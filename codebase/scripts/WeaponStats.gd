class_name WeaponStats
extends Resource

enum WeaponType {
    PRIMARY,
    SIDEARM
}

enum WeaponNames {
    NO_WEAPON,
    CLASSIC,
    SHERIFF,
    VANDAL,
    OPERATOR,
    SPECTRE,
    ODIN
}

@export var body_damage := 0
@export var headshot_damage := 0
@export var max_ammo := 0
@export var texture: Texture
@export var weapon_type: WeaponType
@export var weapon_name: WeaponNames
