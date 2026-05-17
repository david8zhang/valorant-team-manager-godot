class_name Agent
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
@onready var sprite = $AnimatedSprite2D as AnimatedSprite2D
@onready var button = $Button as Button
@onready var health_bar = $HealthBar as ProgressBar
@onready var shield_bar = $ShieldBar as ProgressBar
@onready var weapon_sprite = $Weapon as AnimatedSprite2D
@onready var shake_component = $ShakeComponent as ShakeComponent

@export var projectile_scene: PackedScene
@export var vision_distance := 25
@export var vision_angle_degrees := 60

static var DEFAULT_SCALE = 1.5
static var TOTAL_ACTION_POINTS = 5
static var MAX_HEALTH = 100
static var MAX_SHIELDS = 50
static var WALK_SPEED_PER_TILE = 5

var agent_stats: AgentStats
var ability_1_charges := 0
var ability_2_charges := 0
var agent_name := ""
var map: Map
var vision_direction: Vector2 = Vector2.UP
var visible_tiles := []
var is_showing_visible_tiles := false
var rem_action_points = TOTAL_ACTION_POINTS
var has_completed_turn := false
var curr_side: GameRound.Side
var damage_source_mapping = {}
var kills_this_round := 0
var did_plant_this_round := false
var did_defuse_this_round := false

var primary_weapon: Weapon = null
var sidearm_weapon: Weapon = null
var weapon_to_attack_with: Weapon = null
var has_bomb := false
var ability_1: Ability
var ability_2: Ability

var confidence_level # Dictates turn queue ordering (higher is better)
var is_defusing := false
var is_planting := false
var holding_tiles := []
var pos_to_watch := Vector2.ZERO

# For CPU-controlled individual agent AI
var single_agent_controller

signal on_agent_click(agent)
signal on_update_action_menu()
signal on_take_damage()
signal on_death()
signal on_kill()

func _ready() -> void:
	reload_shader()
	sprite.scale = Vector2(DEFAULT_SCALE, DEFAULT_SCALE)
	sprite.sprite_frames = agent_stats.animations
	sprite.play("idle")
	button.pressed.connect(agent_click)
	confidence_level = randi_range(1, 10)
	ability_1 = AbilityCreator.create_ability(agent_stats.ability_1)
	ability_2 = AbilityCreator.create_ability(agent_stats.ability_2)

func init_from_game_stats(agent_game_stats: GameRoundVariables.AgentGameStats):
	primary_weapon = GameRoundVariables.load_weapon_from_name(agent_game_stats.primary_weapon_name, game_round)
	sidearm_weapon = GameRoundVariables.load_weapon_from_name(agent_game_stats.sidearm_weapon_name, game_round)
	# TBD - make this based on buy menu option
	ability_1_charges = agent_stats.ability_1.total_charges
	ability_2_charges = agent_stats.ability_2.total_charges

func agent_click():
	on_agent_click.emit(self)

func move_to_position(new_world_pos: Vector2, callback: Callable):
	# Stop holding the angle when in movement
	var prev_world_pos = Vector2(global_position.x, global_position.y)
	var curr_tile_pos = map.get_tile_pos_from_world_pos(prev_world_pos)
	var new_tile_pos = map.get_tile_pos_from_world_pos(new_world_pos)
	var path = game_round.pathfinding.get_shortest_path(curr_tile_pos, new_tile_pos)
	sprite.play("walk")
	var on_path_walk_complete = func _on_path_walk_complete():
		sprite.play("idle")
		callback.call()
	_move_to_next_node_in_path(1, path, on_path_walk_complete)
	var ap_cost = game_round.get_ap_cost_for_movement(prev_world_pos, new_world_pos)
	rem_action_points -= ap_cost

func _move_to_next_node_in_path(curr_node_idx, path, on_finished_cb):
	if curr_node_idx == path.size() or is_dead():
		on_finished_cb.call()
		return
	var next_node = path[curr_node_idx]
	var next_node_world_pos = map.get_world_pos_from_tile_pos(next_node)
	var tween = create_tween()
	# Only look towards the next position if we're not already holding an angle
	if pos_to_watch == Vector2.ZERO:
		look_at_position(next_node_world_pos)
	tween.tween_property(self, "global_position", next_node_world_pos, 0.05)
	var on_complete = func _on_complete():
		if game_round.attack_side == curr_side:
			acquire_bomb_if_possible(next_node_world_pos)
		update_tiles_in_view()
		# Update visible tiles after each tile movement if this is the player's currently selected agent
		if curr_side == GameRound.Side.PLAYER:
			map.show_specific_visible_tiles(visible_tiles)
			game_round.update_visible_enemies_to_player()
		_move_to_next_node_in_path(curr_node_idx + 1, path, on_finished_cb)
	tween.finished.connect(on_complete)

