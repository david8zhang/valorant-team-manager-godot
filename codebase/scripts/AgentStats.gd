class_name AgentStats
extends Resource

enum AgentType {
	DUELIST,
	INITIATOR,
	SENTINEL,
	CONTROLLER
}

@export var agent_type: AgentType
@export var agent_name := ""
@export var texture: Texture2D
@export var ability_1: AbilityStats
@export var ability_2: AbilityStats
