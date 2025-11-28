class_name AgentController
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
@export var highlight_overlay: HighlightOverlay
@export var team: Team

enum ActionState {
	NONE,
	WATCH,
	DEFUSE,
	PLANT,
	MOVE,
	PRIMARY_ATTACK,
	SECONDARY_ATTACK,
	ABILITY_ONE,
	ABILITY_TWO
}

signal on_complete_turn

var selected_agent: Agent
var curr_action_state: ActionState = ActionState.NONE
var is_hovering_action_menu := false

func _ready() -> void:
	await game_round.ready
	game_round.action_menu.on_action.connect(set_action_state_move)
	game_round.action_menu.mouse_entered.connect(enter_hover_action_menu)
	game_round.action_menu.mouse_exited.connect(exit_hover_action_menu)

func set_action_state_move(new_action_state: ActionState):
	curr_action_state = new_action_state

func exit_hover_action_menu():
	is_hovering_action_menu = false

func enter_hover_action_menu():
	is_hovering_action_menu = true

func _process(_delta):
	if game_round.curr_turn_side == GameRound.Side.PLAYER and !is_hovering_action_menu: 
		if Input.is_action_just_pressed("mouse_left") and curr_action_state == ActionState.MOVE:
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
