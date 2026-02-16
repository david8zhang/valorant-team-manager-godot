class_name GunBuyMenuOption
extends PanelContainer

@onready var texture_rect = $MarginContainer/VBoxContainer/TextureRect as TextureRect
@onready var name_label = $MarginContainer/VBoxContainer/HBoxContainer/Label as Label
@onready var price_label = $MarginContainer/VBoxContainer/HBoxContainer/Label2 as Label
@onready var button = $Button as Button

@export var gun_name := ""
@export var gun_price := 0
@export var texture: Texture2D

signal on_click(gun_buy_menu_option)

func _ready() -> void:
	name_label.text = gun_name
	price_label.text = "Free" if gun_price == 0 else str(gun_price)
	texture_rect.texture = texture
	button.pressed.connect(click)

func click():
	on_click.emit(self)

func highlight():
	var selected_stylebox = load("res://prefabs/BuyMenu_Selected.tres") as StyleBoxFlat
	add_theme_stylebox_override("panel", selected_stylebox)

func de_highlight():
	var default_stylebox = load("res://prefabs/BuyMenuWeapon.tres") as StyleBoxFlat
	add_theme_stylebox_override("panel", default_stylebox)