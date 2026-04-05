class_name WeaponStats
extends Resource

enum WeaponType {
    PRIMARY,
    SIDEARM
}

enum WeaponNames {
	NO_WEAPON,
	CLASSIC,
	FRENZY,
	GHOST,
	SHERIFF,
	GUARDIAN,
	VANDAL,
	STINGER,
	SPECTRE,
	MARSHALL,
	OPERATOR,
	ARES,
	ODIN,
	BUCKY,
	JUDGE,
	PHANTOM,
	BULLDOG
}

enum WeaponFireRate {
    LOW,
    MED,
    HIGH,
		VERY_HIGH
}

@export var body_damage := 0
@export var headshot_damage := 0
@export var max_ammo := 0
@export var cost := 0
@export var in_game_texture: Texture
@export var in_menu_texture: Texture
@export var weapon_type: WeaponType
@export var weapon_name: WeaponNames
@export var weapon_fire_rate: WeaponFireRate
@export var animations: SpriteFrames
@export var barrel_x_pos := 0
@export var barrel_y_pos := 0
@export var barrel_y_pos_flip := 0
@export var scale := 0.0
