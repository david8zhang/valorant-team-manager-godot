class_name RushSite
extends TeamStrategy

var site_to_rush = null

func get_suitability(state: WorldState):
	var game_round = state.game_round
	var score = 0.0
	if game_round.get_current_phase() == Scoreboard.Phase.SETUP:
		score += 0.125
	if state.cpu_agent_controller.team_strategy == null:
		score += 0.125
	# If a given site is fairly weak
	var weakest_site = identify_weak_site(state)
	if weakest_site != null:
		score += 0.5
	return score

func identify_weak_site(state: WorldState):
	var enemy_agents = state.game_round.player_team.agents
	var last_known_enemy_pos_map = state.last_known_enemy_pos_map
	var site_to_enemy_num: Dictionary[TeamStrategy.Site, int] = {}
	var seen_agents := 0
	for a in enemy_agents:
		var enemy_agent = a as Agent
		if last_known_enemy_pos_map.has(enemy_agent.agent_name):
			seen_agents += 1
			var last_known_pos = last_known_enemy_pos_map[enemy_agent.agent_name]
			var nearest_waypoint = state.get_nearest_waypoint(last_known_pos, 15)
			var site_for_wp = state.get_nearest_site_to_waypoint(nearest_waypoint)
			if !site_to_enemy_num.has(site_for_wp):
				site_to_enemy_num[site_for_wp] = 0
			site_to_enemy_num[site_for_wp] += 1
	# If we've seen a majority of agents, figure out which site is weak based on their last known position
	if seen_agents >= 3:
		var weakest_site = null
		var weakest_site_num_enemies := INF
		for site in site_to_enemy_num.keys():
			if site_to_enemy_num[site] < weakest_site_num_enemies:
				weakest_site = site
				weakest_site_num_enemies = site_to_enemy_num[site]
		return weakest_site
	return null

func assign_roles(agents: Array, state: WorldState):
	if site_to_rush == null:
		site_to_rush = state.get_all_sites().pick_random()
		# TODO: Need to ensure that each site has >= 5 waypoints, otherwise agents will overlap
		var waypoints_for_site = state.get_site_waypoints(site_to_rush)
		for i in range(0, agents.size()):
			var waypoint = waypoints_for_site[i] as TileMapWaypoint
			var agent = agents[i] as Agent
			state.agent_assignments[agent.agent_name] = waypoint.waypoint_tile_pos

func get_strategy_name():
	return "Rush Site"
