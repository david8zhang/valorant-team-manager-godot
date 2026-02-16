class_name AgentBuyMenu
extends Control

@onready var panel_container = $PanelContainer as PanelContainer
@onready var agent_name_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/Label
@onready var kill_count_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/HBoxContainer/KillCount
@onready var death_count_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/HBoxContainer2/DeathCount
@onready var assist_count_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/HBoxContainer3/AssistCount
@onready var shield_icon = $PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Shield as TextureRect
@onready var weapon_sprite = $PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Gun as TextureRect
@onready var button = $Button as Button

signal on_click(agent_buy_menu)

func _ready() -> void:
	button.pressed.connect(click)

func click():
	on_click.emit(self)

func init_from_agent(agent: Agent):
	# Populate agent stats
	agent_name_label.text = agent.agent_name
	var agent_stats = GameRoundVariables.get_or_create_agent_game_stat(agent.agent_name) as GameRoundVariables.AgentGameStats
	kill_count_label.text = str(agent_stats.kill_count)
	death_count_label.text = str(agent_stats.death_count)
	assist_count_label.text = str(agent_stats.assist_count)

	# Populate weapon sprite
	var weapon_stats: WeaponStats
	if agent.primary_weapon != null:
		weapon_stats = agent.primary_weapon.weapon_stats
	elif agent.sidearm_weapon != null:
		weapon_stats = agent.sidearm_weapon.weapon_stats
	if weapon_stats != null:
		weapon_sprite.texture = weapon_stats.texture

	# Show if agent has shields or not
	var alpha = 1 if agent.shield_bar.value == Agent.MAX_SHIELDS else 0
	shield_icon.modulate.a = alpha

func highlight():
	var selected_stylebox = load("res://prefabs/BuyMenu_Selected.tres") as StyleBoxFlat
	panel_container.add_theme_stylebox_override("panel", selected_stylebox)

func de_highlight():
	var default_stylebox = load("res://prefabs/AgentStatusPanelBG.tres") as StyleBoxFlat
	panel_container.add_theme_stylebox_override("panel", default_stylebox)