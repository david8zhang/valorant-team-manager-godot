class_name BattlePreview
extends PanelContainer

@onready var fire_button = $MarginContainer/VBoxContainer/Fire as Button
@onready var attacker_shields = $MarginContainer/VBoxContainer/HealthPreview/AttackerStats/AttackerShields
@onready var attacker_health = $MarginContainer/VBoxContainer/HealthPreview/AttackerStats/AttackerHealth
@onready var defender_shields = $MarginContainer/VBoxContainer/HealthPreview/DefenderStats/DefenderShields
@onready var defender_health = $MarginContainer/VBoxContainer/HealthPreview/DefenderStats/DefenderHealth

signal on_fire_clicked

func _ready() -> void:
	fire_button.pressed.connect(on_fire)

func on_fire():
	on_fire_clicked.emit()

func update_preview(attacker: Agent, defender: Agent):
	attacker_shields.value = attacker.shield_bar.value
	attacker_health.value = attacker.health_bar.value
	defender_shields.value = defender.shield_bar.value
	defender_health.value = defender.health_bar.value
