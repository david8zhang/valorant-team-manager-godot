class_name Agent
extends Node2D

@export var vision_distance := 50
@export var vision_angle_degrees := 60
var walls_tilemap: TileMapLayer
var ground_tilemap: TileMapLayer
var vision_tilemap: TileMapLayer

func move_to_position(new_pos: Vector2, callback: Callable):
	var tween = create_tween()
	tween.tween_property(self, "global_position", new_pos, 0.5)
	var on_complete = func _on_complete():
		print("Went here!")
		var visible_tiles = get_visible_tiles()
		highlight_visible_tiles(visible_tiles)  # optional, for debugging
		callback.call()
	tween.finished.connect(on_complete)


func get_visible_tiles() -> Array:
		var px = ground_tilemap.local_to_map(global_position)
		var forward: Vector2 = Vector2.UP.rotated(rotation).normalized()

		var half_angle_rad = deg_to_rad(vision_angle_degrees / 2.0)
		var tile_size: Vector2 = ground_tilemap.tile_set.tile_size
		var max_dist_world = vision_distance * tile_size.x

		var visible_tiles := []

		for dx in range(-vision_distance, vision_distance + 1):
				for dy in range(-vision_distance, vision_distance + 1):

						var tile = px + Vector2i(dx, dy)

						# --- Tile center in WORLD coordinates ---
						var top_left_local = ground_tilemap.map_to_local(tile)
						var top_left_world = ground_tilemap.to_global(top_left_local)
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
								visible_tiles.append(tile)

		return visible_tiles


func is_tile_blocked(start: Vector2i, target: Vector2i) -> bool:
		var points := bresenham_line(start.x, start.y, target.x, target.y)

		for p in points:
				if p == start:
						continue

				if walls_tilemap.get_cell_source_id(p) != -1:
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
func highlight_visible_tiles(tiles: Array) -> void:
	vision_tilemap.clear()
	# Example: print tiles or draw debug overlay
	# Replace with your own debug visuals
	for t in tiles:
		# For example, tint them, place markers, etc.
		vision_tilemap.set_cell(t, 0, Vector2i(0, 0))
