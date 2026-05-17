class_name Retake
extends TeamStrategy

func get_suitability(state: WorldState) -> float:
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
	var stacked_site = null
	var max_enemy_at_site = 3
	for site in enemy_to_site_map.keys():
		if enemy_to_site_map[site] >= max_enemy_at_site:
			stacked_site = site
			max_enemy_at_site = enemy_to_site_map[site]
	if stacked_site != null:
		return 1.0
	return 0.0

func assign_roles(agents: Array, state: WorldState) -> void:
	# Assign an agent to each enemy in a round-robin fashion
	var last_known_enemy_positions = state.last_known_enemy_pos_map
	var i = 0
	for pos in last_known_enemy_positions.values():
		var agent = agents[i] as Agent
		state.agent_assignments[agent.agent_name] = pos
		i = (i + 1) % agents.size()

func get_strategy_name():
	return "Retake"