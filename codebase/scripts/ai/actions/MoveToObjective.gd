class_name MoveToObjective
extends SingleAgentAction

static var MOVE_RADIUS_TILES = 10

var tile_to_move_to

func get_utility(agent: Agent, world_state: WorldState) -> float:
	var game_round = world_state.game_round as GameRound
	if world_state.agent_assignments.has(agent.agent_name):
		var objective_tile_pos = world_state.agent_assignments[agent.agent_name]
		var agent_tile_pos = game_round.map.get_tile_pos_from_world_pos(agent.global_position)
		var tiles_within_radius = game_round.get_movable_tiles_within_radius(agent_tile_pos, MOVE_RADIUS_TILES, agent.rem_action_points)
		var min_dist_to_objective := INF
		for tile in tiles_within_radius:
			var dist_to_objective = tile.distance_to(objective_tile_pos)
			if dist_to_objective < min_dist_to_objective:
				min_dist_to_objective = dist_to_objective
				tile_to_move_to = min_dist_to_objective
	return 0.0

func execute(_agent: Agent, _world_state: WorldState, _on_complete: Callable) -> void:
	pass
