class_name SplitSiteHold
extends TeamStrategy

var has_assigned_positions := false

func get_suitability(state: WorldState) -> float:
	var game_round = state.game_round as GameRound
	return 0.25 if game_round.get_current_phase() == Scoreboard.Phase.SETUP else 0.0

func assign_roles(agents: Array, state: WorldState) -> void:
	if !has_assigned_positions:
		has_assigned_positions = true
		var a_site_locations = state.get_site_waypoints(TeamStrategy.Site.A)
		var b_site_locations = state.get_site_waypoints(TeamStrategy.Site.B)
		a_site_locations.shuffle()
		b_site_locations.shuffle()
		print("Assigning roles!")
		for i in range(0, agents.size()):
			var agent = agents[i] as Agent
			if i % 2 == 0:
				var rand_a_site_pos = a_site_locations.pop_front() as TileMapWaypoint
				assert(rand_a_site_pos != null, "No A site positions to assign!")
				state.agent_assignments[agent.agent_name] = rand_a_site_pos.waypoint_tile_pos
			else:
				var rand_b_site_pos = b_site_locations.pop_front() as TileMapWaypoint
				assert(rand_b_site_pos != null, "No B site positions to assign!")
				state.agent_assignments[agent.agent_name] = rand_b_site_pos.waypoint_tile_pos

func get_strategy_name():
	return "Split Site Hold"
