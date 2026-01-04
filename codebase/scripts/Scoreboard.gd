class_name Scoreboard
extends Control

enum Phase {
	BUY,
	SETUP,
	PRE_PLANT,
	POST_PLANT
}

@onready var player_score_label = $HBoxContainer/PlayerScoreContainer/MarginContainer/PlayerScore/Score
@onready var cpu_score_label = $HBoxContainer/CPUScoreContainer/MarginContainer/CPUScore/Score
@onready var round_number_label = $HBoxContainer/VBoxContainer/RoundInfoContainer/MarginContainer/RoundInfo/Label
@onready var round_info_container = $HBoxContainer/VBoxContainer/RoundInfoContainer as PanelContainer
@onready var turns_remaining_label = $HBoxContainer/VBoxContainer/RoundInfoContainer/MarginContainer/RoundInfo/Turns
@onready var turns_remaining_bottom_label = $HBoxContainer/VBoxContainer/RoundInfoContainer/MarginContainer/RoundInfo/TurnsLabel as Label
@onready var show_turn_order_button = $HBoxContainer/VBoxContainer/ShowTurnOrder as Button

static var PRE_PLANT_TURN_LIMIT = 10
static var POST_PLANT_TURN_LIMIT = 5
static var DEFUSE_TURN_LIMIT = 2

var turns_remaining = PRE_PLANT_TURN_LIMIT
var round_num := 1
var player_score := 0
var cpu_score := 0
var curr_phase := Phase.PRE_PLANT
var plant_turns_remaining = 0

func _ready() -> void:
	turns_remaining_label.text = str(turns_remaining)
	round_number_label.text = "Round " + str(round_num)
	player_score_label.text = str(player_score)
	cpu_score_label.text = str(cpu_score)

func decrement_turn():
	turns_remaining = max(0, turns_remaining - 1)
	turns_remaining_label.text = str(turns_remaining)

func reset_turns_remaining(turns):
	turns_remaining = turns
	turns_remaining_label.text = str(turns_remaining)

func on_bomb_planted():
	switch_to_phase(Scoreboard.Phase.POST_PLANT)

func incr_score(side: GameRound.Side):
	if side == GameRound.Side.CPU:
		cpu_score += 1
		cpu_score_label.text = str(cpu_score)
	else:
		player_score += 1
		player_score_label.text = str(player_score)

func incr_round():
	round_num += 1

func switch_to_phase(phase: Scoreboard.Phase):
	match phase:
		Phase.PRE_PLANT:
			turns_remaining = PRE_PLANT_TURN_LIMIT
			turns_remaining_label.text = str(turns_remaining)
			round_number_label.text = "Round " + str(round_num)
			round_number_label.add_theme_color_override("font_color", Color.BLACK)
			turns_remaining_label.add_theme_color_override("font_color", Color.BLACK)
			turns_remaining_bottom_label.add_theme_color_override("font_color", Color.BLACK)
			round_info_container.add_theme_stylebox_override("panel", load("res://prefabs/RoundTurnRem.tres"))
		Phase.POST_PLANT:
			# Only initialize the turns remaining count if the bomb was just planted
			turns_remaining = POST_PLANT_TURN_LIMIT
			turns_remaining_label.text = str(turns_remaining)
			round_number_label.text = "PLANTED"
			round_number_label.add_theme_color_override("font_color", Color.WHITE)
			turns_remaining_label.add_theme_color_override("font_color", Color.WHITE)
			turns_remaining_bottom_label.add_theme_color_override("font_color", Color.WHITE)
			round_info_container.add_theme_stylebox_override("panel", load("res://prefabs/PlantedTurnRem.tres"))
	curr_phase = phase