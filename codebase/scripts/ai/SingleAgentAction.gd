class_name SingleAgentAction
extends Resource

var ap_cost := 0
@export var action_name: String

func get_utility(_agent: Agent, _world_state: WorldState) -> float:
	return 0.0

func execute(_agent: Agent, _world_state: WorldState, _on_complete: Callable) -> void:
	pass