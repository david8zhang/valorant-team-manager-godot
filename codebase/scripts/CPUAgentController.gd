class_name CPUAgentController
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
signal on_complete_turn
var selected_agent: Agent

func _ready() -> void:
	await game_round.ready
	selected_agent = game_round.cpu_team.agents[0]

func move_agent():
	var pos_to_move_to = get_positions_to_move_to()
	var rand_pos = game_round.map.get_world_pos_from_tile_pos(pos_to_move_to.pick_random())
	selected_agent.move_to_position(rand_pos, complete_turn)

func complete_turn():
	on_complete_turn.emit()

func get_positions_to_move_to():
	var radius = 10.0
	var pos_to_move_to = []
	for x_diff in range(-radius / 2, radius / 2):
		for y_diff in range(-radius / 2, radius / 2):
			var curr_agent_tile_pos = game_round.map.get_tile_pos_from_world_pos(selected_agent.global_position)
			var pos = Vector2(curr_agent_tile_pos.x + x_diff, curr_agent_tile_pos.y + y_diff)
			if game_round.map.is_tile_pos_in_bounds(pos) and !game_round.is_position_occupied(pos):
				pos_to_move_to.append(pos)
	return pos_to_move_to
