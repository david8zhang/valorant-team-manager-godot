@tool
extends Node2D

var waypoints: Array[TileMapWaypoint]
@export var base_tileset: TileSet
@export var data_to_load: MultiTileMapData:
	set(val):
		data_to_load = val
		if Engine.is_editor_hint() and val != null:
			load_into_editor()

func _ready():
	save_all_layers(self, "res://resources/maps/data/TestCombat2.tres")

func save_all_layers(parent_node: Node, file_path: String) -> void:
	waypoints = data_to_load.waypoints
	var multi_data = MultiTileMapData.new()
	for child in parent_node.get_children():
		if child is TileMapLayer:
			var layer_tiles: Array[Dictionary] = []
			var cells = child.get_used_cells()
			for coords in cells:
				layer_tiles.append({
					"coords": coords,
					"source_id": child.get_cell_source_id(coords),
					"atlas_coords": child.get_cell_atlas_coords(coords),
					"alternative_tile": child.get_cell_alternative_tile(coords)
				})
			multi_data.layers_content[child.name] = layer_tiles
	multi_data.waypoints = waypoints
	var result = ResourceSaver.save(multi_data, file_path)
	if result == OK:
		print("All layers saved successfully.")

func load_into_editor() -> void:
	if not data_to_load:
		return
		
	if not base_tileset:
		push_error("Assign a TileSet first!")
		return

	var tree = get_tree()
	if not tree:
		tree = Engine.get_main_loop() as SceneTree
	
	if not tree or not tree.edited_scene_root:
		return

	for layer_name in data_to_load.layers_content.keys():
		# Explicitly convert the key to a NodePath to satisfy the compiler
		var node_path = NodePath(str(layer_name))
		var existing_node = get_node_or_null(node_path)
		
		if existing_node:
			existing_node.free()
		
		var new_layer = TileMapLayer.new()
		new_layer.name = layer_name
		new_layer.tile_set = base_tileset
		
		add_child(new_layer)
		
		# Set owner to the scene root so it stays in the scene file
		new_layer.owner = tree.edited_scene_root
		
		var tile_list = data_to_load.layers_content[layer_name]
		for cell in tile_list:
			new_layer.set_cell(
				cell["coords"],
				cell["source_id"],
				cell["atlas_coords"],
				cell["alternative_tile"]
			)
	print("Layers loaded successfully. You may need to click them to refresh the viewport.")