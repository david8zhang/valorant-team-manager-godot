class_name SingleCPUAgentController
extends Node

var actions: Array[SingleAgentAction] = []
var agent: Agent
var cpu_agent_controller: CPUAgentController

func _init(_agent: Agent, _cpu_agent_controller: CPUAgentController):
	agent = _agent
	cpu_agent_controller = _cpu_agent_controller
	actions = cpu_agent_controller.single_agent_action_factory.get_actions_for_agent(agent)

func select_and_do_action():
	GameRoundVariables.cpu_world_state.update_tiles_being_held()
	GameRoundVariables.cpu_world_state.update_map_control_view()
	GameRoundVariables.cpu_world_state.update_cpu_vision()
	print(agent.agent_name + " thinking...")
	await agent.get_tree().create_timer(0.5).timeout
	var best_action = _get_best_action()
	if best_action != null and agent.rem_action_points > 0:
		best_action.execute(agent, GameRoundVariables.cpu_world_state, select_and_do_action)
	else:
		cpu_agent_controller.complete_turn()

func _get_best_action() -> SingleAgentAction:
	var curr_highest_score := -1.0
	var selected_action = null
	for action in actions:
		var util_score = action.get_utility(agent, GameRoundVariables.cpu_world_state)
		if util_score > curr_highest_score:
			curr_highest_score = util_score
			selected_action = action
	return selected_action if curr_highest_score > 0.2 else null
