class_name Molly
extends Ability

static var MOLLY_RADIUS = 4
static var MOLLY_TURN_DURATION = 2

var hl_tiles = []
var molly_sprites_on_map = []

class InGameMolly:
	var sprite: Sprite2D
	var center_position: Vector2
	var circle_tiles := []
	var turns_to_live = Molly.MOLLY_TURN_DURATION

	func _init(_sprite, _center_position, _circle_tiles) -> void:
		sprite = _sprite
		center_position = _center_position
		circle_tiles = _circle_tiles

	func dissipate():
		var tween = sprite.create_tween()
		tween.tween_property(sprite, "modulate:a", 0, 0.5)
		var on_finished = func _finished():
			sprite.queue_free()
		tween.finished.connect(on_finished)				

func handle_hover(x_pos: int, y_pos: int):
	var circle_tiles = get_circle_tiles(Vector2(x_pos, y_pos), MOLLY_RADIUS)
	var map = game_round.map
	for tile in hl_tiles:
		tile.queue_free()
	hl_tiles = []
	for tile in circle_tiles:
		var color_rect = ColorRect.new()
		color_rect.custom_minimum_size.x = map.ground_layer.tile_set.tile_size.x
		color_rect.custom_minimum_size.y = map.ground_layer.tile_set.tile_size.y
		color_rect.color = Color.ORANGE
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

func _process(_delta: float) -> void:
	game_round.map.queue_redraw()

func deselect():
	for tile in hl_tiles:
		tile.queue_free()
	hl_tiles = []

func handle_click(x_pos: int, y_pos: int):
	var molly_texture = load("res://assets/abilities/in-game/molly.png") as Texture
	var molly_sprite = Sprite2D.new()
	molly_sprite.texture = molly_texture
	game_round.add_util_below_player(molly_sprite)
	var world_pos = game_round.map.get_world_pos_from_tile_pos(Vector2(x_pos, y_pos))
	molly_sprite.global_position = Vector2(world_pos.x + 8, world_pos.y)
	molly_sprite.modulate.a = 0.75
	molly_sprites_on_map.append(molly_sprite)
	var circle_tiles = get_circle_tiles(Vector2i(x_pos, y_pos), MOLLY_RADIUS)
	var in_game_molly = InGameMolly.new(molly_sprite, molly_sprite.global_position, circle_tiles)
	game_round.molly_on_field.append(in_game_molly)
