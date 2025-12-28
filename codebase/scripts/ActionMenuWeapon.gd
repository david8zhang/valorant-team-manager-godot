class_name ActionMenuWeapon
extends Button

@onready var ammo_meter = $AmmoMeter as ProgressBar
@onready var texture_rect = $TextureRect as TextureRect
@onready var no_weapon_label = $NoWeaponLabel as Label

func update_from_weapon(weapon: Weapon):
    if weapon == null:
        ammo_meter.hide()
        texture_rect.hide()
        no_weapon_label.show()
    else:
        ammo_meter.show()
        ammo_meter.value = weapon.curr_ammo
        ammo_meter.max_value = weapon.max_ammo
        texture_rect.show()
        texture_rect.texture = weapon.weapon_stats.texture
        no_weapon_label.hide()