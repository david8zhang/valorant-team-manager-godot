class_name DefaultAttack
extends TeamStrategy

var has_assigned_positions := false

func get_suitability(state: WorldState):
	var game_round = state.game_round
	var is_setup_phase = game_round.get_current_phase() == Scoreboard.Phase.SETUP
	# TODO: Might be good to specifically designate strategies as "early round", "mid round", and "late round"
	var has_not_chosen_team_strat = state.cpu_agent_controller.team_strategy == null
	return 0.25 if is_setup_phase and has_not_chosen_team_strat else 0.0

func assign_roles(agents: Array, state: WorldState):
	# Basically the equivalent of a Split Site Hold on defense - gather intel and eventually pivot to a rush site strategy
	var positions_by_site = get_positions_by_site(state)
	for i in range(0, agents.size()):
		var agent = agents[i] as Agent
		var site_bucket_index = i % positions_by_site.keys().size()
		var site_to_assign_to = positions_by_site.keys()[site_bucket_index]
		var shuffled_positions = positions_by_site[site_to_assign_to] as Array
		var pos_to_assign = shuffled_positions.pop_front()
		assert(pos_to_assign != null, "No site position to assign for default attack!")
		state.agent_assignments[agent.agent_name] = pos_to_assign

func get_positions_by_site(state: WorldState):
	var positions_by_site: Dictionary[TeamStrategy.Site, Array] = {}
	var all_sites = state.get_all_sites()
	for site in all_sites:
		var site_positions = state.get_site_waypoints(site).map(func(s: TileMapWaypoint): return s.waypoint_tile_pos)
		site_positions.shuffle()
		positions_by_site[site] = site_positions
	return positions_by_site

func get_strategy_name():
	return "Default Attack"