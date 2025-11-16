class_name Map
extends Node2D

@onready var ground_layer = $GroundLayer as TileMapLayer

func _ready() -> void:
	is_tile_pos_in_bounds(Vector2(-1, -1))

func move_node_to_pos(node: Node2D, x: int, y: int):
	var world_pos = ground_layer.map_to_local(Vector2(x, y))
	node.global_position = world_pos

func get_tile_pos_from_world_pos(world_pos: Vector2):
	return ground_layer.local_to_map(world_pos)

func get_world_pos_from_tile_pos(tile_pos: Vector2):
	return ground_layer.map_to_local(tile_pos)

func is_tile_pos_in_bounds(tile_pos: Vector2):
	var map := ground_layer.get_used_rect()
	return tile_pos.x >= 0 and tile_pos.x < map.size.x and tile_pos.y >= 0 and tile_pos.y < map.size.y