class_name Defuse
extends SingleAgentAction

func get_utility(agent: Agent, _world_state: WorldState) -> float:
	var game_round = agent.game_round as GameRound
	var agent_tile_pos = game_round.map.get_tile_pos_from_world_pos(agent.global_position)
	# Defusal is invalid if we're not in range or the bomb isn't planted
	if !game_round.is_within_bomb_defusal_range(agent_tile_pos) or !game_round.bomb.curr_bomb_state != Bomb.BombState.PLANTED:
		return -1.0
	# Defuse the bomb if:
	# 1. it's safe to do so (add bonus if true):
  #		- ally is watching the bomb
	#   - # allies in vicinity > # enemies
	# 2. add bonus to continue defusing bomb if nearing completion
	var base_score = 0.0
	return base_score

func execute(_agent: Agent, _world_state: WorldState, _on_complete: Callable) -> void:
	pass
