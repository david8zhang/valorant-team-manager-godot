class_name Retake
extends TeamStrategy

var has_assigned_positions := false
var prev_stacked_site = null
var stacked_site = null

func get_suitability(state: WorldState) -> float:
	stacked_site = get_stacked_site(state)
	if stacked_site != null:
		return 1.0
	return 0.0

func get_stacked_site(state: WorldState):
	var game_round = state.game_round
	var curr_stacked_site
	if game_round.bomb.curr_bomb_state == Bomb.BombState.PLANTED:
		curr_stacked_site = get_bomb_plant_site(state)
		print("Bomb plant site: " + str(curr_stacked_site))
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
				curr_stacked_site = site
				max_enemy_at_site = enemy_to_site_map[site]
	return curr_stacked_site

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
	if stacked_site != prev_stacked_site and stacked_site != null:
		prev_stacked_site = stacked_site
		var target_positions = state.get_site_waypoints(stacked_site).map(func (wp: TileMapWaypoint): return wp.waypoint_tile_pos)
		for i in range(0, agents.size()):
			var agent = agents[i] as Agent
			if state.bomb_defuser != null and state.bomb_defuser.agent_name != agent.agent_name:
				var target_tile_pos = target_positions[i % target_positions.size()]
				state.set_agent_assignment(agent.agent_name, target_tile_pos)
		print("Assigning roles for retake: " + str(state.agent_assignments))

func get_strategy_name():
	return "Retake"
