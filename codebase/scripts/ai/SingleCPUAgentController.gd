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
	# Safety Check: Stop if the agent died between turns
	if agent == null or agent.is_dead():
		cpu_agent_controller.complete_turn()
		return
	GameRoundVariables.cpu_world_state.update_map_control_view()
	GameRoundVariables.cpu_world_state.update_cpu_vision()
	var best_action = _get_best_action()
	# Check if we have an action AND enough AP
	if best_action != null and agent.rem_action_points >= best_action.ap_cost:
		print("[%s] Best action: %s" % [agent.agent_name, best_action.action_name])
		best_action.execute(agent, GameRoundVariables.cpu_world_state, select_and_do_action)
	else:
		# If no action (or no AP), wait briefly to allow for visual pacing, then end turn
		await agent.get_tree().create_timer(0.5).timeout
		cpu_agent_controller.complete_turn()

func _get_best_action() -> SingleAgentAction:
	var curr_highest_score := -1.0
	var selected_action = null
	for action in actions:
		var util_score = action.get_utility(agent, GameRoundVariables.cpu_world_state)
		# Debugging: Only print if the score is actually meaningful to keep logs clean
		if util_score > 0.1:
			print("[%s] util score for %s: %.2f" % [agent.agent_name, action.action_name, util_score])
		if util_score > curr_highest_score:
			curr_highest_score = util_score
			selected_action = action
	# Threshold check: Only return the action if it exceeds 0.2
	return selected_action if curr_highest_score > 0.2 else null
