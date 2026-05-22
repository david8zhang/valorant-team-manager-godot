class_name AssignDefuser
extends TeamStrategy

var defuser: Agent = null

func get_suitability(state: WorldState) -> float:
	var game_round = state.game_round
	if game_round.bomb.curr_bomb_state == Bomb.BombState.PLANTED and (defuser == null or defuser.is_dead()):
		return 2.0
	return 0.0
	
func assign_roles(agents: Array, state: WorldState) -> void:
	if defuser == null or defuser.is_dead():
		var game_round = state.game_round
		var rand_agent = agents.filter(func(a: Agent): return !a.is_dead()).pick_random()
		defuser = rand_agent
		var bomb_tile_pos = game_round.map.get_tile_pos_from_world_pos(game_round.bomb.global_position)
		print("Assigning defuser: " + defuser.agent_name + " to move to " + str(bomb_tile_pos))
		state.agent_assignments[defuser.agent_name] = bomb_tile_pos
		state.bomb_defuser = defuser

func get_strategy_name():
	return "AssignDefuser"