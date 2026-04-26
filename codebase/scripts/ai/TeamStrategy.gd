class_name TeamStrategy
extends Resource

enum StrategyType {
	DEFAULT,
	RUSH,
	EXECUTE,
	RETAKE
}

@export var strategy_type: StrategyType
@export var target_site: String
@export var aggression_multiplier := 1.0
@export var fallback_threshold := 0.3