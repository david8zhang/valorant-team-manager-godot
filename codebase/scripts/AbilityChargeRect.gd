class_name AbilityChargeRect
extends ColorRect

var rect_width := 0
var rect_height := 0

func _ready() -> void:
	custom_minimum_size.x = rect_width
	custom_minimum_size.y = rect_height
