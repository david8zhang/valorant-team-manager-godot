class_name GameRound
extends Node2D

enum Side {
	PLAYER,
	CPU
}

enum TopViewState {
	SCOREBOARD,
	TURN_QUEUE,
	HIDDEN
}

@onready var agent_controller = $PlayerTeam/AgentController as AgentController
@onready var cpu_agent_controller = $CPUTeam/CPUAgentController as CPUAgentController
@onready var player_team = $PlayerTeam as Team
@onready var cpu_team = $CPUTeam as Team
@onready var map = $Map as Map
@onready var game_camera := $GameCamera as GameCamera
@onready var action_menu := $CanvasLayer/Control/ActionMenu as ActionMenu
@onready var battle_preview_menu := $CanvasLayer/Control/BattlePreview as BattlePreview
@onready var scoreboard := $CanvasLayer/Control/Scoreboard as Scoreboard
@onready var canvas_control := $CanvasLayer/Control as Control
@onready var turn_order_list_view := $CanvasLayer/Control/TurnOrder as TurnOrder
@onready var toggle_top_view_button := $CanvasLayer/Control/ToggleTopView as Button

@export var bomb_scene: PackedScene

var turn_queue = []
var curr_turn_index = 0

static var AP_COST_MOVE_PER_SQUARE = 0.1
static var AP_COST_PRIMARY_ATTACK = 1
static var BOMB_SPAWN_TILE_COORD = Vector2(60, 70)

var curr_turn_side = Side.PLAYER
var attack_side = Side.PLAYER
var is_showing_scoreboard := true
var top_view_state := TopViewState.SCOREBOARD
var bomb: Bomb

func _ready():
	action_menu.agent_controller = agent_controller
	agent_controller.action_menu = action_menu
	agent_controller.on_complete_turn.connect(go_to_next_turn)
	cpu_agent_controller.on_complete_turn.connect(go_to_next_turn)
	for a in player_team.agents:
		a.update_visible_tiles()

	var all_agents = player_team.agents + cpu_team.agents
	for a in all_agents:
		var agent = a as Agent
		agent.on_take_damage.connect(update_team_statuses)
		agent.on_kill.connect(update_team_statuses)
		agent.on_death.connect(update_team_statuses)

	place_bomb()
	create_turn_queue(all_agents)
	toggle_top_view_button.pressed.connect(toggle_top_view)
	setup_game_round_variables()
	start_turn_for_next_agent()

func place_bomb():
	bomb = bomb_scene.instantiate() as Bomb
	add_child(bomb)
	bomb.global_position = map.get_world_pos_from_tile_pos(BOMB_SPAWN_TILE_COORD)

func setup_game_round_variables():
	if GameRoundVariables.agent_game_stat_mapping.is_empty():
		var all_agents = player_team.agents + cpu_team.agents
		for a in all_agents:
			var agent = a as Agent
			var agent_game_stats = GameRoundVariables.AgentGameStats.new()
			agent.init_from_game_stats(agent_game_stats)
			GameRoundVariables.agent_game_stat_mapping[agent.agent_name] = agent_game_stats

func update_team_statuses():
	player_team.team_status.update_from_team(player_team.agents)
	cpu_team.team_status.update_from_team(cpu_team.agents)

func start_turn_for_next_agent():
	var next_agent_in_turn_queue = get_agent_for_name(turn_queue[curr_turn_index])
	turn_order_list_view.update_turn_order_list(get_turn_queue_agents(), next_agent_in_turn_queue)
	if next_agent_in_turn_queue != null:
		if next_agent_in_turn_queue.curr_side == Side.PLAYER:
			agent_controller.start_turn(next_agent_in_turn_queue)
		else:
			cpu_agent_controller.start_turn(next_agent_in_turn_queue)


func go_to_next_turn():
	for i in range(curr_turn_index + 1, curr_turn_index + 1 + turn_queue.size()):
		var index = i % turn_queue.size()
		var agent = get_agent_for_name(turn_queue[index])
		if agent != null and !agent.is_dead():
			curr_turn_index = index
			break
	# Check if all agents have completed their turns
	if have_all_agents_completed_turn():
		if is_round_over():
			return
		go_to_next_turn_cycle()
	start_turn_for_next_agent()


func have_all_agents_completed_turn():
	var all_agents = player_team.agents + cpu_team.agents
	for a in all_agents:
		var agent = a as Agent
		if !agent.is_dead() and !agent.has_completed_turn:
			return false
	return true

