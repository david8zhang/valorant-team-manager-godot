class_name BattlePreview
extends PanelContainer

@onready var fire_button = $MarginContainer/VBoxContainer/Fire as Button
@onready var attacker_texture_rect = $MarginContainer/VBoxContainer/HeroPreview/Attacker as TextureRect
@onready var defender_texture_rect = $MarginContainer/VBoxContainer/HeroPreview/Defender as TextureRect
@onready var attacker_shields = $MarginContainer/VBoxContainer/HealthPreview/AttackerStats/AttackerShields
@onready var attacker_health = $MarginContainer/VBoxContainer/HealthPreview/AttackerStats/AttackerHealth
@onready var defender_shields = $MarginContainer/VBoxContainer/HealthPreview/DefenderStats/DefenderShields
@onready var defender_health = $MarginContainer/VBoxContainer/HealthPreview/DefenderStats/DefenderHealth
@onready var attacker_weapon = $MarginContainer/VBoxContainer/WeaponPreview/AttackerWeapon as TextureRect
@onready var defender_weapon = $MarginContainer/VBoxContainer/WeaponPreview/DefenderWeapon as TextureRect

signal on_fire_clicked

func _ready() -> void:
	fire_button.pressed.connect(on_fire)

func on_fire():
	on_fire_clicked.emit()

func update_preview(attacker: Agent, defender: Agent, weapon_to_attack_with: Weapon):
	attacker_texture_rect.texture = attacker.agent_stats.texture
	defender_texture_rect.texture = defender.agent_stats.texture	
	attacker_shields.value = attacker.shield_bar.value
	attacker_health.value = attacker.health_bar.value
	defender_shields.value = defender.shield_bar.value
	defender_health.value = defender.health_bar.value
	attacker_weapon.texture = weapon_to_attack_with.weapon_stats.in_menu_texture
	if defender.primary_weapon:
		defender_weapon.texture = defender.primary_weapon.weapon_stats.in_menu_texture
	else:
		defender_weapon.texture = defender.sidearm_weapon.weapon_stats.in_menu_texture
