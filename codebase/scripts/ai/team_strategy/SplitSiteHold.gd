class_name SplitSiteHold
extends TeamStrategy

func get_suitability(_state: WorldState) -> float:
	print("Getting suitability for Split Site Hold")
	return 0.0

func assign_roles(_agents: Array, _state: WorldState) -> void:
	print("Assigning roles for Split Site Hold")
	return