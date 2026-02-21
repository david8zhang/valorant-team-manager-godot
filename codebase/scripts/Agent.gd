class_name Agent
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
@onready var sprite = $AnimatedSprite2D as AnimatedSprite2D
@onready var button = $Button as Button
@onready var health_bar = $HealthBar as ProgressBar
@onready var shield_bar = $ShieldBar as ProgressBar
@onready var weapon_sprite = $Weapon as Sprite2D

@export var projectile_scene: PackedScene
@export var vision_distance := 25
@export var vision_angle_degrees := 60

static var DEFAULT_SCALE = 1.5
static var TOTAL_ACTION_POINTS = 5
static var MAX_HEALTH = 100
static var MAX_SHIELDS = 50

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

signal on_agent_click(agent)
signal on_update_action_menu()
signal on_take_damage()
signal on_death()
signal on_kill()

func _ready() -> void:
	sprite.scale = Vector2(DEFAULT_SCALE, DEFAULT_SCALE)
	button.pressed.connect(agent_click)
	confidence_level = randi_range(1, 10)
	ability_1 = AbilityCreator.create_ability(agent_stats.ability_1)
	ability_2 = AbilityCreator.create_ability(agent_stats.ability_2)

func init_from_game_stats(agent_game_stats: GameRoundVariables.AgentGameStats):
	primary_weapon = GameRoundVariables.load_weapon_from_name(agent_game_stats.primary_weapon_name)
	sidearm_weapon = GameRoundVariables.load_weapon_from_name(agent_game_stats.sidearm_weapon_name)
	# TBD - make this based on buy menu option
	ability_1_charges = agent_stats.ability_1.total_charges
	ability_2_charges = agent_stats.ability_2.total_charges

func agent_click():
	on_agent_click.emit(self)

func move_to_position(new_pos: Vector2, callback: Callable):
	var prev_pos = Vector2(global_position.x, global_position.y)
	var tween = create_tween()
	tween.tween_property(self, "global_position", new_pos, 0.5)
	var on_complete = func _on_complete():
		if game_round.attack_side == curr_side:
			acquire_bomb_if_possible(new_pos)
		update_visible_tiles()
		callback.call()
	tween.finished.connect(on_complete)
	var ap_cost = game_round.get_ap_cost_for_movement(prev_pos, new_pos)
	rem_action_points -= ap_cost

func acquire_bomb_if_possible(new_pos: Vector2):
	if new_pos == game_round.bomb.global_position && game_round.bomb.curr_bomb_state == Bomb.BombState.DROPPED:
		game_round.bomb.set_bomb_state(Bomb.BombState.CARRIED)
		has_bomb = true

func drop_bomb():
	game_round.bomb.global_position = Vector2(global_position.x, global_position.y)
	game_round.bomb.set_bomb_state(Bomb.BombState.DROPPED)

func update_visible_tiles():
	visible_tiles = get_visible_tiles()

func get_visible_tiles() -> Array:
	var px = map.ground_layer.local_to_map(global_position)
	var forward: Vector2 = vision_direction.rotated(rotation).normalized()

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

func is_tile_blocked(start: Vector2i, target: Vector2i) -> bool:
	var points := bresenham_line(start.x, start.y, target.x, target.y)
	for p in points:
		if p == start:
			continue
		if map.walls_layer.get_cell_source_id(p) != -1:
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
	var ap_cost = game_round.get_ap_cost_for_primary_attack()
	rem_action_points -= ap_cost

	var game_camera = game_round.game_camera
	game_camera.target_zoom = Vector2(1.5, 1.5)
	var enemy_to_attack_pos = enemy_to_attack.global_position
	var selected_agent_pos = self.global_position
	var angle = rad_to_deg((enemy_to_attack_pos - selected_agent_pos).angle())

	assert(weapon_to_attack_with != null, "Weapon to attack with is null!")
	weapon_sprite.texture = weapon_to_attack_with.weapon_stats.texture
	weapon_sprite.show()
	weapon_sprite.rotation_degrees = angle
	weapon_sprite.flip_v = weapon_sprite.rotation_degrees <= -90 and weapon_sprite.rotation_degrees >= -270 or \
									weapon_sprite.rotation_degrees >= 90 and weapon_sprite.rotation_degrees <= 270

	# Add a 1-second delay
	var t = wait_delay(0.5)
	await t.timeout

	# Shoot bullet from gun
	var projectile = projectile_scene.instantiate() as Node2D
	weapon_sprite.add_child(projectile)
	projectile.position = Vector2(weapon_sprite.position.x + 20, weapon_sprite.position.y + 5)
	projectile.reparent(game_round)
	projectile.show()
	var tween = create_tween()
	tween.tween_property(projectile, "global_position", enemy_to_attack_pos, 0.5)
	tween.finished.connect(func (): on_attack_finished(projectile, enemy_to_attack, should_retaliate, on_complete))

func on_attack_finished(projectile: Node2D, enemy_to_attack: Agent, should_retaliate: bool, on_complete: Callable):
	var damage = calculate_damage_to_deal()
	enemy_to_attack.take_damage(damage)

	# Log damage from this agent to enemy in order to calculate assists
	if !enemy_to_attack.damage_source_mapping.has(agent_name):
		enemy_to_attack.damage_source_mapping[agent_name] = 0
	enemy_to_attack.damage_source_mapping[agent_name] += damage

	# If kill is scored, emit a kill or assit signal
	if enemy_to_attack.get_curr_health() == 0:
		GameRoundVariables.update_kill_count_for_agent(agent_name)
		GameRoundVariables.update_assist_counts(enemy_to_attack, agent_name)
		kills_this_round += 1
		on_kill.emit()

	projectile.queue_free()
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

func calculate_damage_to_deal():
	assert(weapon_to_attack_with != null, "Weapon to attack with is null when calculating damage!")
	var hit_roll = randi_range(0, 100)
	
	# replace this with actual accuracy stat
	if hit_roll < 40:
		print("Missed!")
		return 0
	else:
		var headshot_roll = randi_range(0, 100)
		if headshot_roll >= 80:
			return weapon_to_attack_with.weapon_stats.headshot_damage
		else:
			return weapon_to_attack_with.weapon_stats.body_damage

func take_damage(damage):
	var dmg_to_hp = damage - shield_bar.value
	shield_bar.value -= damage
	health_bar.value -= dmg_to_hp
	on_update_action_menu.emit()
	on_take_damage.emit()

	# Handle agent death
	if health_bar.value == 0:
		if has_bomb:
			has_bomb = false
			drop_bomb()
		GameRoundVariables.update_death_count_for_agent(agent_name)
		on_death.emit()
		hide()

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
	update_visible_tiles()
	var other_agent_tile_pos = game_round.map.get_tile_pos_from_world_pos(other_agent.global_position)
	for t in visible_tiles:
		if t.x == other_agent_tile_pos.x and t.y == other_agent_tile_pos.y:
			return true
	return false

func hide_in_fog_of_war():
	var shader = sprite.material as ShaderMaterial
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
