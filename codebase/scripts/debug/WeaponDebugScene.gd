extends Node2D

@onready var weapon = $Weapon as AnimatedSprite2D
@export var weapon_stats: WeaponStats

func _ready() -> void:
	weapon.sprite_frames = weapon_stats.animations

func _input(event):
		if event is InputEventMouseButton:
				if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
						var mouse_world_pos = get_viewport().get_camera_2d().get_global_mouse_position()
						fire_weapon_at_position(mouse_world_pos)


func get_tracer_start_pos() -> Vector2:
		var barrel_local = Vector2(weapon_stats.barrel_x_pos, weapon_stats.barrel_y_pos) + Vector2(0, -8)  # adjust for sprite origin/offset
		if weapon.flip_v:
				barrel_local.y += weapon_stats.barrel_y_pos_flip
		var rotated_barrel = barrel_local.rotated(weapon.rotation)
		return weapon.global_position + rotated_barrel

func fire_weapon_at_position(pos: Vector2) -> void:
		weapon.rotation = (pos - weapon.global_position).angle()
		weapon.flip_v = weapon.rotation_degrees <= -90 and weapon.rotation_degrees >= -270 or \
										weapon.rotation_degrees >= 90 and weapon.rotation_degrees <= 270
		weapon.play("firing")
		var tracer_start = get_tracer_start_pos()
		var tracer_end = pos

		var tracer_line = Line2D.new()
		tracer_line.points = [tracer_start, tracer_end]
		tracer_line.width = 3
		tracer_line.default_color = Color("#fbf236")
		add_child(tracer_line)

		var timer = Timer.new()
		timer.wait_time = 0.03
		timer.one_shot = true
		timer.autostart = true
		timer.timeout.connect(func():
				var three_q_point = (tracer_line.points[0] + tracer_end * 3) / 4
				tracer_line.points = [three_q_point, tracer_end]
				var timer2 = Timer.new()
				timer2.wait_time = 0.03
				timer2.one_shot = true
				timer2.autostart = true
				timer2.timeout.connect(func(): tracer_line.queue_free())
				add_child(timer2)
		)
		add_child(timer)
