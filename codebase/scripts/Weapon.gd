class_name Weapon
extends Node

var game_round: GameRound
var weapon_stats: WeaponStats
var curr_ammo := 0
var max_ammo := 0

static var NUM_SHOTS_HFR = 5
static var NUM_SHOTS_MFR = 3
static var NUM_SHOTS_LFR = 1

var shots_rem := 0

func _init(_weapon_stats: WeaponStats, _game_round) -> void:
		weapon_stats = _weapon_stats
		max_ammo = _weapon_stats.max_ammo
		game_round = _game_round

func fire_at_enemy(weapon_sprite: AnimatedSprite2D, selected_agent: Agent, enemy_to_attack: Agent, callback: Callable):
	var enemy_to_attack_pos = enemy_to_attack.global_position
	var selected_agent_pos = selected_agent.global_position
	var angle = rad_to_deg((enemy_to_attack_pos - selected_agent_pos).angle())
	weapon_sprite.sprite_frames = weapon_stats.animations
	weapon_sprite.show()
	weapon_sprite.scale = Vector2(weapon_stats.scale, weapon_stats.scale)
	weapon_sprite.rotation_degrees = angle
	weapon_sprite.flip_v = weapon_sprite.rotation_degrees <= -90 and weapon_sprite.rotation_degrees >= -270 or \
									weapon_sprite.rotation_degrees >= 90 and weapon_sprite.rotation_degrees <= 270
	shots_rem = get_num_shots_for_fire_rate(weapon_stats.weapon_fire_rate)
	fire_shots(weapon_sprite, selected_agent, enemy_to_attack, callback)

func get_num_shots_for_fire_rate(fire_rate: WeaponStats.WeaponFireRate):
	match fire_rate:
		WeaponStats.WeaponFireRate.HIGH:
			return NUM_SHOTS_HFR
		WeaponStats.WeaponFireRate.MED:
			return NUM_SHOTS_MFR
		WeaponStats.WeaponFireRate.LOW:
			return NUM_SHOTS_LFR

func fire_shots(weapon_sprite: AnimatedSprite2D, selected_agent: Agent, enemy_to_attack: Agent, cb: Callable):
	if shots_rem == 0:
		cb.call()
		return
	shots_rem -= 1
	weapon_sprite.play("firing")
	handle_enemy_damage(weapon_sprite, selected_agent, enemy_to_attack)
	if !enemy_to_attack.is_dead():
		weapon_sprite.animation_finished.connect(fire_shots.bind(weapon_sprite, selected_agent, enemy_to_attack, cb), CONNECT_ONE_SHOT)
	else:
		cb.call()
		return

func handle_enemy_damage(weapon_sprite, selected_agent: Agent, enemy_to_attack: Agent):
	var agent_name = selected_agent.agent_name
	var damage = calculate_damage_to_deal()
	enemy_to_attack.take_damage(damage)

	# Show bullet tracers
	show_bullet_tracer(weapon_sprite, enemy_to_attack, damage)

	# Log damage from this agent to enemy in order to calculate assists
	if !enemy_to_attack.damage_source_mapping.has(agent_name):
		enemy_to_attack.damage_source_mapping[agent_name] = 0
	enemy_to_attack.damage_source_mapping[agent_name] += damage

	# handle if enemy is killed
	if enemy_to_attack.get_curr_health() == 0:
		GameRoundVariables.update_kill_count_for_agent(agent_name)
		GameRoundVariables.update_assist_counts(enemy_to_attack, agent_name)
		selected_agent.kills_this_round += 1
		selected_agent.on_kill.emit()

func show_bullet_tracer(weapon_sprite: AnimatedSprite2D, enemy_to_attack: Agent, damage):
	var tracer_line = Line2D.new()
	var barrel_x_pos = weapon_stats.barrel_x_pos
	var barrel_y_pos = weapon_stats.barrel_y_pos
	var tracer_start_pos = Vector2(weapon_sprite.position.x + barrel_x_pos, weapon_sprite.position.y + barrel_y_pos)
	var tracer_end_point = enemy_to_attack.global_position

	# Make the tracer line off if it's a missed shot
	if damage == 0:
		var too_far_right = randi_range(0, 1) == 0
		var offset_x = randi_range(15, 20) if too_far_right else randi_range(-20, -15)
		tracer_end_point.x += offset_x

	tracer_line.points = [weapon_sprite.to_global(tracer_start_pos), tracer_end_point]
	tracer_line.default_color = Color("#fbf236")
	tracer_line.width = 3
	game_round.add_child(tracer_line)
	var timer = Timer.new()
	timer.wait_time = 0.03
	timer.one_shot = true
	timer.autostart = true
	var tracer_dissolve = func _tracer_dissolve():
		show_enemy_damage(enemy_to_attack, damage)
		var three_q_point = (tracer_line.points[0] + tracer_end_point * 3) / 4
		tracer_line.points = [three_q_point, tracer_end_point]
		var timer2 = Timer.new()
		timer2.wait_time = 0.03
		timer2.one_shot = true
		timer2.autostart = true
		var remove_tracer = func _remove_tracer():
			tracer_line.queue_free()
		timer2.timeout.connect(remove_tracer)
		game_round.add_child(timer2)
	timer.timeout.connect(tracer_dissolve)
	game_round.add_child(timer)


func show_enemy_damage(enemy_to_attack: Agent, damage: int):
	var shader = enemy_to_attack.sprite.material as ShaderMaterial
	var prev_solid_color = shader.get_shader_parameter("solid_color")
	if damage > 0:
		enemy_to_attack.shake_component.shake(3.0, 0.1)
		shader.set_shader_parameter("solid_color", Color.RED)
		shader.set_shader_parameter("enabled", true)
	var timer = Timer.new()
	timer.wait_time = 0.1
	timer.autostart = true
	timer.one_shot = true
	var on_complete = func _on_complete():
		shader.set_shader_parameter("solid_color", prev_solid_color)
		shader.set_shader_parameter("enabled", false)
	timer.timeout.connect(on_complete)
	game_round.add_child(timer)


func calculate_damage_to_deal():
	var hit_roll = randi_range(0, 100)	
	# replace this with actual accuracy stat
	if hit_roll < 35:
		print("Missed!")
		return 0
	else:
		var headshot_roll = randi_range(0, 100)
		if headshot_roll >= 80:
			return weapon_stats.headshot_damage
		else:
			return weapon_stats.body_damage
