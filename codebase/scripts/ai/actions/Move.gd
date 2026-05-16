class_name Move
extends SingleAgentAction

# Static distance to enemy threshold to be considered "dangerous"
static var DANGER_DIST_THRESHOLD = 10

var move_target: Vector2 = Vector2.ZERO

func get_utility(agent: Agent, world_state: WorldState) -> float:
	# 1. Fetch all tiles in the moveable range (max 3AP cost)
	# 2. Calculate score of tile based on
	#   - If it's in a dangerous area
	#   - If we're low health and it's in a safe area
	# 	- Proximity to enemy agents last known positions
	#   - Proximity to assigned objective
	var map = agent.game_round.map as Map
	var agent_tile_pos = map.get_tile_pos_from_world_pos(agent.global_position)
	var walk_range = min(15, agent.rem_action_points / GameRound.AP_COST_MOVE_PER_SQUARE)
	var tiles_to_consider = get_tiles_within_radius(agent_tile_pos, walk_range, agent.game_round)
	var highest_tile_score = score_tile(agent, agent_tile_pos, world_state)
	var best_tile: Vector2 = Vector2.ZERO
	for tile in tiles_to_consider:
		# Only consider tiles to move towards and not the current tile
		if tile == agent_tile_pos:
			continue
		var score = score_tile(agent, tile, world_state)
		if score >= highest_tile_score:
			highest_tile_score = score
			best_tile = tile
	if best_tile != Vector2.ZERO:
		move_target = best_tile
		return highest_tile_score
	else:
		return -1.0

func score_tile(agent: Agent, tile: Vector2, world_state: WorldState):
	var map = agent.game_round.map as Map
	var agent_tile_pos = map.get_tile_pos_from_world_pos(agent.global_position)
	var score = 0.2
	var nearest_waypoint = world_state.get_nearest_waypoint(tile, 10)
	var dist_to_nearest_wp = 0 if nearest_waypoint == null else nearest_waypoint.waypoint_tile_pos.distance_to(tile)
	var is_low_health = agent.get_curr_health() <= Agent.MAX_HEALTH * 0.2
	# Check if tile is in dangerous area
	if nearest_waypoint != null and world_state.is_waypoint_dangerous(nearest_waypoint):
		score -= (1 / dist_to_nearest_wp)
	# If is low health, look for safe tile to retreat to
	if is_low_health:
		if nearest_waypoint != null and world_state.is_waypoint_safe(nearest_waypoint):
			score += (1 / dist_to_nearest_wp)
	else:
		# If not low health, make aggressive plays depending on aggression multiplier
		var closest_enemy = world_state.get_closest_known_enemy(tile) as Agent
		if closest_enemy != null:
			var closest_enemy_pos = map.get_tile_pos_from_world_pos(closest_enemy.global_position)
			var distance_to_enemy = closest_enemy_pos.distance_to(tile)
			if distance_to_enemy <= DANGER_DIST_THRESHOLD:
				var team_strategy = world_state.get_team_strategy()
				score *= team_strategy.aggression_multiplier
	# Check distance to assigned objective
	if world_state.agent_assignments.has(agent.agent_name):
		var assigned_pos = world_state.agent_assignments[agent.agent_name] as Vector2
		var curr_distance = agent_tile_pos.distance_to(assigned_pos)
		var new_distance = tile.distance_to(assigned_pos)
		var progress_bonus = (curr_distance - new_distance) / 75.0
		score += progress_bonus
	return score

func execute(agent: Agent, _world_state: WorldState, on_complete: Callable) -> void:
	print(agent.agent_name + " moving to " + str(move_target))
	var game_round = agent.game_round as GameRound
	var agent_tile_pos = game_round.map.get_tile_pos_from_world_pos(agent.global_position)
	var shortest_path = game_round.pathfinding.get_shortest_path(agent_tile_pos, move_target)
	ap_cost = round(shortest_path.size() * GameRound.AP_COST_MOVE_PER_SQUARE)	
	agent.move_to_position(game_round.map.get_world_pos_from_tile_pos(move_target), on_complete)
	agent.rem_action_points -= ap_cost

func get_tiles_within_radius(center_pos: Vector2, radius: int, game_round: GameRound) -> Array[Vector2i]:
	var map = game_round.map as Map
	var tiles_to_consider: Array[Vector2i] = []
	var min_x = center_pos.x - radius
	var max_x = center_pos.x + radius
	var min_y = center_pos.y - radius
	var max_y = center_pos.y + radius
	for x in range(min_x, max_x + 1):
		for y in range(min_y, max_y + 1):
			var tile_pos = Vector2i(x, y)
			if !map.is_tile_pos_in_bounds(tile_pos):
				continue
			if map.is_tile_pos_obstructed(tile_pos):
				continue
			if !game_round.pathfinding.can_find_path(center_pos, tile_pos):
				continue
			var dist_squared = (tile_pos - Vector2i(center_pos)).length_squared()
			if dist_squared <= radius * radius:
				tiles_to_consider.append(tile_pos)
	return tiles_to_consider
