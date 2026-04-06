class_name Map
extends Node2D

## You MUST drag your .tres TileSet resource here for tiles to appear
@export var base_tileset: TileSet

@onready var game_round = get_node("/root/GameRound") as GameRound
@onready var ground_layer := $GroundLayer as TileMapLayer
@onready var spawn_layer := $SpawnLayer as TileMapLayer
@onready var site_layer := $SiteLayer as TileMapLayer
@onready var walls_layer := $WallsLayer as TileMapLayer
@onready var temp_barrier_layer := $TempBarrierLayer as TileMapLayer
@onready var vision_layer := $VisionLayer as TileMapLayer

var last_visible_tiles = {}

func _ready() -> void:
	spawn_layer.hide()
	load_all_layers(self, "res://resources/maps/Ascent.tres")

func move_node_to_pos(node: Node2D, tile_x: int, tile_y: int):
	var world_pos = ground_layer.map_to_local(Vector2(tile_x, tile_y))
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
	show_specific_visible_tiles(all_visible_tiles)

func show_specific_visible_tiles(visible_tiles_array):
	var current_visible_tiles = {}
	for t in visible_tiles_array:
		current_visible_tiles[t] = true
	for t in last_visible_tiles:
		if not current_visible_tiles.has(t):
			vision_layer.set_cell(t, -1)
	for t in current_visible_tiles:
		if last_visible_tiles.has(t): 
			continue
		var source_id = ground_layer.get_cell_source_id(t)
		var atlas = ground_layer.get_cell_atlas_coords(t)
		if source_id == -1:
			source_id = site_layer.get_cell_source_id(t)
			atlas = site_layer.get_cell_atlas_coords(t)
		if source_id != -1:
			vision_layer.set_cell(t, source_id, atlas)
	last_visible_tiles = current_visible_tiles

func is_at_bomb_site(tile_pos: Vector2):
	return site_layer.get_cell_source_id(tile_pos) != -1

func highlight_tile_at_tile_pos(x_pos, y_pos, color):
	var cell_size = ground_layer.tile_set.tile_size
	var cell_size_vec2 = Vector2(cell_size.x, cell_size.y)
	var tile_pos_to_hl = Vector2(x_pos, y_pos)
	var tile_pos = ground_layer.map_to_local(tile_pos_to_hl) as Vector2
	var rect = Rect2(tile_pos - cell_size_vec2 / 2, cell_size)
	draw_rect(rect, color, true)

func is_tile_pos_obstructed(tile_pos):
	return walls_layer.get_cell_source_id(tile_pos) != -1

func load_all_layers(parent_node: Node, file_path: String) -> void:
	if not FileAccess.file_exists(file_path):
		return
	var multi_data = load(file_path) as MultiTileMapData
	if not multi_data:
		return

	for layer_name in multi_data.layers_content.keys():
		var layer = parent_node.get_node_or_null(NodePath(layer_name)) as TileMapLayer
		# If the layer exists in the scene, reconstruct it
		if layer:
			layer.clear()
			var tile_list = multi_data.layers_content[layer_name]

			for cell in tile_list:
				layer.set_cell(
					cell["coords"],
					cell["source_id"],
					cell["atlas_coords"],
					cell["alternative_tile"]
				)

	print("All layers loaded successfully.")