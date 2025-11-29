class_name BattlePreview
extends PanelContainer

@onready var fire_button = $MarginContainer/VBoxContainer/Fire as Button

signal on_fire_clicked

func _ready() -> void:
	fire_button.pressed.connect(on_fire)

func on_fire():
	on_fire_clicked.emit()
