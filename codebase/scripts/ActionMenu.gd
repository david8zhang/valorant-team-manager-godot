class_name ActionMenu
extends PanelContainer

@onready var watch_button = $VBoxContainer/NonCombatAndStats/NonCombatActions/Watch as Button
@onready var bomb_button = $VBoxContainer/NonCombatAndStats/NonCombatActions/Bomb as Button
@onready var move_button = $VBoxContainer/NonCombatAndStats/NonCombatActions/Move as Button

signal on_action(action_state)

func _ready() -> void:
	move_button.pressed.connect(func (): on_action_click(AgentController.ActionState.MOVE))
	bomb_button.pressed.connect(func (): on_action_click(AgentController.ActionState.DEFUSE))
	watch_button.pressed.connect(func (): on_action_click(AgentController.ActionState.WATCH))

func on_action_click(action_state: AgentController.ActionState):
	on_action.emit(action_state)
	set_button_highlight_from_state(action_state)

func set_button_highlight_from_state(curr_action_state: AgentController.ActionState):
	dehighlight_all_buttons()
	match curr_action_state:
		AgentController.ActionState.MOVE:
			highlight_single_button(move_button)
		AgentController.ActionState.WATCH:
			highlight_single_button(watch_button)
		AgentController.ActionState.DEFUSE, AgentController.ActionState.PLANT:
			highlight_single_button(bomb_button)

func dehighlight_all_buttons():
	dehighlight_single_button(watch_button)
	dehighlight_single_button(bomb_button)
	dehighlight_single_button(move_button)

func dehighlight_single_button(button):
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.6, 0.6, 0.6)  # blue background
	button.add_theme_stylebox_override("normal", sb)

func highlight_single_button(button):
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0, 1, 0)  # blue background
	button.add_theme_stylebox_override("normal", sb)