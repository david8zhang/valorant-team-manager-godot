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
	game_round.action_menu.on_action.connect(handle_new_action_state)
	game_round.action_menu.mouse_entered.connect(enter_hover_action_menu)
	game_round.action_menu.mouse_exited.connect(exit_hover_action_menu)

	for a in game_round.cpu_team.agents:
		var agent = a as Agent
		agent.on_agent_click.connect(handle_enemy_agent_click)

func handle_enemy_agent_click(agent):
	if curr_action_state == ActionState.PRIMARY_ATTACK or curr_action_state == ActionState.SECONDARY_ATTACK:
		var midpoint_pos = Vector2((selected_agent.global_position.x + agent.global_position.x) / 2, (selected_agent.global_position.y + agent.global_position.y) / 2)
		game_round.game_camera.target_position = midpoint_pos
		var battle_preview_menu = game_round.battle_preview_menu
		battle_preview_menu.show()

func exit_hover_action_menu():
	is_hovering_action_menu = false

func enter_hover_action_menu():
	is_hovering_action_menu = true

func handle_new_action_state(new_action_state):
	highlight_overlay.hide()
	match new_action_state:
		ActionState.MOVE:
			highlight_overlay.show()
	curr_action_state = new_action_state

func _process(_delta):
	if game_round.curr_turn_side == GameRound.Side.PLAYER and !is_hovering_action_menu:
		match curr_action_state:
			ActionState.MOVE:
				if Input.is_action_just_pressed("mouse_left"):
					highlight_overlay.should_update_pos = false
					var pos_to_move_to = game_round.map.ground_layer.map_to_local(highlight_overlay.hovered_tile_pos)
					selected_agent.move_to_position(pos_to_move_to, complete_move)
					center_camera_on_position(pos_to_move_to)
				if Input.is_action_just_pressed("center_camera"):
					center_camera_on_agent(selected_agent)

func start_turn():
	select_agent(team.agents[0])
	game_round.update_visible_enemies()

func complete_move():
	highlight_overlay.should_update_pos = true
	game_round.update_visible_enemies()

func complete_turn():
	on_complete_turn.emit()

func select_agent(agent: Agent):
	selected_agent = agent
	center_camera_on_agent(agent)
	selected_agent.update_and_show_visible_tiles()

func center_camera_on_agent(agent: Agent):
	game_round.game_camera.target_position = agent.global_position

func center_camera_on_position(new_pos: Vector2):
	game_round.game_camera.target_position = new_pos
