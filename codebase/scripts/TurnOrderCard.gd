class_name TurnOrderCard
extends Control

@onready var panel_container = $PanelContainer as PanelContainer
@onready var texture_rect = $PanelContainer/MarginContainer/VBoxContainer/TextureRect as TextureRect
@onready var agent_name_label = $PanelContainer/MarginContainer/VBoxContainer/Label as Label

func update_from_agent(agent: Agent):
	agent_name_label.text = agent.agent_name
	texture_rect.texture = agent.agent_stats.texture
	var base := panel_container.get_theme_stylebox("panel") as StyleBoxFlat
	base.bg_color = GameRoundVariables.CPU_OUTLINE_COLOR if agent.curr_side == GameRound.Side.CPU else GameRoundVariables.PLAYER_OUTLINE_COLOR
	base.bg_color.a = 0.25

func highlight_curr_card():
	var base := panel_container.get_theme_stylebox("panel") as StyleBoxFlat
	base.border_color = Color(1, 1, 0, 1)

func dehighlight_curr_card():
	var base := panel_container.get_theme_stylebox("panel") as StyleBoxFlat
	base.border_color = Color(1, 1, 1, 0)
