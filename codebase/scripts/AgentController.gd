class_name AgentController
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound
@export var highlight_overlay: HighlightOverlay
@export var team: Team

enum ActionState {
	NONE,
	WATCH,
	STOP_WATCH,
	DEFUSE,
	PLANT,
	MOVE,
	PRIMARY_ATTACK,
	SECONDARY_ATTACK,
	ABILITY_ONE,
	ABILITY_TWO
}

signal on_complete_turn
signal on_complete_move

var selected_agent: Agent
var curr_action_state: ActionState = ActionState.NONE
var is_hovering_action_menu := false
var enemy_to_attack: Agent
var action_menu: ActionMenu
var cached_top_view_state: GameRound.TopViewState

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
	# Handle old action state
	match curr_action_state:
		ActionState.ABILITY_ONE, ActionState.ABILITY_TWO:
			var ability_to_process = selected_agent.ability_1 if curr_action_state == ActionState.ABILITY_ONE else selected_agent.ability_2
			ability_to_process.deselect()
	# Handle new action state
	match new_action_state:
		ActionState.STOP_WATCH:
			action_menu.stop_watching_button.hide()
			selected_agent.stop_watching_position()
		ActionState.MOVE, ActionState.WATCH:
			highlight_overlay.show()
	curr_action_state = new_action_state

func _process(_delta):
	if game_round.curr_turn_side == GameRound.Side.PLAYER and !is_hovering_action_menu and game_round.is_round_underway():
		var is_defusing_or_planting = selected_agent.is_defusing or selected_agent.is_planting
		match curr_action_state:
			ActionState.MOVE:
				var pos_to_move_to = game_round.map.get_world_pos_from_tile_pos(highlight_overlay.hovered_tile_pos)
				var ap_cost_for_move = game_round.get_ap_cost_for_movement(selected_agent.global_position, pos_to_move_to)
				highlight_overlay.is_pos_valid = ap_cost_for_move <= selected_agent.rem_action_points and !is_defusing_or_planting and game_round.can_move_to_pos(selected_agent.global_position, pos_to_move_to)
				action_menu.preview_ap_cost(ap_cost_for_move)
				if Input.is_action_just_pressed("mouse_left"):
					if highlight_overlay.is_pos_valid:
						highlight_overlay.should_update_pos = false
						action_menu.can_go_to_next_turn = false
						selected_agent.move_to_position(pos_to_move_to, complete_move)
						action_menu.update_all()
						center_camera_on_position(pos_to_move_to)
				if Input.is_action_just_pressed("center_camera"):
					center_camera_on_agent(selected_agent)
			ActionState.ABILITY_ONE, ActionState.ABILITY_TWO:
				var ability_to_process = selected_agent.ability_1 if curr_action_state == ActionState.ABILITY_ONE else selected_agent.ability_2
				var map = game_round.map
				var mouse_world_pos = get_global_mouse_position()
				var hovered_tile_pos = map.ground_layer.local_to_map(game_round.to_local(mouse_world_pos))
				ability_to_process.handle_hover(hovered_tile_pos.x, hovered_tile_pos.y)
				var ap_cost_for_ability = ability_to_process.ability_stats.ap_cost
				action_menu.preview_ap_cost(ap_cost_for_ability)
				if Input.is_action_just_pressed("mouse_left"):
					if ap_cost_for_ability <= selected_agent.rem_action_points and !is_defusing_or_planting:
						selected_agent.rem_action_points -= ap_cost_for_ability
						action_menu.update_all()
						ability_to_process.handle_click(hovered_tile_pos.x, hovered_tile_pos.y)
			ActionState.WATCH:
				highlight_overlay.is_pos_valid = true
				if Input.is_action_just_pressed("mouse_left"):
					var pos_to_watch = game_round.map.get_world_pos_from_tile_pos(highlight_overlay.hovered_tile_pos)
					selected_agent.watch_position(pos_to_watch)
					action_menu.stop_watching_button.show()

func start_turn(agent_to_select: Agent):
	agent_to_select.rem_action_points = Agent.TOTAL_ACTION_POINTS
	select_agent(agent_to_select)
	game_round.update_visible_enemies_to_player()

func complete_move():
	action_menu.can_go_to_next_turn = true
	highlight_overlay.should_update_pos = true
	action_menu.update_all()
	show_visible_tiles_for_selected_agent()
	game_round.update_visible_enemies_to_player()
	on_complete_move.emit()

func complete_turn():
	selected_agent.ability_1.deselect()
	selected_agent.ability_2.deselect()
	selected_agent.rem_action_points = Agent.TOTAL_ACTION_POINTS
	selected_agent.has_completed_turn = true
	selected_agent.sprite.self_modulate = Color(0.5, 0.5, 0.5)
	if selected_agent.is_defusing:
		game_round.continue_bomb_defuse(selected_agent)
	elif selected_agent.is_planting:
		game_round.continue_bomb_plant(selected_agent)
	selected_agent.update_tiles_in_view()
	on_complete_turn.emit()
	curr_action_state = ActionState.NONE
	highlight_overlay.hide()
	action_menu.de_highlight_all_buttons()

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
		cached_top_view_state = game_round.top_view_state
		game_round.set_top_view_state(GameRound.TopViewState.HIDDEN)
		game_round.battle_preview_menu.hide()		
		var weapon_to_attack_with = selected_agent.primary_weapon if curr_action_state == ActionState.PRIMARY_ATTACK else selected_agent.sidearm_weapon
		selected_agent.weapon_to_attack_with = weapon_to_attack_with
		action_menu.can_go_to_next_turn = false
		selected_agent.attack_enemy_agent(enemy_to_attack, true, on_battle_complete)
		action_menu.update_all()

func on_battle_complete():
	game_round.set_top_view_state(cached_top_view_state)
	if selected_agent.is_dead():
		complete_turn()
	action_menu.can_go_to_next_turn = true

func update_action_menu():
	if selected_agent != null:
		action_menu.update_all()

func has_vision_on_enemy(curr_agent, target):
	var visible_tiles = curr_agent.visible_tiles
	var enemy_tile_pos = game_round.map.get_tile_pos_from_world_pos(target.global_position)
	return visible_tiles.has(enemy_tile_pos)

func show_visible_tiles_for_selected_agent():
	selected_agent.update_tiles_in_view()
	game_round.map.show_specific_visible_tiles(selected_agent.visible_tiles)
