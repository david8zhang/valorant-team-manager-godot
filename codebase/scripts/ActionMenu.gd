class_name ActionMenu
extends PanelContainer

@onready var game_round = get_node("/root/GameRound") as GameRound
@onready var watch_button = $VBoxContainer/NonCombatAndStats/NonCombatActions/Watch as Button
@onready var bomb_button = $VBoxContainer/NonCombatAndStats/NonCombatActions/Bomb as Button
@onready var bomb_texture = $VBoxContainer/NonCombatAndStats/NonCombatActions/Bomb/TextureRect as TextureRect
@onready var move_button = $VBoxContainer/NonCombatAndStats/NonCombatActions/Move as Button
@onready var defuse_button = $VBoxContainer/NonCombatAndStats/NonCombatActions/Defuse as Button
@onready var defuse_texture = $VBoxContainer/NonCombatAndStats/NonCombatActions/Defuse/TextureRect as TextureRect
@onready var primary_weapon = $VBoxContainer/CombatAbilities/PrimaryWeapon as ActionMenuWeapon
@onready var sidearm_weapon = $VBoxContainer/CombatAbilities/SidearmWeapon as ActionMenuWeapon
@onready var ability_1 = $VBoxContainer/CombatAbilities/Ability1 as Button
@onready var ability_2 = $VBoxContainer/CombatAbilities/Ability2 as Button

@onready var action_point_menu = $VBoxContainer/NonCombatAndStats/VBoxContainer/HBoxContainer as HBoxContainer
@onready var health_bar = $VBoxContainer/NonCombatAndStats/VBoxContainer/Health as ProgressBar
@onready var shield_bar = $VBoxContainer/NonCombatAndStats/VBoxContainer/Shields as ProgressBar
@onready var end_turn_button = $VBoxContainer/NonCombatAndStats/EndTurn as Button

@onready var ability_1_texture = $VBoxContainer/CombatAbilities/Ability1/MarginContainer/VBoxContainer/TextureRect as TextureRect
@onready var ability_1_charges_container = $VBoxContainer/CombatAbilities/Ability1/MarginContainer/VBoxContainer/HBoxContainer as HBoxContainer
@onready var ability_2_texture = $VBoxContainer/CombatAbilities/Ability2/MarginContainer/VBoxContainer/TextureRect as TextureRect
@onready var ability_2_charges_container = $VBoxContainer/CombatAbilities/Ability2/MarginContainer/VBoxContainer/HBoxContainer as HBoxContainer

@export var ability_charge_scene: PackedScene

var agent_controller: AgentController
var ap_rect_cost_style
var ap_rect_unused_style
var ap_rect_used_style

signal on_action(action_state)

func _ready() -> void:
	move_button.pressed.connect(func (): on_action_click(AgentController.ActionState.MOVE))
	bomb_button.pressed.connect(on_bomb_button_clicked)
	defuse_button.pressed.connect(on_defuse_button_clicked)
	watch_button.pressed.connect(func (): on_action_click(AgentController.ActionState.WATCH))
	primary_weapon.pressed.connect(func (): on_action_click(AgentController.ActionState.PRIMARY_ATTACK))
	sidearm_weapon.pressed.connect(func (): on_action_click(AgentController.ActionState.SECONDARY_ATTACK))
	ability_1.pressed.connect(func (): on_action_click(AgentController.ActionState.ABILITY_ONE))
	ability_2.pressed.connect(func (): on_action_click(AgentController.ActionState.ABILITY_TWO))
	end_turn_button.pressed.connect(end_curr_turn)
	ap_rect_cost_style = load("res://prefabs/ActionPoint_CostPreview.tres")
	ap_rect_unused_style = load("res://prefabs/ActionPoint_Unused.tres")
	ap_rect_used_style = load("res://prefabs/ActionPoint_Used.tres")

func on_action_click(action_state: AgentController.ActionState):
	on_action.emit(action_state)
	set_button_highlight_from_state(action_state)

func set_button_highlight_from_state(curr_action_state: AgentController.ActionState):
	de_highlight_all_buttons()
	match curr_action_state:
		AgentController.ActionState.MOVE:
			highlight_single_button(move_button)
		AgentController.ActionState.WATCH:
			highlight_single_button(watch_button)
		AgentController.ActionState.DEFUSE, AgentController.ActionState.PLANT:
			highlight_single_button(bomb_button)
		AgentController.ActionState.PRIMARY_ATTACK:
			highlight_single_button(primary_weapon)
		AgentController.ActionState.SECONDARY_ATTACK:
			highlight_single_button(sidearm_weapon)
		AgentController.ActionState.ABILITY_ONE:
			highlight_single_button(ability_1)
		AgentController.ActionState.ABILITY_TWO:
			highlight_single_button(ability_2)

func de_highlight_all_buttons():
	dehighlight_single_button(watch_button)
	dehighlight_single_button(bomb_button)
	dehighlight_single_button(move_button)
	dehighlight_single_button(primary_weapon, 0.75)
	dehighlight_single_button(sidearm_weapon, 0.75)
	dehighlight_single_button(ability_1, 0.75)
	dehighlight_single_button(ability_2, 0.75)

