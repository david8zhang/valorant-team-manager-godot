class_name Pathfinding
extends Node

@onready var game = get_node("/root/GameRound") as GameRound
@export var map: Map

var astar_grid: AStarGrid2D

func _ready() -> void:
	var ground_layer = map.ground_layer as TileMapLayer
	var used_rect = ground_layer.get_used_rect()
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region = used_rect
	astar_grid.cell_size = ground_layer.tile_set.tile_size
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar_grid.update()
	setup_solid_tiles()

func setup_solid_tiles():
	var used_rect = map.ground_layer.get_used_rect()
	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var cell = Vector2(x, y)
			if is_blocked(cell):
				astar_grid.set_point_solid(cell, true)

func is_blocked(cell: Vector2) -> bool:
	return map.walls_layer.get_cell_source_id(cell) != -1

func get_shortest_path(start_tile: Vector2, end_tile: Vector2) -> Array[Vector2i]:
	return astar_grid.get_id_path(start_tile, end_tile)