func go_to_next_turn_cycle():
	scoreboard.decrement_turn()
	var all_agents = player_team.agents + cpu_team.agents
	for a in all_agents:
		var agent = a as Agent
		agent.has_completed_turn = false
	for a in player_team.agents:
		var agent = a as Agent
		agent.sprite.self_modulate = Color(1, 1, 1)

func update_visible_enemies_to_player():
	# Only show visible enemies for selected agent, otherwise, just show them as gray blobs
	var selected_agent = agent_controller.selected_agent as Agent
	if selected_agent != null:
		var visible_tiles_for_selected_agent = selected_agent.visible_tiles
		var other_visible_tiles = player_team.get_all_visible_tiles().filter(func (p): return !visible_tiles_for_selected_agent.has(p))
		var enemy_agents = cpu_team.agents as Array[Agent]

		for agent in enemy_agents:
			if !agent.is_dead():
				var tile_pos = map.get_tile_pos_from_world_pos(agent.global_position)
				if visible_tiles_for_selected_agent.has(tile_pos):
					agent.show_fully()
				else:
					if other_visible_tiles.has(tile_pos):
						agent.hide_in_fog_of_war()
					else:
						agent.hide_fully()

func update_specific_visible_enemies(visible_tiles, enemy_agents):
	for agent in enemy_agents:
		if !agent.is_dead():
			var tile_pos = map.get_tile_pos_from_world_pos(agent.global_position)
			if visible_tiles.has(tile_pos):
				agent.show()
			else:
				agent.hide()

func is_position_occupied(tile_pos: Vector2):
	var all_agents = cpu_team.agents + player_team.agents
	for agent in all_agents:
		# Get agent position in tilemap coordinates
		var curr_agent_pos = map.get_tile_pos_from_world_pos(agent.global_position)
		if curr_agent_pos.x == tile_pos.x and curr_agent_pos.y == tile_pos.y:
			return true
	return false

func get_ap_cost_for_movement(start: Vector2, end: Vector2):
	var start_tile_pos = map.get_tile_pos_from_world_pos(start)
	var end_tile_pos = map.get_tile_pos_from_world_pos(end)
	var manhattan_dist = abs(start_tile_pos.x - end_tile_pos.x) + abs(start_tile_pos.y - end_tile_pos.y)
	return max(1, round(manhattan_dist * AP_COST_MOVE_PER_SQUARE))
	
func get_ap_cost_for_primary_attack():
	return AP_COST_PRIMARY_ATTACK

func is_round_over():
	return scoreboard.turns_remaining == 0

func add_canvas_item(item: Control):
	canvas_control.add_child(item)

func create_turn_queue(all_agents: Array):
	all_agents.sort_custom(func (a: Agent, b: Agent): return b.confidence_level < a.confidence_level)
	turn_queue = all_agents.map(func (a: Agent): return a.agent_name)
	turn_order_list_view.init_turn_order_list(all_agents)

func get_agent_for_name(agent_name: String):
	var all_agents = cpu_team.agents + player_team.agents
	for a in all_agents:
		var agent = a as Agent
		if agent.agent_name == agent_name:
			return agent
	return null

func toggle_top_view():
	match top_view_state:
		TopViewState.SCOREBOARD:
			toggle_top_view_button.text = "Hide Top View"
			scoreboard.hide()
			turn_order_list_view.show()
			top_view_state = TopViewState.TURN_QUEUE
		TopViewState.TURN_QUEUE:
			toggle_top_view_button.text = "Show Scoreboard"
			turn_order_list_view.hide()
			top_view_state = TopViewState.HIDDEN
		TopViewState.HIDDEN:
			toggle_top_view_button.text = "Show Turn Order"
			scoreboard.show()
			top_view_state = TopViewState.SCOREBOARD

func get_turn_queue_agents():
	return turn_queue.map(func (agent_name): return get_agent_for_name(agent_name))

func plant_bomb(planter: Agent, plant_pos: Vector2):
	planter.rem_action_points = 0
	planter.has_bomb = false
	action_menu.update_all()
	bomb.global_position = Vector2(plant_pos.x, plant_pos.y)
	bomb.show()
	bomb.set_bomb_state(Bomb.BombState.PLANTED)
	scoreboard.on_bomb_planted()