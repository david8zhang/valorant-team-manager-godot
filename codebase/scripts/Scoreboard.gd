class_name Scoreboard
extends Control

@onready var player_score_label = $HBoxContainer/PlayerScoreContainer/MarginContainer/PlayerScore/Score
@onready var cpu_score_label = $HBoxContainer/CPUScoreContainer/MarginContainer/CPUScore/Score
@onready var round_number_label = $HBoxContainer/VBoxContainer/RoundInfoContainer/MarginContainer/RoundInfo/Label
@onready var turns_remaining_label = $HBoxContainer/VBoxContainer/RoundInfoContainer/MarginContainer/RoundInfo/Turns
@onready var show_turn_order_button = $HBoxContainer/VBoxContainer/ShowTurnOrder as Button

@export var PLANT_PHASE_TURN_LIMIT = 10
@export var DEFUSE_PHASE_TURN_LIMIT = 5

var turns_remaining = PLANT_PHASE_TURN_LIMIT
var round_num := 1
var player_score := 0
var cpu_score := 0

func _ready() -> void:
	turns_remaining_label.text = str(turns_remaining)
	round_number_label.text = "Round " + str(round_num)
	player_score_label.text = str(player_score)
	cpu_score_label.text = str(cpu_score)

func decrement_turn():
	turns_remaining = max(0, turns_remaining - 1)
	if turns_remaining == 0:
		print("Phase over!")
	turns_remaining_label.text = str(turns_remaining)
