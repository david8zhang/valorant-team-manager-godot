class_name ActionMenu
extends PanelContainer

@onready var watch_button = $VBoxContainer/NonCombatAndStats/NonCombatActions/Watch as Button
@onready var bomb_button = $VBoxContainer/NonCombatAndStats/NonCombatActions/Bomb as Button
@onready var move_button = $VBoxContainer/NonCombatAndStats/NonCombatActions/Move as Button
@onready var primary_weapon = $VBoxContainer/CombatAbilities/PrimaryWeapon as Button
@onready var secondary_weapon = $VBoxContainer/CombatAbilities/SideArm as Button
@onready var primary_weapon_ammo_meter = $VBoxContainer/CombatAbilities/PrimaryWeapon/ProgressBar as ProgressBar
@onready var secondary_weapon_ammo_meter = $VBoxContainer/CombatAbilities/SideArm/ProgressBar as ProgressBar

signal on_action(action_state)

func _ready() -> void:
	move_button.pressed.connect(func (): on_action_click(AgentController.ActionState.MOVE))
	bomb_button.pressed.connect(func (): on_action_click(AgentController.ActionState.DEFUSE))
	watch_button.pressed.connect(func (): on_action_click(AgentController.ActionState.WATCH))
	primary_weapon.pressed.connect(func (): on_action_click(AgentController.ActionState.PRIMARY_ATTACK))
	secondary_weapon.pressed.connect(func (): on_action_click(AgentController.ActionState.SECONDARY_ATTACK))

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
			highlight_single_button(secondary_weapon)

func de_highlight_all_buttons():
	dehighlight_single_button(watch_button)
	dehighlight_single_button(bomb_button)
	dehighlight_single_button(move_button)
	dehighlight_single_button(primary_weapon, 0.75)
	dehighlight_single_button(secondary_weapon, 0.75)

func dehighlight_single_button(button, color = 0.6):
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, color, color)
	button.add_theme_stylebox_override("normal", sb)

func highlight_single_button(button):
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 1, 0)
	button.add_theme_stylebox_override("normal", sb)
