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
	# Load strategy playbook
	for s in strategy_playbook:
		var strategy = s as TeamStrategy
		if strategy.strategy_side == TeamStrategy.StrategySide.ATTACK:
			attack_strategies.append(strategy)
		else:
			defense_strategies.append(strategy)
	GameRoundVariables.cpu_world_state.initialize(self)
	await game_round.ready
	selected_agent = game_round.cpu_team.agents[0]
	for a in game_round.cpu_team.agents:
		var agent = a as Agent
		agent.vision_direction = Vector2.DOWN
		agent.update_tiles_in_view()
	game_round.agent_controller.on_complete_move.connect(GameRoundVariables.cpu_world_state.update_cpu_vision)

func select_round_strategy():
	var playbook_to_use = attack_strategies if game_round.attack_side == GameRound.Side.CPU else defense_strategies
	var max_suitability_score := -1.0
	if team_strategy != null:
		max_suitability_score = team_strategy.get_suitability(GameRoundVariables.cpu_world_state)	
	var best_strategy: TeamStrategy
	for s in playbook_to_use:
		var strategy = s as TeamStrategy
		var suitability_score = strategy.get_suitability(GameRoundVariables.cpu_world_state)
		if suitability_score > max_suitability_score:
			best_strategy = strategy
	if best_strategy != null:
		team_strategy = best_strategy
		team_strategy.assign_roles(game_round.cpu_team.get_all_living_agents(), GameRoundVariables.cpu_world_state)

func start_turn(agent_to_select: Agent):
	selected_agent = agent_to_select
	selected_agent.rem_action_points = Agent.TOTAL_ACTION_POINTS
	if !selected_agent.single_agent_controller:
		var single_agent_controller = SingleCPUAgentController.new(selected_agent, self)
		selected_agent.single_agent_controller = single_agent_controller
	var single_controller = selected_agent.single_agent_controller as SingleCPUAgentController
	single_controller.select_and_do_action()

func complete_turn():
	if cached_top_view_state != null:
		game_round.set_top_view_state(cached_top_view_state)
	selected_agent.has_completed_turn = true
	on_complete_turn.emit()
