class_name MapDebugScene
extends Node2D

@onready var map = $Map as Map

func _ready() -> void:
	for p in map.map_data.waypoints:
		var waypoint = p as TileMapWaypoint
		var label = Label.new()
		label.global_position = map.get_world_pos_from_tile_pos(waypoint.waypoint_tile_pos)
		label.text = waypoint.waypoint_name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		add_child(label)
		label.global_position = label.global_position - (label.size / 2)		
