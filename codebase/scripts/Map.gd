class_name Map
extends Node2D

@onready var ground_layer = $GroundLayer as TileMapLayer

func move_node_to_pos(node: Node2D, x: int, y: int):
	var world_pos = ground_layer.map_to_local(Vector2(x, y))
	node.global_position = world_pos