func acquire_bomb_if_possible(new_pos: Vector2):
	if new_pos == game_round.bomb.global_position && game_round.bomb.curr_bomb_state == Bomb.BombState.DROPPED:
		game_round.bomb.set_bomb_state(Bomb.BombState.CARRIED)
		has_bomb = true

func drop_bomb():
	game_round.bomb.global_position = Vector2(global_position.x, global_position.y)
	game_round.bomb.set_bomb_state(Bomb.BombState.DROPPED)

func update_tiles_in_view():
	visible_tiles = get_tiles_in_view()
	if curr_side == GameRound.Side.CPU:
		GameRoundVariables.cpu_world_state.update_cpu_vision()	

func get_tiles_in_view() -> Array:
	# If we're holding a specific angle, adjust vision direction accordingly
	if pos_to_watch != Vector2.ZERO:
		vision_direction = (pos_to_watch - global_position).normalized()
	return get_tiles_in_view_for_direction(vision_direction)

func get_tiles_in_view_for_direction(direction: Vector2):
	var px = map.ground_layer.local_to_map(global_position)
	var forward: Vector2 = direction.rotated(rotation).normalized()
	var half_angle_rad = deg_to_rad(vision_angle_degrees / 2.0)
	var tile_size: Vector2 = map.ground_layer.tile_set.tile_size
	var max_dist_world = vision_distance * tile_size.x
	var res := []
	for dx in range(-vision_distance, vision_distance + 1):
		for dy in range(-vision_distance, vision_distance + 1):
			var tile = px + Vector2i(dx, dy)
			# --- Tile center in WORLD coordinates ---
			var top_left_local = map.ground_layer.map_to_local(tile)
			var top_left_world = map.ground_layer.to_global(top_left_local)
			var tile_center_world = top_left_world + tile_size * 0.5
			# --- Distance check ---
			if global_position.distance_to(tile_center_world) > max_dist_world:
				continue
			# --- Angle check ---
			var to_tile = (tile_center_world - global_position).normalized()
			var dot = forward.dot(to_tile)
			if dot < cos(half_angle_rad):    # avoids slow acos()
				continue
			# --- Line of Sight ---
			if not is_tile_blocked(px, tile):
				res.append(tile)
	return res

func look_at_position(world_pos_to_look_at: Vector2):
	vision_direction = (world_pos_to_look_at - global_position).normalized()
	update_tiles_in_view()

func set_vision_direction(new_direction: Vector2):
	vision_direction = new_direction
	update_tiles_in_view()

func watch_position(pos: Vector2):
	# Stop holding previous tiles if we were holding before
	pos_to_watch = pos
	look_at_position(pos_to_watch)
	map.show_specific_visible_tiles(visible_tiles)
	game_round.update_visible_enemies_to_player()

func stop_watching_position():
	pos_to_watch = Vector2.ZERO

func is_tile_blocked(start: Vector2i, target: Vector2i) -> bool:
	var points := bresenham_line(start.x, start.y, target.x, target.y)
	for p in points:
		if p == start:
			continue
		if map.walls_layer.get_cell_source_id(p) != -1:
			return true
		if game_round.is_tile_smoked(p):
			return true
	return false

func bresenham_line(x0, y0, x1, y1) -> Array[Vector2i]:
	var line: Array[Vector2i] = []
	var dx = abs(x1 - x0)
	var dy = -abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy
	var x = x0
	var y = y0
	while true:
		line.append(Vector2i(x, y))
		if x == x1 and y == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
	return line

func attack_enemy_agent(enemy_to_attack: Agent, should_retaliate: bool, on_complete: Callable):
	if weapon_to_attack_with == null:
		weapon_to_attack_with = primary_weapon if primary_weapon != null else sidearm_weapon
	var ap_cost = game_round.get_ap_cost_for_primary_attack()
	rem_action_points -= ap_cost
	# Pan and zoom camera to battle
	var game_camera = game_round.game_camera
	var midpoint_pos = Vector2((global_position.x + enemy_to_attack.global_position.x) / 2, (global_position.y + enemy_to_attack.global_position.y) / 2)
	game_round.game_camera.target_position = midpoint_pos	
	game_camera.target_zoom = Vector2(1.5, 1.5)
	# Add a 1-second delay
	var t = wait_delay(0.5)
	await t.timeout
	# Shoot bullet from gun
	weapon_to_attack_with.fire_at_enemy(weapon_sprite, self, enemy_to_attack, func (): on_attack_finished(enemy_to_attack, should_retaliate, on_complete))

