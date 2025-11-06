class_name HighlightOverlay
extends Node2D

@export var map: Map
@onready var game_round = get_node("/root/GameRound") as GameRound
var hovered_tile_pos: Vector2

func _process(_delta: float) -> void:
	if map != null and game_round != null:
		var mouse_world_pos = get_global_mouse_position()
		hovered_tile_pos = map.ground_layer.local_to_map(game_round.to_local(mouse_world_pos))
		queue_redraw()

func _draw() -> void:
	if hovered_tile_pos != null:
		var cell_size = map.ground_layer.tile_set.tile_size
		var cell_size_vec2 = Vector2(cell_size.x, cell_size.y)
		var tile_pos = map.ground_layer.map_to_local(hovered_tile_pos) as Vector2
		var rect = Rect2(tile_pos - cell_size_vec2 / 2, cell_size)
		draw_rect(rect, Color(0, 1, 0, 0.4), true)
