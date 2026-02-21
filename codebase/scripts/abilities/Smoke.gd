class_name Smoke
extends Ability

static var SMOKE_RADIUS = 4

var hl_tiles = []

func handle_hover(x_pos: int, y_pos: int):
	var circle_tiles = get_circle_tiles(Vector2(x_pos, y_pos), SMOKE_RADIUS)
	var map = game_round.map
	for tile in hl_tiles:
		tile.queue_free()
	hl_tiles = []
	for tile in circle_tiles:
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size.x = map.ground_layer.tile_set.tile_size.x
		color_rect.custom_minimum_size.y = map.ground_layer.tile_set.tile_size.y
		color_rect.color = Color("#555555")
		color_rect.color.a = 0.5
		game_round.add_child(color_rect)
		color_rect.global_position = map.get_world_pos_from_tile_pos(tile)
		hl_tiles.append(color_rect)
		
func get_circle_tiles(center: Vector2i, radius: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = []
	var r_squared = (radius + 0.3) * (radius + 0.3)
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			var tile = Vector2(x + 0.5, y + 0.5)
			var center_f = Vector2(center) + Vector2(0.5, 0.5)
			if tile.distance_squared_to(center_f) <= r_squared:
				tiles.append(Vector2i(x, y))
	return tiles

func deselect():
	for tile in hl_tiles:
		tile.queue_free()
	hl_tiles = []
