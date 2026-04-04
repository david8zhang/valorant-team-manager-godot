class_name Smoke
extends Ability

static var SMOKE_RADIUS = 4
static var SMOKE_TURN_DURATION = 2

var hl_tiles = []
var smoke_sprites_on_map = []

class InGameSmoke:
	var sprite: Sprite2D
	var center_position: Vector2
	var circle_tiles := []
	var turns_to_live = Smoke.SMOKE_TURN_DURATION

	func _init(_sprite, _center_position, _circle_tiles) -> void:
		sprite = _sprite
		center_position = _center_position
		circle_tiles = _circle_tiles.map(func (tile): return str(tile.x) + "," + str(tile.y))

	func is_position_smoked(pos: Vector2i):
		var pos_key = str(pos.x) + "," + str(pos.y)
		return circle_tiles.has(pos_key)

	func dissipate():
		var tween = sprite.create_tween()
		tween.tween_property(sprite, "modulate:a", 0, 0.5)
		var on_finished = func _finished():
			sprite.queue_free()
		tween.finished.connect(on_finished)
	

func handle_hover(x_pos: int, y_pos: int):
	var circle_tiles = get_circle_tiles(Vector2(x_pos, y_pos), SMOKE_RADIUS)
	var map = game_round.map
	for tile in hl_tiles:
		tile.queue_free()
	hl_tiles = []
	for tile in circle_tiles:
		var color_rect = ColorRect.new()
		var tile_size = map.ground_layer.tile_set.tile_size
		color_rect.custom_minimum_size.x = tile_size.x
		color_rect.custom_minimum_size.y = tile_size.y
		color_rect.color = Color("#555555")
		color_rect.mouse_filter = Control.MOUSE_FILTER_PASS
		color_rect.color.a = 0.5
		game_round.add_child(color_rect)
		color_rect.global_position = map.get_world_pos_from_tile_pos(tile)
		hl_tiles.append(color_rect)
		
static func get_circle_tiles(center: Vector2i, radius: int) -> Array[Vector2i]:
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

func handle_click(x_pos: int, y_pos: int):
	var smoke_texture = load("res://assets/abilities/in-game/smoke.png") as Texture
	var smoke_sprite = Sprite2D.new()
	smoke_sprite.texture = smoke_texture
	game_round.add_util_above_player(smoke_sprite)
	var world_pos = game_round.map.get_world_pos_from_tile_pos(Vector2(x_pos, y_pos))
	smoke_sprite.global_position = Vector2(world_pos.x + 8, world_pos.y)
	smoke_sprite.modulate.a = 0.75
	smoke_sprites_on_map.append(smoke_sprite)
	var circle_tiles = get_circle_tiles(Vector2i(x_pos, y_pos), SMOKE_RADIUS)
	var in_game_smoke = InGameSmoke.new(smoke_sprite, smoke_sprite.global_position, circle_tiles)
	game_round.smokes_on_field.append(in_game_smoke)
