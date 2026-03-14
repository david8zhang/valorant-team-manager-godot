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
		MARSHALL,
    OPERATOR,
		STINGER,
    SPECTRE,
		ARES,
    ODIN
}

enum WeaponFireRate {
    LOW,
    MED,
    HIGH
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