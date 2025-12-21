class_name Agent
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
@onready var sprite = $AnimatedSprite2D as AnimatedSprite2D
@onready var button = $Button as Button
@onready var health_bar = $HealthBar as ProgressBar
@onready var shield_bar = $ShieldBar as ProgressBar
@onready var weapon = $Weapon as Sprite2D

@export var projectile_scene: PackedScene
@export var vision_distance := 25
@export var vision_angle_degrees := 60

static var DEFAULT_SCALE = 1.5
static var TOTAL_ACTION_POINTS = 5

var agent_name := ""
var map: Map
var vision_direction: Vector2 = Vector2.UP
var visible_tiles := []
var is_showing_visible_tiles := false
var rem_action_points = TOTAL_ACTION_POINTS
var has_completed_turn := false

signal on_agent_click(agent)
signal on_update_action_menu()
signal on_take_damage()

func _ready() -> void:
	sprite.scale = Vector2(DEFAULT_SCALE, DEFAULT_SCALE)
	button.pressed.connect(agent_click)

func agent_click():
	on_agent_click.emit(self)

func move_to_position(new_pos: Vector2, callback: Callable):
	var prev_pos = Vector2(global_position.x, global_position.y)
	var tween = create_tween()
	tween.tween_property(self, "global_position", new_pos, 0.5)
	var on_complete = func _on_complete():
		update_visible_tiles()
		callback.call()
	tween.finished.connect(on_complete)
	var ap_cost = game_round.get_ap_cost_for_movement(prev_pos, new_pos)
	rem_action_points -= ap_cost

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
	weapon.show()
	weapon.rotation_degrees = angle
	weapon.flip_v = weapon.rotation_degrees <= -90 and weapon.rotation_degrees >= -270 or \
									weapon.rotation_degrees >= 90 and weapon.rotation_degrees <= 270

	# Add a 1-second delay
	var t = wait_delay(0.5)
	await t.timeout

	# Shoot bullet from gun
	var projectile = projectile_scene.instantiate() as Node2D
	weapon.add_child(projectile)
	projectile.position = Vector2(weapon.position.x + 20, weapon.position.y + 5)
	projectile.reparent(game_round)
	projectile.show()
	var tween = create_tween()
	tween.tween_property(projectile, "global_position", enemy_to_attack_pos, 0.5)
	tween.finished.connect(func (): on_attack_finished(projectile, enemy_to_attack, should_retaliate, on_complete))

func on_attack_finished(projectile: Node2D, enemy_to_attack: Agent, should_retaliate: bool, on_complete: Callable):
	var rand_damage = randi_range(50, 75)
	enemy_to_attack.take_damage(rand_damage)
	projectile.queue_free()
	if should_retaliate and !enemy_to_attack.is_dead() and enemy_to_attack.has_vision_of_agent(self):
		enemy_to_attack.attack_enemy_agent(self, false, on_complete)
	else:
		var t = wait_delay(0.5)
		await t.timeout
		enemy_to_attack.weapon.hide()
		weapon.hide()
		game_round.game_camera.target_zoom = Vector2.ONE
		on_complete.call()

func take_damage(damage):
	var dmg_to_hp = damage - shield_bar.value
	shield_bar.value -= damage
	health_bar.value -= dmg_to_hp
	on_update_action_menu.emit()
	on_take_damage.emit()

	# Handle agent death
	if health_bar.value == 0:
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
