class_name Retake
extends TeamStrategy

var has_assigned_positions := false
var stacked_site = null

func get_suitability(state: WorldState) -> float:
	var game_round = state.game_round
	if game_round.bomb.curr_bomb_state == Bomb.BombState.PLANTED:
		stacked_site = get_bomb_plant_site(state)
	else:
		# If enemy agents are all stacked towards one site, this strategy becomes more suitable
		var enemy_to_site_map = {
			TeamStrategy.Site.A: 0,
			TeamStrategy.Site.B: 0,
			TeamStrategy.Site.C: 0
		}
		var last_known_enemy_positions = state.last_known_enemy_pos_map
		for pos in last_known_enemy_positions.values():
			var nearest_waypoint = state.get_nearest_waypoint(pos, 10) as TileMapWaypoint
			if nearest_waypoint != null:
				var wp_name = nearest_waypoint.waypoint_name
				if wp_name.begins_with("A_"):
					enemy_to_site_map[TeamStrategy.Site.A] += 1
				elif wp_name.begins_with("B_"):
					enemy_to_site_map[TeamStrategy.Site.B] += 1
				elif wp_name.begins_with("C_"):
					enemy_to_site_map[TeamStrategy.Site.C] += 1
		# If there are 3 or more enemies in the proximity of a given site, we should go towards that site
		var max_enemy_at_site = 3
		for site in enemy_to_site_map.keys():
			if enemy_to_site_map[site] >= max_enemy_at_site:
				stacked_site = site
				max_enemy_at_site = enemy_to_site_map[site]
	if stacked_site != null:
		return 1.0
	return 0.0

func get_bomb_plant_site(state: WorldState):
	var game_round = state.game_round as GameRound
	var bomb_tile_pos = game_round.map.get_tile_pos_from_world_pos(game_round.bomb.global_position)
	var nearest_waypoint = state.get_nearest_waypoint(bomb_tile_pos, 10000)
	if nearest_waypoint.waypoint_name.begins_with("A_"):
		return TeamStrategy.Site.A
	elif nearest_waypoint.waypoint_name.begins_with("B_"):
		return TeamStrategy.Site.B
	elif nearest_waypoint.waypoint_name.begins_with("C_"):
		return TeamStrategy.Site.C

func assign_roles(agents: Array, state: WorldState) -> void:
	var site_waypoints = state.get_site_waypoints(stacked_site)
	site_waypoints.shuffle()
	for i in range(0, agents.size()):
		var agent = agents[i] as Agent
		var waypoint = site_waypoints[i] as TileMapWaypoint
		state.agent_assignments[agent.agent_name] = waypoint.waypoint_tile_pos

func get_strategy_name():
	return "Retake"