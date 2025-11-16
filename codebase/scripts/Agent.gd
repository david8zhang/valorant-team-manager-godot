class_name Agent
extends Node2D

func move_to_position(new_pos: Vector2, callback: Callable):
	var tween = create_tween()
	tween.tween_property(self, "global_position", new_pos, 0.5)
	var on_complete = func _on_complete():
		callback.call()
	tween.finished.connect(on_complete)