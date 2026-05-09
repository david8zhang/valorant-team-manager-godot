class_name HoldAngle
extends SingleAgentAction

func get_utility(_agent: Agent, _world_state: WorldState) -> float:
	# 1. Get all visible tiles in each compass direction angle (N, S, E, W, NE, NW, SE, SW)
	# 2. For each visible tile set, check if it covers a dangerous waypoint
	# 3. Determining a "dangerous" choke point is based on proximity to enemy controlled map areas (danger heatmap)
	return 0.0

func execute(_agent: Agent, _world_state: WorldState, _on_complete: Callable) -> void:
	pass
