class_name WatchAngle
extends SingleAgentAction

var angle_to_watch: Vector2 = Vector2.ZERO

func get_utility(agent: Agent, _world_state: WorldState) -> float:
	var angles = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2(1, 1).normalized(), # South east
		Vector2(-1, 1).normalized(), # South west
		Vector2(1, -1).normalized(), # North east
		Vector2(-1, -1).normalized(), # North west
	]
	var max_angle_score = score_angle_direction(agent, agent.vision_direction)
	var best_angle := Vector2.ZERO
	for angle in angles:
		if angle == agent.vision_direction:
			continue
		var angle_score = score_angle_direction(agent, angle)
		if angle_score > max_angle_score:
			best_angle = angle
			max_angle_score = angle_score
	if best_angle == Vector2.ZERO:
		return -1.0
	angle_to_watch = best_angle
	return max_angle_score

func score_angle_direction(agent: Agent, direction: Vector2) -> float:
	var base_score = 0.1
	var tiles = agent.get_tiles_in_view_for_direction(direction)
	var enemy_agent_position_map = agent.game_round.get_agent_positions_map(GameRound.Side.PLAYER)
	for tile in tiles:
		var serialized_tile_key = GameRound.serialize_tile_pos_key(tile)
		# If this angle detects enemies, it's a good angle to look towards
		if serialized_tile_key in enemy_agent_position_map:
			base_score += 0.25
	# Angles that reveal more area also are better
	base_score += tiles.size() * 0.001
	return base_score

func execute(agent: Agent, _world_state: WorldState, on_complete: Callable) -> void:
	if angle_to_watch != Vector2.ZERO:
		print("[" + agent.agent_name + "]" + " watching " + str(angle_to_watch))
		agent.set_vision_direction(angle_to_watch)
		on_complete.call()
