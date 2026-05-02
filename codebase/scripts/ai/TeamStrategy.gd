class_name TeamStrategy
extends Resource

enum StrategyType {
	DEFAULT,
	RUSH,
	EXECUTE,
	RETAKE,
	SPLIT_SITE_HOLD,
	SITE_STACK
}

enum Site {
	NONE,
	A,
	B,
	C
}

enum StrategySide {
	DEFENSE,
	ATTACK
}

@export var strategy_type: StrategyType
@export var strategy_side: StrategySide
@export var aggression_multiplier := 1.0
@export var fallback_threshold := 0.3

func get_suitability(_state: WorldState) -> float:
	return 0.0

func assign_roles(_agents: Array, _state: WorldState) -> void:
	return