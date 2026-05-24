class_name AssignPlanter
extends TeamStrategy

var planter: Agent = null

func get_suitability(state: WorldState):
	var bomb = state.game_round.bomb as Bomb
	return 1.0 if bomb.curr_bomb_state == Bomb.BombState.DROPPED else 0.0

func assign_roles(agents: Array, state: WorldState):
	if planter == null or planter.is_dead():
		var bomb = state.game_round.bomb as Bomb
		var map = state.game_round.map as Map
		var living_agents = agents.filter(func (agent: Agent): return !agent.is_dead())
		planter = living_agents.pick_random() as Agent
		state.agent_assignments[planter.agent_name] = map.get_tile_pos_from_world_pos(bomb.global_position)

func get_strategy_name():
	return "Assign Planter"