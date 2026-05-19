class_name Defuse
extends SingleAgentAction

func get_utility(agent: Agent, _world_state: WorldState) -> float:
	var game_round = agent.game_round as GameRound
	var agent_tile_pos = game_round.map.get_tile_pos_from_world_pos(agent.global_position)
	var has_req_ap = agent.rem_action_points == GameRound.DEFUSE_COST
	# Defusal is invalid if we're not in range or the bomb isn't planted
	if !game_round.is_within_bomb_defusal_range(agent_tile_pos) or !game_round.bomb.curr_bomb_state != Bomb.BombState.PLANTED or !has_req_ap:
		return -1.0
	# Baseline is to keep defusing the bomb whenever possible. Subtract penalties based on danger level
	var base_score = 2.0
	# If the enemy has vision, prefer not to defuse
	var enemy_agents = game_round.player_team.get_all_living_agents()
	for a in enemy_agents:
		var player_agent = a as Agent
		if player_agent.has_vision_of_agent(agent):
			base_score -= 0.1
	# Add bonus or penalty depending on if allies outnumber enemies or vice versa
	var num_allies = game_round.get_agents_in_vicinity(agent_tile_pos, GameRound.Side.CPU, 15).size()
	var num_enemies = game_round.get_agents_in_vicinity(agent_tile_pos, GameRound.Side.PLAYER, 15).size()
	base_score -= (num_enemies - num_allies) * 0.15
	print("Base score for defuse: " + str(base_score))
	return base_score

func execute(agent: Agent, world_state: WorldState, on_complete: Callable) -> void:
	var game_round = world_state.game_round as GameRound
	game_round.start_defuse_bomb(agent)
	on_complete.call()
