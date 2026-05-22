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
		var cost = agent.game_round.get_ap_cost_for_movement_tiles(agent_tile_pos, best_tile)
		print("[" + agent.agent_name + "]" + " Cost to move: " + str(cost))
		print("[" + agent.agent_name + "]" + " Rem AP:" + str(agent.rem_action_points))
		if cost > agent.rem_action_points:
			return -1.0
		move_target = best_tile
		return highest_tile_score
	else:
		return -1.0

func score_tile(agent: Agent, tile: Vector2, world_state: WorldState) -> float:
	var map = agent.game_round.map as Map
	var agent_tile_pos = map.get_tile_pos_from_world_pos(agent.global_position)
	
	# Start with a fixed, positive baseline score
	var score: float = 0.5
	
	# --- 1. STRATEGIC CONTEXT (BOMB CHECK) ---
	var bomb_priority_multiplier: float = 1.0
	var is_defuse_objective: bool = false
	
	if world_state.agent_assignments.has(agent.agent_name):
		var assigned_pos = world_state.agent_assignments[agent.agent_name] as Vector2
		var bomb = agent.game_round.bomb
		
		# Check if the bomb exists and is planted
		if bomb != null and bomb.curr_bomb_state == Bomb.BombState.PLANTED:
			var bomb_tile_pos = map.get_tile_pos_from_world_pos(bomb.global_position)
			
			# If our assignment is exactly the bomb tile, spike the priority
			if assigned_pos == Vector2(bomb_tile_pos):
				is_defuse_objective = true
				bomb_priority_multiplier = 2.5 # Dramatically amplify progress reward
	
	# --- 2. WAYPOINT & SAFETY EVALUATION ---
	var nearest_waypoint = world_state.get_nearest_waypoint(tile, 10)
	# If it's a critical bomb defuse, we suppress "low health fear" slightly so they don't desert the objective
	var health_threshold = 0.1 if is_defuse_objective else 0.2
	var is_low_health = agent.get_curr_health() <= Agent.MAX_HEALTH * health_threshold
	
	if nearest_waypoint != null:
		var dist_to_nearest_wp = nearest_waypoint.waypoint_tile_pos.distance_to(tile) + 0.1
		var proximity_weight = 1.0 / dist_to_nearest_wp
		
		if world_state.is_waypoint_dangerous(nearest_waypoint):
			# If defusing the bomb, reduce the fear of dangerous areas to allow for clutch plays
			var danger_modifier = 0.15 if is_defuse_objective else 0.4
			score -= proximity_weight * danger_modifier
			
		if is_low_health and world_state.is_waypoint_safe(nearest_waypoint):
			score += proximity_weight * 0.5
			
	# --- 3. COMBAT & AGGRESSION EVALUATION ---
	# If we are strictly focusing on a planted bomb, we tone down hunting behaviors 
	# to keep the AI focused on the objective rather than getting distracted by exit frags
	if not is_low_health and not is_defuse_objective:
		var closest_enemy = world_state.get_closest_known_enemy(tile) as Agent
		if closest_enemy != null:
			var closest_enemy_pos = map.get_tile_pos_from_world_pos(closest_enemy.global_position)
			var distance_to_enemy = closest_enemy_pos.distance_to(tile)
			
			if distance_to_enemy <= DANGER_DIST_THRESHOLD:
				var team_strategy = world_state.get_team_strategy()
				var enemy_proximity = 1.0 / (distance_to_enemy + 0.1)
				score += enemy_proximity * team_strategy.aggression_multiplier * 0.3

	# --- 4. OBJECTIVE PROGRESS EVALUATION ---
	if world_state.agent_assignments.has(agent.agent_name):
		var assigned_pos = world_state.agent_assignments[agent.agent_name] as Vector2
		var curr_distance = agent_tile_pos.distance_to(assigned_pos)
		var new_distance = tile.distance_to(assigned_pos)
		
		var progress_bonus = (curr_distance - new_distance) / 75.0
		
		# Apply the bomb multiplier here to weight progress towards a planted bomb immensely higher
		score += progress_bonus * 0.4 * bomb_priority_multiplier
		
		# If the tile literally gets us closer to the planted bomb, give it an explicit baseline boost
		if is_defuse_objective and new_distance < curr_distance:
			score += 0.25

	# --- 5. SANITY CHECK ---
	return clamp(score, 0.0, 1.0)

func execute(agent: Agent, _world_state: WorldState, on_complete: Callable) -> void:
	print("[" + agent.agent_name + "]" + " Moving to " + str(move_target))
	var game_round = agent.game_round as GameRound
	agent.move_to_position(game_round.map.get_world_pos_from_tile_pos(move_target), on_complete)

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
