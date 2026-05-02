class_name SingleCPUAgentController
extends Node

var actions: Array[SingleAgentAction] = []
var agent: Agent
var cpu_agent_controller: CPUAgentController

func _init(_agent: Agent, _cpu_agent_controller: CPUAgentController):
	agent = _agent
	cpu_agent_controller = _cpu_agent_controller
	actions = cpu_agent_controller.single_agent_action_factory.get_actions_for_agent(agent)

func start_turn():
	pass

func _get_best_action(_world_state) -> SingleAgentAction:
	var curr_highest_score := -1.0
	var selected_action = null
	for action in actions:
		var util_score = action.get_utility(agent, {})
		if util_score > curr_highest_score:
			selected_action = action
	return selected_action if curr_highest_score > 0.2 else null