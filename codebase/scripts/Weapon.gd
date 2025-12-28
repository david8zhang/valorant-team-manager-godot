class_name Weapon
extends Node

var weapon_stats: WeaponStats
var curr_ammo := 0
var max_ammo := 0

func _init(_weapon_stats: WeaponStats) -> void:
    weapon_stats = _weapon_stats
    max_ammo = _weapon_stats.max_ammo