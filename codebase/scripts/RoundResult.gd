class_name RoundResult
extends Control

enum WinCondition {
	ELIMINATION,
	TIME,
	DEFUSE,
	DETONATION
}

@onready var winning_side_label = $PanelContainer2/WinningSideLabel as Label
@onready var win_condition_label = $PanelContainer/MarginContainer/VBoxContainer/WinConditionLabel as Label
@onready var continue_button = $Button as Button

var last_winning_side: GameRound.Side

signal on_continue(winning_side: GameRound.Side)

func _ready() -> void:
	continue_button.pressed.connect(on_continue_pressed)

func on_continue_pressed():
	hide()
	on_continue.emit(last_winning_side)

func show_winning_side(side: GameRound.Side, win_condition: WinCondition):
	last_winning_side = side
	winning_side_label.text = "Player" if side == GameRound.Side.PLAYER else "CPU"
	match win_condition:
		WinCondition.ELIMINATION:
			win_condition_label.text = "ELIMINATION"
		WinCondition.TIME:
			win_condition_label.text = "TIME OUT"
		WinCondition.DEFUSE:
			win_condition_label.text = "BOMB DEFUSED"
		WinCondition.DETONATION:
			win_condition_label.text = "BOMB DETONATED"
	show()