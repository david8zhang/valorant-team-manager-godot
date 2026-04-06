@tool
extends Node

## Drag and drop your .res or .tres file here in the Inspector
@export var data_to_load: MultiTileMapData:
	set(val):
		data_to_load = val
		if Engine.is_editor_hint() and val != null:
			load_into_editor()

## This function reconstructs the layers as actual editor nodes
func load_into_editor() -> void:
	if not data_to_load:
		return
		
	# Clear existing children to avoid duplicates
	for child in get_children():
		child.free()
		
	for layer_name in data_to_load.layers_content.keys():
		var new_layer = TileMapLayer.new()
		new_layer.name = layer_name
		add_child(new_layer)
		
		# CRITICAL: Setting owner allows the node to be seen and saved in the Scene Dock
		new_layer.owner = get_tree().edited_scene_root
		
		var tile_list = data_to_load.layers_content[layer_name]
		for cell in tile_list:
			new_layer.set_cell(
				cell["coords"],
				cell["source_id"],
				cell["atlas_coords"],
				cell["alternative_tile"]
			)
			
	print("Successfully loaded ", data_to_load.layers_content.size(), " layers into editor.")