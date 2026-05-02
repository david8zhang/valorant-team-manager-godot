class_name CPUAgentController
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
@onready var single_agent_action_factory = $SingleAgentActionFactory as SingleAgentActionFactory
@export var strategy_playbook: Array[TeamStrategy] = []

signal on_complete_turn
signal on_complete_move
var selected_agent: Agent
var cached_top_view_state
var team_strategy: TeamStrategy
var attack_strategies := []
var defense_strategies := []

func _ready() -> void:
	await game_round.ready
	selected_agent = game_round.cpu_team.agents[0]
	for a in game_round.cpu_team.agents:
		var agent = a as Agent
		agent.vision_direction = Vector2.DOWN
		agent.update_visible_tiles()
		var single_agent_controller = SingleCPUAgentController.new(agent, self)
		agent.single_agent_controller = single_agent_controller

	# Load strategy playbook
	for s in strategy_playbook:
		var strategy = s as TeamStrategy
		if strategy.strategy_side == TeamStrategy.StrategySide.ATTACK:
			attack_strategies.append(strategy)
		else:
			defense_strategies.append(strategy)

func select_round_strategy():
	var playbook_to_use = attack_strategies if game_round.attack_side == GameRound.Side.CPU else defense_strategies
	var max_suitability_score := -1.0
	var best_strategy: TeamStrategy
	for s in playbook_to_use:
		var strategy = s as TeamStrategy
		var suitability_score = strategy.get_suitability(GameRoundVariables.cpu_world_state)
		if suitability_score > max_suitability_score:
			best_strategy = strategy
	team_strategy = best_strategy
	team_strategy.assign_roles(game_round.cpu_team.get_all_living_agents(), GameRoundVariables.cpu_world_state)

func move_agent():
	var pos_to_move_to = get_positions_to_move_to()
	var rand_pos = game_round.map.get_world_pos_from_tile_pos(pos_to_move_to.pick_random())
	selected_agent.move_to_position(rand_pos, complete_move)

func start_turn(agent_to_select: Agent):
	selected_agent = agent_to_select
	selected_agent.rem_action_points = Agent.TOTAL_ACTION_POINTS
	move_agent()

func complete_move():
	on_complete_move.emit()
	attack_target_if_possible()

func attack_target_if_possible():
	if selected_agent.is_dead():
		complete_turn()
	else:
		var visible_tiles = selected_agent.get_visible_tiles()
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
			cached_top_view_state = game_round.top_view_state
			game_round.set_top_view_state(GameRound.TopViewState.HIDDEN)
			selected_agent.attack_enemy_agent(target_to_attack, true, complete_turn)
		else:
			complete_turn()

func complete_turn():
	if cached_top_view_state != null:
		game_round.set_top_view_state(cached_top_view_state)
	selected_agent.has_completed_turn = true
	on_complete_turn.emit()

func get_positions_to_move_to():
	var radius = 10.0
	var pos_to_move_to = []
	for x_diff in range(-radius / 2, radius / 2):
		for y_diff in range(-radius / 2, radius / 2):
			var curr_agent_tile_pos = game_round.map.get_tile_pos_from_world_pos(selected_agent.global_position)
			var pos = Vector2(curr_agent_tile_pos.x + x_diff, curr_agent_tile_pos.y + y_diff)
			var world_pos = game_round.map.get_world_pos_from_tile_pos(pos)
			if game_round.can_move_to_pos(selected_agent.global_position, world_pos):
				pos_to_move_to.append(pos)
	return pos_to_move_to
