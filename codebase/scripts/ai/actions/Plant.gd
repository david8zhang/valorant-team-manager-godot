class_name Plant
extends SingleAgentAction

func get_utility(agent: Agent, state: WorldState) -> float:
	var game_round = state.game_round as GameRound
	var pos = game_round.map.get_tile_pos_from_world_pos(agent.global_position)
	
	# Return 0.0 if the action is impossible (invalid state)
	if !game_round.can_plant_bomb(agent) or \
		 game_round.bomb.curr_bomb_state != Bomb.BombState.CARRIED or \
		 agent.rem_action_points < GameRound.PLANT_COST:
		return 0.0
		
	# High base score: Planting is a high-value action
	var score = 0.5
	
	# Dynamic Penalty: If we are being watched, we are in danger.
	# This lowers the score, potentially allowing the AI to switch to 'Attack' to defend itself.
	var enemies = game_round.get_agents_in_vicinity(pos, GameRound.Side.PLAYER, 15)
	for a in enemies:
		if a.has_vision_of_agent(agent):
			score -= 0.3
		
	return clamp(score, 0.0, 1.0)

func execute(_agent: Agent, _world_state: WorldState, _on_complete: Callable) -> void:
	pass