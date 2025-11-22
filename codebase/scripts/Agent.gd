class_name Agent
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
@export var vision_distance := 50
@export var vision_angle_degrees := 60

var map: Map
var vision_direction: Vector2 = Vector2.UP
var visible_tiles := []
var is_showing_visible_tiles := false

func move_to_position(new_pos: Vector2, callback: Callable):
	var tween = create_tween()
	tween.tween_property(self, "global_position", new_pos, 0.5)
	var on_complete = func _on_complete():
		update_and_show_visible_tiles()
		callback.call()
	tween.finished.connect(on_complete)

func update_and_show_visible_tiles():
	visible_tiles = get_visible_tiles()
	show_visible_tiles(visible_tiles)

func get_visible_tiles() -> Array:
	var px = map.ground_layer.local_to_map(global_position)
	var forward: Vector2 = vision_direction.rotated(rotation).normalized()

	var half_angle_rad = deg_to_rad(vision_angle_degrees / 2.0)
	var tile_size: Vector2 = map.ground_layer.tile_set.tile_size
	var max_dist_world = vision_distance * tile_size.x

	var res := []
	for dx in range(-vision_distance, vision_distance + 1):
		for dy in range(-vision_distance, vision_distance + 1):
			var tile = px + Vector2i(dx, dy)

			# --- Tile center in WORLD coordinates ---
			var top_left_local = map.ground_layer.map_to_local(tile)
			var top_left_world = map.ground_layer.to_global(top_left_local)
			var tile_center_world = top_left_world + tile_size * 0.5

			# --- Distance check ---
			if global_position.distance_to(tile_center_world) > max_dist_world:
				continue

			# --- Angle check ---
			var to_tile = (tile_center_world - global_position).normalized()
			var dot = forward.dot(to_tile)

			if dot < cos(half_angle_rad):    # avoids slow acos()
				continue

			# --- Line of Sight ---
			if not is_tile_blocked(px, tile):
				res.append(tile)
	return res


func is_tile_blocked(start: Vector2i, target: Vector2i) -> bool:
	var points := bresenham_line(start.x, start.y, target.x, target.y)
	for p in points:
		if p == start:
			continue
		if map.walls_layer.get_cell_source_id(p) != -1:
			return true
	return false


func bresenham_line(x0, y0, x1, y1) -> Array[Vector2i]:
	var line: Array[Vector2i] = []
	var dx = abs(x1 - x0)
	var dy = -abs(y1 - y0)
	var sx = 1 if x0 < x1 else -1
	var sy = 1 if y0 < y1 else -1
	var err = dx + dy

	var x = x0
	var y = y0

	while true:
		line.append(Vector2i(x, y))
		if x == x1 and y == y1:
			break
		var e2 = 2 * err
		if e2 >= dy:
			err += dy
			x += sx
		if e2 <= dx:
			err += dx
			y += sy
	return line


# -----------------------------------------------------------
# DEBUG: highlight tiles (optional)
# -----------------------------------------------------------
func show_visible_tiles(tiles: Array) -> void:
	map.vision_layer.clear()
	for t in tiles:
		var source_id = map.ground_layer.get_cell_source_id(t)
		var atlas_coords = map.ground_layer.get_cell_atlas_coords(t)
		map.vision_layer.set_cell(t, source_id, atlas_coords)
