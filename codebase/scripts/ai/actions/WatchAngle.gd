class_name WatchAngle
extends SingleAgentAction

var angle_to_watch: Vector2 = Vector2.ZERO

func get_utility(agent: Agent, _world_state: WorldState) -> float:
	var angles = [
		Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT,
		Vector2(1, 1).normalized(), Vector2(-1, 1).normalized(),
		Vector2(1, -1).normalized(), Vector2(-1, -1).normalized()
	]
	
	var max_angle_score = -1.0
	var best_angle := Vector2.ZERO
	
	for angle in angles:
		var angle_score = score_angle_direction(agent, angle)
		if angle_score > max_angle_score:
			max_angle_score = angle_score
			best_angle = angle
	
	# --- STATE CHANGE FIX ---
	# If we are already looking at the best possible angle, this action 
	# provides 0 utility. This forces the AI to consider other actions (like 
	# moving or attacking) or end its turn.
	if best_angle == agent.vision_direction:
		return 0.0
	
	# Only assign the target if the score is actually worth the effort
	if max_angle_score > 0.0:
		angle_to_watch = best_angle
		return clamp(max_angle_score, 0.0, 0.5)
		
	return 0.0

func score_angle_direction(agent: Agent, direction: Vector2) -> float:
	var base_score = 0.1
	var tiles = agent.get_tiles_in_view_for_direction(direction)
	var enemy_agent_position_map = agent.game_round.get_agent_positions_map(GameRound.Side.PLAYER)
	
	for tile in tiles:
		var serialized_tile_key = GameRound.serialize_tile_pos_key(tile)
		# If this angle detects enemies, it's a good angle to look towards
		if serialized_tile_key in enemy_agent_position_map:
			base_score += 0.3
			
	# Angles that reveal more area are slightly better (tie-breaker)
	base_score += tiles.size() * 0.001
	return base_score

func execute(agent: Agent, _world_state: WorldState, on_complete: Callable) -> void:
	if angle_to_watch != Vector2.ZERO:
		print("[%s] watching %s" % [agent.agent_name, str(angle_to_watch)])
		agent.set_vision_direction(angle_to_watch)
		# Give the vision system a tiny moment to update if needed before finishing
		on_complete.call()
