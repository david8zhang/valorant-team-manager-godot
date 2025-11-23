class_name AgentController
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
@export var highlight_overlay: HighlightOverlay
@export var team: Team

signal on_complete_turn

var selected_agent: Agent

func _process(_delta):
	if game_round.curr_turn_side == GameRound.Side.PLAYER and Input.is_action_just_pressed("mouse_left"):
		var pos_to_move_to = game_round.map.ground_layer.map_to_local(highlight_overlay.hovered_tile_pos)
		selected_agent.move_to_position(pos_to_move_to, complete_move)

func start_turn():
	select_agent(team.agents[0])
	game_round.update_visible_enemies()

func complete_move():
	game_round.update_visible_enemies()

func complete_turn():
	on_complete_turn.emit()

func select_agent(agent: Agent):
	selected_agent = agent
	game_round.game_camera.target_position = selected_agent.global_position
	selected_agent.update_and_show_visible_tiles()
