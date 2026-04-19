class_name TileMapWaypoint
extends Resource

enum MapSide {
	ATTACKER,
	DEFENDER
}

@export var waypoint_name: String
@export var waypoint_tile_pos: Vector2
@export var map_side: MapSide
