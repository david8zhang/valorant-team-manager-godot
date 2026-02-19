class_name AbilityStats
extends Resource

enum AbilityType {
	FLASH,
	INFO_BEACON,
	MOLLY,
	RECON_DART,
	SMOKE,
	STIM,
	STUN_GRENADE,
	WALL
}

@export var ability_name := ""
@export var ability_texture: Texture2D
@export var ability_type: AbilityType
@export var total_charges := 0
@export var ap_cost := 0