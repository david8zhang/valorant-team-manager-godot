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
var enemy_to_attack: Agent
var action_menu: ActionMenu

func _ready() -> void:
	await game_round.ready
	game_round.action_menu.on_action.connect(handle_new_action_state)
	game_round.action_menu.mouse_entered.connect(enter_hover_action_menu)
	game_round.action_menu.mouse_exited.connect(exit_hover_action_menu)
	game_round.battle_preview_menu.on_fire_clicked.connect(start_battle)

	for a in game_round.cpu_team.agents:
		var agent = a as Agent
		agent.on_agent_click.connect(handle_enemy_agent_click)
		agent.button.mouse_entered.connect(handle_enemy_agent_hover)
		agent.button.mouse_exited.connect(handle_enemy_agent_unhover)

	for a in game_round.player_team.agents:
		var agent = a as Agent
		agent.on_update_action_menu.connect(update_action_menu)

func handle_enemy_agent_click(agent):
	if curr_action_state == ActionState.PRIMARY_ATTACK or curr_action_state == ActionState.SECONDARY_ATTACK:
		if game_round.get_ap_cost_for_primary_attack() <= selected_agent.rem_action_points and has_vision_on_enemy(selected_agent, agent):
			var weapon_to_attack_with = selected_agent.primary_weapon if curr_action_state == ActionState.PRIMARY_ATTACK else selected_agent.sidearm_weapon
			var midpoint_pos = Vector2((selected_agent.global_position.x + agent.global_position.x) / 2, (selected_agent.global_position.y + agent.global_position.y) / 2)
			game_round.game_camera.target_position = midpoint_pos
			var battle_preview_menu = game_round.battle_preview_menu
			battle_preview_menu.show()
			battle_preview_menu.update_preview(selected_agent, agent, weapon_to_attack_with)
			enemy_to_attack = agent

func handle_enemy_agent_hover():
	if curr_action_state == ActionState.PRIMARY_ATTACK or curr_action_state == ActionState.SECONDARY_ATTACK:
		var ap_cost_for_attack = game_round.get_ap_cost_for_primary_attack()
		action_menu.preview_ap_cost(ap_cost_for_attack)

func handle_enemy_agent_unhover():
	if curr_action_state == ActionState.PRIMARY_ATTACK or curr_action_state == ActionState.SECONDARY_ATTACK:
		action_menu.update_all()

func exit_hover_action_menu():
	is_hovering_action_menu = false

func enter_hover_action_menu():
	is_hovering_action_menu = true

func handle_new_action_state(new_action_state):
	highlight_overlay.hide()
	game_round.battle_preview_menu.hide()
	enemy_to_attack = null
	action_menu.update_all()
	match new_action_state:
		ActionState.MOVE:
			highlight_overlay.show()
	curr_action_state = new_action_state

func _process(_delta):
	if game_round.curr_turn_side == GameRound.Side.PLAYER and !is_hovering_action_menu:
		match curr_action_state:
			ActionState.MOVE:
				var pos_to_move_to = game_round.map.get_world_pos_from_tile_pos(highlight_overlay.hovered_tile_pos)
				var ap_cost_for_move = game_round.get_ap_cost_for_movement(selected_agent.global_position, pos_to_move_to)
				var is_defusing_or_planting = selected_agent.is_defusing or selected_agent.is_planting
				highlight_overlay.is_pos_valid = ap_cost_for_move <= selected_agent.rem_action_points and !is_defusing_or_planting
				action_menu.preview_ap_cost(ap_cost_for_move)
				if Input.is_action_just_pressed("mouse_left"):
					if ap_cost_for_move <= selected_agent.rem_action_points and !is_defusing_or_planting:
						highlight_overlay.should_update_pos = false
						selected_agent.move_to_position(pos_to_move_to, complete_move)
						action_menu.update_all()
						center_camera_on_position(pos_to_move_to)
				if Input.is_action_just_pressed("center_camera"):
					center_camera_on_agent(selected_agent)

func start_turn(agent_to_select: Agent):
	agent_to_select.rem_action_points = Agent.TOTAL_ACTION_POINTS
	select_agent(agent_to_select)
	game_round.update_visible_enemies_to_player()

func complete_move():
	highlight_overlay.should_update_pos = true
	game_round.update_visible_enemies_to_player()
	action_menu.update_all()
	show_visible_tiles_for_selected_agent()

func complete_turn():
	selected_agent.rem_action_points = Agent.TOTAL_ACTION_POINTS
	selected_agent.has_completed_turn = true
	selected_agent.sprite.self_modulate = Color(0.5, 0.5, 0.5)
	if selected_agent.is_defusing:
		game_round.continue_bomb_defuse(selected_agent)
	elif selected_agent.is_planting:
		game_round.continue_bomb_plant(selected_agent)

	on_complete_turn.emit()

func select_agent(agent: Agent):
	selected_agent = agent
	center_camera_on_agent(agent)
	action_menu.update_all()
	action_menu.show()
	show_visible_tiles_for_selected_agent()

func center_camera_on_agent(agent: Agent):
	game_round.game_camera.target_position = agent.global_position

func center_camera_on_position(new_pos: Vector2):
	game_round.game_camera.target_position = new_pos

func start_battle():
	if enemy_to_attack != null:
		var weapon_to_attack_with = selected_agent.primary_weapon if curr_action_state == ActionState.PRIMARY_ATTACK else selected_agent.sidearm_weapon
		selected_agent.weapon_to_attack_with = weapon_to_attack_with
		game_round.battle_preview_menu.hide()
		selected_agent.attack_enemy_agent(enemy_to_attack, true, on_battle_complete)
		action_menu.update_all()

func on_battle_complete():
	if selected_agent.is_dead():
		complete_turn()

func update_action_menu():
	action_menu.update_all()

func has_vision_on_enemy(curr_agent, target):
	var visible_tiles = curr_agent.visible_tiles
	var enemy_tile_pos = game_round.map.get_tile_pos_from_world_pos(target.global_position)
	return visible_tiles.has(enemy_tile_pos)

func show_visible_tiles_for_selected_agent():
	selected_agent.update_visible_tiles()
	game_round.map.vision_layer.clear()
	game_round.map.show_specific_visible_tiles(selected_agent.visible_tiles)
