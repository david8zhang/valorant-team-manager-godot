class_name ShakeComponent
extends Node2D

@export var decay_speed := 8.0

var shake_strength := 0.0
var shake_time := 0.0

var target: Node2D

# This is the base position we offset from each frame
var base_position := Vector2.ZERO

func _ready():
	target = get_parent() as Node2D
	base_position = target.position

func shake(strength: float = 6.0, duration: float = 0.25):
	shake_strength = strength
	shake_time = duration

func _process(delta):
	if not target:
		return

	# update base position so shake offsets current parent position
	base_position = target.position if shake_time <= 0 else base_position

	if shake_time > 0:
		shake_time -= delta
		var offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		target.position = base_position + offset
		shake_strength = lerpf(shake_strength, 0.0, decay_speed * delta)
	else:
		# restore base position exactly when shake ends
		target.position = base_position