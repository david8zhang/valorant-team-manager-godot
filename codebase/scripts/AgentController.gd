class_name AgentController
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
@export var highlight_overlay: HighlightOverlay

signal on_complete_turn

var selected_agent: Agent

func _ready() -> void:
	await game_round.ready
	selected_agent = game_round.player_team.agents[0]

func _process(_delta):
	if game_round.curr_turn_side == GameRound.Side.PLAYER and Input.is_action_just_pressed("mouse_left"):
		var pos_to_move_to = game_round.map.ground_layer.map_to_local(highlight_overlay.hovered_tile_pos)
		selected_agent.move_to_position(pos_to_move_to, complete_turn)

func complete_turn():
	on_complete_turn.emit()