func dehighlight_single_button(button, color = 0.6):
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, color, color)
	button.add_theme_stylebox_override("normal", sb)

func highlight_single_button(button):
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("#46daa69b")
	button.add_theme_stylebox_override("normal", sb)

func preview_ap_cost(ap_cost):
	var selected_agent = agent_controller.selected_agent
	var ap_rects = action_point_menu.get_children().slice(0, selected_agent.rem_action_points)
	ap_rects.reverse()
	for i in range(0, ap_rects.size()):
		var ap_rect = ap_rects[i] as Panel
		if i < ap_cost:
			ap_rect.add_theme_stylebox_override("panel", ap_rect_cost_style)
		else:
			ap_rect.add_theme_stylebox_override("panel", ap_rect_unused_style)

func update_ap_menu():
	var selected_agent = agent_controller.selected_agent
	var ap_rects = action_point_menu.get_children()
	for i in range(0, ap_rects.size()):
		var ap_rect = ap_rects[i]
		if i < selected_agent.rem_action_points:
			ap_rect.add_theme_stylebox_override("panel", ap_rect_unused_style)
		else:
			ap_rect.add_theme_stylebox_override("panel", ap_rect_used_style)

func update_health_and_shields():
	var selected_agent = agent_controller.selected_agent as Agent
	health_bar.value = selected_agent.health_bar.value
	shield_bar.value = selected_agent.shield_bar.value

func update_weapon_info():
	var selected_agent = agent_controller.selected_agent as Agent
	primary_weapon.update_from_weapon(selected_agent.primary_weapon)
	sidearm_weapon.update_from_weapon(selected_agent.sidearm_weapon)

func update_defuse_status():
	var selected_agent = agent_controller.selected_agent as Agent
	if game_round.attack_side != selected_agent.curr_side:
		var is_at_bomb_pos = selected_agent.global_position == game_round.bomb.global_position
		if is_at_bomb_pos:
			defuse_button.show()
		else:
			defuse_button.hide()

func update_bomb_status():
	var selected_agent = agent_controller.selected_agent as Agent
	if selected_agent.has_bomb:
		bomb_button.show()
		if can_plant_bomb(selected_agent):
			bomb_button.disabled = false
		else:
			bomb_button.disabled = true
	else:
		bomb_button.hide()

func can_plant_bomb(selected_agent: Agent):
	var agent_tile_pos = game_round.map.get_tile_pos_from_world_pos(selected_agent.global_position)
	return game_round.map.is_at_bomb_site(agent_tile_pos) and selected_agent.has_bomb and selected_agent.rem_action_points == 5

func can_defuse_bomb(selected_agent: Agent):
	return selected_agent.rem_action_points == 5

func on_bomb_button_clicked():
	var selected_agent = agent_controller.selected_agent as Agent
	if can_plant_bomb(selected_agent):
		if !selected_agent.is_planting:
			bomb_texture.texture = load("res://assets/placeholder/ban-solid-full.svg")
			game_round.start_plant_bomb(selected_agent)
		else:
			bomb_texture.texture = load("res://assets/placeholder/bomb-solid-full.svg")
			game_round.stop_plant_bomb(selected_agent)

func on_defuse_button_clicked():
	var selected_agent = agent_controller.selected_agent as Agent
	if can_defuse_bomb(selected_agent):
		if !selected_agent.is_defusing:
			defuse_texture.texture = load("res://assets/placeholder/ban-solid-full.svg")
			game_round.start_defuse_bomb(selected_agent)
		else:
			defuse_texture.texture = load("res://assets/placeholder/wrench-solid-full.svg")
			game_round.stop_defuse_bomb(selected_agent)

func update_ability_menu():
	var selected_agent = agent_controller.selected_agent
	var ability_1_stats: AbilityStats = selected_agent.agent_stats.ability_1
	var ability_2_stats: AbilityStats = selected_agent.agent_stats.ability_2
	ability_1_texture.texture = ability_1_stats.ability_texture
	ability_2_texture.texture = ability_2_stats.ability_texture
	for c in ability_1_charges_container.get_children():
		ability_1_charges_container.remove_child(c)
	for c in ability_2_charges_container.get_children():
		ability_2_charges_container.remove_child(c)
	for i in range(0, selected_agent.ability_1_charges):
		_add_ability_charge(ability_1_charges_container)
	for i in range(0, selected_agent.ability_2_charges):
		_add_ability_charge(ability_2_charges_container)

func update_all():
	update_ap_menu()
	update_health_and_shields()
	update_weapon_info()
	update_defuse_status()
	update_bomb_status()
	update_ability_menu()

func end_curr_turn():
	if game_round.curr_turn_side == GameRound.Side.PLAYER:
		hide()
		agent_controller.complete_turn()

func _add_ability_charge(container: HBoxContainer):
	var charge_rect = ability_charge_scene.instantiate() as AbilityChargeRect
	charge_rect.rect_width = 10
	charge_rect.rect_height = 10
	container.add_child(charge_rect)
