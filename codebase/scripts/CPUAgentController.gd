class_name CPUAgentController
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
signal on_complete_turn
signal on_complete_move
var selected_agent: Agent

func _ready() -> void:
	await game_round.ready
	selected_agent = game_round.cpu_team.agents[0]
	for a in game_round.cpu_team.agents:
		var agent = a as Agent
		agent.vision_direction = Vector2.DOWN
		agent.update_visible_tiles()

func move_agent():
	var pos_to_move_to = get_positions_to_move_to()
	var rand_pos = game_round.map.get_world_pos_from_tile_pos(pos_to_move_to.pick_random())
	selected_agent.move_to_position(rand_pos, complete_move)

func start_turn():
	var agents_to_select = game_round.cpu_team.agents.filter(func (a: Agent): return !a.is_dead() and !a.has_completed_turn)
	if agents_to_select.is_empty():
		complete_turn()
	else:
		selected_agent = agents_to_select.pick_random()
		move_agent()

func complete_move():
	on_complete_move.emit()
	# Update visible enemies for player, since the game is from player's perspective
	game_round.update_visible_enemies()
	attack_target_if_possible()

func attack_target_if_possible():
	var visible_tiles = game_round.cpu_team.get_all_visible_tiles()
	var attackable_targets = []
	for tile in visible_tiles:
		for a in game_round.player_team.agents:
			var agent = a as Agent
			var agent_tile_pos = game_round.map.get_tile_pos_from_world_pos(agent.global_position)
			if !agent.is_dead() and agent_tile_pos.x == tile.x and agent_tile_pos.y == tile.y:
				attackable_targets.append(agent)
	if !attackable_targets.is_empty():
		var target_to_attack = attackable_targets[0]
		for t in attackable_targets:
			var target = t as Agent
			if target.get_curr_health() < target_to_attack.get_curr_health():
				target_to_attack = target

		# Move camera & attack
		var midpoint_pos = Vector2((selected_agent.global_position.x + target_to_attack.global_position.x) / 2, (selected_agent.global_position.y + target_to_attack.global_position.y) / 2)
		game_round.game_camera.target_position = midpoint_pos
		selected_agent.attack_enemy_agent(target_to_attack, true, complete_turn)
	else:
		complete_turn()

func complete_turn():
	selected_agent.has_completed_turn = true
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
