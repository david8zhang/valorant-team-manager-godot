class_name AgentBuyMenu
extends Control

@onready var panel_container = $PanelContainer as PanelContainer
@onready var agent_name_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/Label
@onready var kill_count_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/HBoxContainer/KillCount
@onready var death_count_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/HBoxContainer2/DeathCount
@onready var assist_count_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/HBoxContainer3/AssistCount
@onready var shield_icon = $PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Shield as TextureRect
@onready var weapon_sprite = $PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/Gun as TextureRect
@onready var agent_sprite = $PanelContainer/VBoxContainer/MarginContainer/HBoxContainer/PlayerAvatar as TextureRect
@onready var button = $Button as Button

var agent_game_stats: GameRoundVariables.AgentGameStats
var primary_weapon_option: GunBuyMenuOption
var sidearm_weapon_option: GunBuyMenuOption
var original_primary_weapon_option: GunBuyMenuOption
var original_sidearm_weapon_option: GunBuyMenuOption

signal on_click(agent_buy_menu)

func _ready() -> void:
	button.pressed.connect(click)

func click():
	on_click.emit(self)

func init_from_agent(agent: Agent):
	# Populate agent stats
	agent_sprite.texture = agent.agent_stats.texture
	agent_name_label.text = agent.agent_name
	agent_game_stats = GameRoundVariables.get_or_create_agent_game_stat(agent.agent_name) as GameRoundVariables.AgentGameStats
	kill_count_label.text = str(agent_game_stats.kill_count)
	death_count_label.text = str(agent_game_stats.death_count)
	assist_count_label.text = str(agent_game_stats.assist_count)
	# Populate weapon sprite
	var weapon_stats: WeaponStats
	if agent.primary_weapon != null:
		weapon_stats = agent.primary_weapon.weapon_stats
	elif agent.sidearm_weapon != null:
		weapon_stats = agent.sidearm_weapon.weapon_stats
	if weapon_stats != null:
		weapon_sprite.texture = weapon_stats.in_game_texture
	# Show if agent has shields or not
	var alpha = 1 if agent.shield_bar.value == Agent.MAX_SHIELDS else 0
	shield_icon.modulate.a = alpha

func highlight():
	var selected_stylebox = load("res://prefabs/BuyMenu_Selected.tres") as StyleBoxFlat
	panel_container.add_theme_stylebox_override("panel", selected_stylebox)

func de_highlight():
	var default_stylebox = load("res://prefabs/AgentStatusPanelBG.tres") as StyleBoxFlat
	panel_container.add_theme_stylebox_override("panel", default_stylebox)

func select_to_buy(buy_menu: BuyMenu):
	highlight()
	if agent_game_stats.primary_weapon_name != WeaponStats.WeaponNames.NO_WEAPON:
		primary_weapon_option = buy_menu.get_gun_buy_menu_option_for_name(agent_game_stats.primary_weapon_name) as GunBuyMenuOption
		primary_weapon_option.highlight()
	if agent_game_stats.sidearm_weapon_name != WeaponStats.WeaponNames.NO_WEAPON:
		sidearm_weapon_option = buy_menu.get_gun_buy_menu_option_for_name(agent_game_stats.sidearm_weapon_name) as GunBuyMenuOption
		sidearm_weapon_option.highlight()

func purchase_weapon(gun_buy_menu_option: GunBuyMenuOption):
	var weapon_to_buy_stats = gun_buy_menu_option.weapon_stats
	# Check if we're trying to buy back the old weapon we had before
	if original_primary_weapon_option != null and \
	   original_primary_weapon_option.weapon_stats.weapon_name == weapon_to_buy_stats.weapon_name:
			undo_if_possible(primary_weapon_option)
	elif original_sidearm_weapon_option != null and \
			 original_sidearm_weapon_option.weapon_stats.weapon_name == weapon_to_buy_stats.weapon_name:
			undo_if_possible(sidearm_weapon_option)
	else:
		if weapon_to_buy_stats.weapon_type == WeaponStats.WeaponType.PRIMARY:
			var primary_weapon_stats = primary_weapon_option.weapon_stats
			if primary_weapon_stats.weapon_name != weapon_to_buy_stats.weapon_name:
				if original_primary_weapon_option == null:
					original_primary_weapon_option = primary_weapon_option
				if primary_weapon_option != null:
					primary_weapon_option.de_highlight()
				primary_weapon_option = gun_buy_menu_option
				primary_weapon_option.highlight()
				agent_game_stats.primary_weapon_name = weapon_to_buy_stats.weapon_name
				weapon_sprite.texture = weapon_to_buy_stats.in_game_texture
				GameRoundVariables.credits -= weapon_to_buy_stats.cost
		elif weapon_to_buy_stats.weapon_type == WeaponStats.WeaponType.SIDEARM:
			var sidearm_weapon_stats = sidearm_weapon_option.weapon_stats
			if sidearm_weapon_stats.weapon_name != weapon_to_buy_stats.weapon_name:
				if original_sidearm_weapon_option == null:
					original_sidearm_weapon_option = sidearm_weapon_option
				if sidearm_weapon_option != null:
					sidearm_weapon_option.de_highlight()
				sidearm_weapon_option = gun_buy_menu_option
				sidearm_weapon_option.highlight()
				agent_game_stats.sidearm_weapon_name = weapon_to_buy_stats.weapon_name
				GameRoundVariables.credits -= weapon_to_buy_stats.cost

func undo_if_possible(gun_buy_menu_option: GunBuyMenuOption):
	var clicked_stats = gun_buy_menu_option.weapon_stats
	var curr_primary_stats = primary_weapon_option.weapon_stats
	var curr_sidearm_stats = sidearm_weapon_option.weapon_stats
	if clicked_stats.weapon_name == curr_primary_stats.weapon_name and original_primary_weapon_option != null:
		var orig_primary_stats = original_primary_weapon_option.weapon_stats
		if curr_primary_stats.weapon_name != orig_primary_stats.weapon_name:
			primary_weapon_option.de_highlight()
			primary_weapon_option = original_primary_weapon_option
			primary_weapon_option.highlight()
			agent_game_stats.primary_weapon_name = orig_primary_stats.weapon_name
			weapon_sprite.texture = orig_primary_stats.in_game_texture
			GameRoundVariables.credits += curr_primary_stats.cost
	elif clicked_stats.weapon_name == curr_sidearm_stats.weapon_name and original_sidearm_weapon_option != null:
		var orig_sidearm_stats = original_sidearm_weapon_option.weapon_stats
		if curr_sidearm_stats.weapon_name != orig_sidearm_stats.weapon_name:
			sidearm_weapon_option.de_highlight()
			sidearm_weapon_option = original_sidearm_weapon_option
			sidearm_weapon_option.highlight()
			agent_game_stats.sidearm_weapon_name = orig_sidearm_stats.weapon_name
			GameRoundVariables.credits += curr_sidearm_stats.cost
