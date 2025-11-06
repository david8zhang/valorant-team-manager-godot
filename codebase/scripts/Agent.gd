class_name Agent
extends Node2D

func move_to_position(new_pos: Vector2):
	var tween = create_tween()
	tween.tween_property(self, "global_position", new_pos, 0.5)