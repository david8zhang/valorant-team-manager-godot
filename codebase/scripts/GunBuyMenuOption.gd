class_name GunBuyMenuOption
extends PanelContainer

@onready var texture_rect = $MarginContainer/VBoxContainer/TextureRect as TextureRect
@onready var name_label = $MarginContainer/VBoxContainer/HBoxContainer/Label as Label
@onready var price_label = $MarginContainer/VBoxContainer/HBoxContainer/Label2 as Label
@onready var button = $Button as Button

@export var weapon_stats: WeaponStats

signal on_click(gun_buy_menu_option)

func _ready() -> void:
	if weapon_stats != null:
		name_label.text = GameRoundVariables.get_weapon_name_str(weapon_stats.weapon_name).to_pascal_case()
		price_label.text = "Free" if weapon_stats.cost == 0 else str(weapon_stats.cost)
		texture_rect.texture = weapon_stats.in_menu_texture
		button.pressed.connect(click)

func click():
	on_click.emit(self)

func highlight():
	var selected_stylebox = load("res://prefabs/BuyMenu_Selected.tres") as StyleBoxFlat
	add_theme_stylebox_override("panel", selected_stylebox)

func de_highlight():
	var default_stylebox = load("res://prefabs/BuyMenuWeapon.tres") as StyleBoxFlat
	add_theme_stylebox_override("panel", default_stylebox)
