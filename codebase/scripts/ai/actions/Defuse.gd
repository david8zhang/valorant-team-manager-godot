class_name Defuse
extends SingleAgentAction

func get_utility(agent: Agent, _world_state: WorldState) -> float:
	var game_round = agent.game_round as GameRound
	var pos = game_round.map.get_tile_pos_from_world_pos(agent.global_position)
	
	# Return 0.0 if the action is impossible (invalid state)
	if !game_round.is_within_bomb_defusal_range(pos) or \
		 game_round.bomb.curr_bomb_state != Bomb.BombState.PLANTED or \
		 agent.rem_action_points < GameRound.DEFUSE_COST:
		return 0.0
		
	# High base score: Defusing is the win condition
	var score = 0.9 
	
	# Dynamic Penalty: If we are being watched, we are in danger.
	# This lowers the score, potentially allowing the AI to switch to 'Attack' to defend itself.
	var enemies = game_round.get_agents_in_vicinity(pos, GameRound.Side.PLAYER, 15)
	for a in enemies:
		if a.has_vision_of_agent(agent):
			score -= 0.3
		
	return clamp(score, 0.0, 1.0)

func execute(agent: Agent, world_state: WorldState, on_complete: Callable) -> void:
	var game_round = world_state.game_round as GameRound
	game_round.start_defuse_bomb(agent)
	on_complete.call()
