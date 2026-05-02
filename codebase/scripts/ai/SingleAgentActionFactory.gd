class_name SingleAgentActionFactory
extends Node

@export var base_actions: Array[SingleAgentAction] = []

func get_actions_for_agent(agent: Agent):
	return base_actions
