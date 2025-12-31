class_name Map
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
@onready var ground_layer := $GroundLayer as TileMapLayer
@onready var site_layer := $SiteLayer as TileMapLayer
@onready var walls_layer := $WallsLayer as TileMapLayer
@onready var vision_layer := $VisionLayer as TileMapLayer

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

func show_player_team_visible_tiles():
	var all_visible_tiles = game_round.player_team.get_all_visible_tiles()
	vision_layer.clear()
	show_specific_visible_tiles(all_visible_tiles)

func show_specific_visible_tiles(visible_tiles):
	for t in visible_tiles:
		var g_source_id = ground_layer.get_cell_source_id(t)
		var g_atlas_coords = ground_layer.get_cell_atlas_coords(t)
		var s_source_id = site_layer.get_cell_source_id(t)
		var s_atlas_coords = site_layer.get_cell_atlas_coords(t)
		if g_source_id != -1:
			vision_layer.set_cell(t, g_source_id, g_atlas_coords)
		elif s_source_id != -1:
			vision_layer.set_cell(t, s_source_id, s_atlas_coords)

func is_at_bomb_site(tile_pos: Vector2):
	return site_layer.get_cell_source_id(tile_pos) != -1