func on_attack_finished(enemy_to_attack: Agent, should_retaliate: bool, on_complete: Callable):
	if should_retaliate and !enemy_to_attack.is_dead() and enemy_to_attack.has_vision_of_agent(self):
		# Set defending agent weapon
		enemy_to_attack.weapon_to_attack_with = enemy_to_attack.primary_weapon if enemy_to_attack.primary_weapon != null else enemy_to_attack.sidearm_weapon		
		enemy_to_attack.attack_enemy_agent(self, false, on_complete)
	else:
		var t = wait_delay(0.5)
		await t.timeout
		enemy_to_attack.weapon_sprite.hide()
		weapon_sprite.hide()
		game_round.game_camera.target_zoom = Vector2.ONE
		weapon_to_attack_with = null
		on_complete.call()

func take_damage(damage):
	var dmg_to_hp = damage - shield_bar.value
	shield_bar.value -= damage
	health_bar.value -= dmg_to_hp
	on_update_action_menu.emit()
	on_take_damage.emit()
	# Handle agent death
	if health_bar.value == 0:
		die()

func die():
	var on_death_anim_finished = func _on_death_anim_finished():
		sprite.material = null
		var on_fade = func _on_fade():
			reload_shader()
			sprite.modulate.a = 1
			if has_bomb:
				has_bomb = false
				drop_bomb()
			GameRoundVariables.update_death_count_for_agent(agent_name)
			on_death.emit()
			hide()
			# Clear all animation finished connections (so we don't get duplicate callback invocations)
			for conn in sprite.animation_finished.get_connections():
					sprite.animation_finished.disconnect(conn.callable)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0, 0.5)
		tween.finished.connect(on_fade)
	sprite.animation_finished.connect(on_death_anim_finished)
	sprite.play("death")

func is_dead():
	return health_bar.value == 0

func wait_delay(delay: float):
	var timer = Timer.new()
	timer.autostart = true
	timer.one_shot = true
	timer.wait_time = delay
	add_child(timer)
	return timer

func get_curr_health():
	return health_bar.value

func set_curr_health(amt):
	health_bar.value = amt

func has_vision_of_agent(other_agent: Agent):
	update_tiles_in_view()
	var other_agent_tile_pos = game_round.map.get_tile_pos_from_world_pos(other_agent.global_position)
	for t in visible_tiles:
		if t.x == other_agent_tile_pos.x and t.y == other_agent_tile_pos.y:
			return true
	return false

func get_enemies_in_view():
	update_tiles_in_view()
	var opp_side = GameRound.Side.PLAYER if curr_side == GameRound.Side.CPU else GameRound.Side.CPU
	var enemy_agent_position_map = game_round.get_agent_positions_map(opp_side)
	var tiles_in_view = get_tiles_in_view()
	var agents_in_view := []
	for tile in tiles_in_view:
		var serialized_tile_pos_key = GameRound.serialize_tile_pos_key(tile)
		if serialized_tile_pos_key in enemy_agent_position_map:
			agents_in_view.append(enemy_agent_position_map[serialized_tile_pos_key])
	return agents_in_view

func hide_in_fog_of_war():
	var shader = sprite.material as ShaderMaterial
	shader.set_shader_parameter("solid_color", Color("#555555"))
	shader.set_shader_parameter("enabled", true)
	health_bar.hide()
	shield_bar.hide()

func hide_fully():
	hide()

func show_fully():
	show()
	health_bar.show()
	shield_bar.show()
	var shader = sprite.material as ShaderMaterial
	shader.set_shader_parameter("enabled", false)

func set_outline(outline_color):
	var shader = sprite.material as ShaderMaterial
	shader.set_shader_parameter("outline_enabled", true)
	shader.set_shader_parameter("outline_color", outline_color)

func reload_shader():
	sprite.material = ShaderMaterial.new()
	sprite.material.shader = load("res://shaders/solid_color.gdshader")

func reset():
	set_curr_health(Agent.MAX_HEALTH)
	vision_direction = Vector2.UP
	rem_action_points = Agent.TOTAL_ACTION_POINTS
	has_completed_turn = false
	is_planting = false
	is_defusing = false
	pos_to_watch = Vector2.ZERO
	did_defuse_this_round = false
	did_plant_this_round = false
	kills_this_round = 0
	sprite.play("idle")
	var outline_color = GameRoundVariables.PLAYER_OUTLINE_COLOR if curr_side == GameRound.Side.PLAYER else GameRoundVariables.CPU_OUTLINE_COLOR
	set_outline(outline_color)
	var agent_game_stats = GameRoundVariables.get_or_create_agent_game_stat(agent_name)
	primary_weapon = GameRoundVariables.load_weapon_from_name(agent_game_stats.primary_weapon_name, game_round)
	sidearm_weapon = GameRoundVariables.load_weapon_from_name(agent_game_stats.sidearm_weapon_name, game_round)
