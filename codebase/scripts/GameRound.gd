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
@onready var round_result = $CanvasLayer/Control/RoundResult as RoundResult
@onready var buy_menu = $CanvasLayer/Control/BuyMenu as BuyMenu
@onready var player_team_status = $CanvasLayer/Control/PlayerTeamStatus as TeamStatus
@onready var cpu_team_status = $CanvasLayer/Control/CPUTeamStatus as TeamStatus
@onready var util_below_player = $UtilBelowPlayer as Node2D
@onready var util_above_player = $UtilAbovePlayer as Node2D
@onready var pathfinding = $Pathfinding as Pathfinding
@onready var debug_menu = $CanvasLayer/Control/DebugMenu as DebugMenu

@export var bomb_scene: PackedScene

var turn_queue = []
var curr_turn_index = 0

static var AP_COST_MOVE_PER_SQUARE = 0.1
static var AP_COST_PRIMARY_ATTACK = 1
static var BOMB_TILE_ATLAS_COORDS = Vector2(0, 11)

var curr_turn_side = Side.PLAYER
var attack_side = Side.PLAYER
var is_showing_scoreboard := true
var top_view_state := TopViewState.SCOREBOARD
var bomb: Bomb
var smokes_on_field := []
var molly_on_field := []
var is_round_over := false

func _ready():
	round_result.on_continue.connect(incr_score_and_go_to_buy_phase)
	action_menu.agent_controller = agent_controller
	agent_controller.action_menu = action_menu
	agent_controller.on_complete_turn.connect(go_to_next_turn)
	cpu_agent_controller.on_complete_turn.connect(go_to_next_turn)
	for a in player_team.agents:
		var agent = a as Agent
		agent.update_tiles_in_view()

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
	cpu_agent_controller.select_round_strategy()
	start_turn_for_next_agent()
	set_top_view_state(top_view_state)

	# Test bomb defusal logic
	# attack_side = Side.CPU
	# scoreboard.switch_to_phase(Scoreboard.Phase.POST_PLANT)
	# bomb.set_bomb_state(Bomb.BombState.PLANTED)
	# var plant_tile_pos = Vector2(22, 26)
	# var plant_global_pos = map.get_world_pos_from_tile_pos(plant_tile_pos)
	# bomb.global_position = Vector2(plant_global_pos.x, plant_global_pos.y)

func place_bomb():
	if bomb == null:
		bomb = bomb_scene.instantiate() as Bomb
		add_child(bomb)
	var non_empty_tiles = map.spawn_layer.get_used_cells()
	for c in non_empty_tiles:
		var atlas_coords = map.spawn_layer.get_cell_atlas_coords(c)
		if atlas_coords.x == BOMB_TILE_ATLAS_COORDS.x and atlas_coords.y == BOMB_TILE_ATLAS_COORDS.y:
			bomb.global_position = map.get_world_pos_from_tile_pos(c)

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
		curr_turn_side = next_agent_in_turn_queue.curr_side
		if next_agent_in_turn_queue.curr_side == Side.PLAYER:
			action_menu.show_for_agent(next_agent_in_turn_queue)
			agent_controller.start_turn(next_agent_in_turn_queue)
		else:
			action_menu.hide()
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
		go_to_next_turn_cycle()
	if !is_round_over:
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
	cpu_agent_controller.select_round_strategy()
	if scoreboard.curr_phase == Scoreboard.Phase.SETUP:
		# Handle setup phase end
		if scoreboard.turns_remaining == 0:
			scoreboard.switch_to_phase(Scoreboard.Phase.PRE_PLANT)
			map.temp_barrier_layer.hide()
			pathfinding.setup_solid_tiles()
		else:
			reset_all_agents_for_turn()			
	else:
		handle_smoke_timers()
		var win_condition = get_win_condition()
		if win_condition != -1:
			handle_win_condition(win_condition)
			is_round_over = true
		else:
			reset_all_agents_for_turn()

func reset_all_agents_for_turn():
	var all_agents = player_team.agents + cpu_team.agents
	for a in all_agents:
		var agent = a as Agent
		agent.has_completed_turn = false
	for a in player_team.agents:
		var agent = a as Agent
		agent.sprite.self_modulate = Color(1, 1, 1)

func handle_win_condition(win_condition):
	var winning_side: GameRound.Side
	match win_condition:
		RoundResult.WinCondition.TIME:
			winning_side = Side.PLAYER if attack_side == Side.CPU else Side.CPU
		RoundResult.WinCondition.ELIMINATION:
			winning_side = Side.PLAYER if all_cpu_agents_eliminated() else Side.CPU
		RoundResult.WinCondition.DETONATION:
			winning_side = Side.PLAYER if attack_side == Side.PLAYER else Side.CPU
		RoundResult.WinCondition.DEFUSE:
			winning_side = Side.PLAYER if attack_side == Side.CPU else Side.PLAYER
	round_result.show_winning_side(winning_side, win_condition)

func update_visible_enemies_to_specific_agent(specific_agent: Agent):
	# Only show visible enemies for selected agent, otherwise, just show them as gray blobs
	var visible_tiles_for_selected_agent = specific_agent.visible_tiles
	var other_visible_tiles = player_team.get_all_visible_tiles().filter(func (p): return !visible_tiles_for_selected_agent.has(p))
	var enemy_agents = cpu_team.agents as Array[Agent]
	for agent in enemy_agents:
		if debug_menu.show_all_agents:
			agent.show_fully()
		else:
			if !agent.is_dead():
				var tile_pos = map.get_tile_pos_from_world_pos(agent.global_position)
				if visible_tiles_for_selected_agent.has(tile_pos):
					agent.show_fully()
				else:
					if other_visible_tiles.has(tile_pos):
						agent.hide_in_fog_of_war()
					else:
						agent.hide_fully()

func update_visible_enemies_to_player():
	if agent_controller.selected_agent != null:
		update_visible_enemies_to_specific_agent(agent_controller.selected_agent)

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
	var path = pathfinding.get_shortest_path(start_tile_pos, end_tile_pos)
	print(path.size())
	return max(1, round(path.size() * AP_COST_MOVE_PER_SQUARE))
	
func get_ap_cost_for_primary_attack():
	return AP_COST_PRIMARY_ATTACK

func get_win_condition():
	if is_defuse():
		return RoundResult.WinCondition.DEFUSE
	if is_timeout():
		if bomb.curr_bomb_state == Bomb.BombState.PLANTED or bomb.curr_bomb_state == Bomb.BombState.DEFUSING:
			return RoundResult.WinCondition.DETONATION
		return RoundResult.WinCondition.TIME
	if all_cpu_agents_eliminated() or all_player_agents_eliminated():
		return RoundResult.WinCondition.ELIMINATION
	return -1

func is_defuse():
	return scoreboard.defuse_progress == Scoreboard.DEFUSE_REQ_TURNS

func is_timeout():
	return scoreboard.turns_remaining == 0

func all_cpu_agents_eliminated():
	var living_cpu_agents = cpu_team.agents.filter(func (a: Agent): return !a.is_dead())
	return living_cpu_agents.size() == 0

func all_player_agents_eliminated():
	var living_player_agents = player_team.agents.filter(func (a: Agent): return !a.is_dead())
	return living_player_agents.size() == 0

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

func set_top_view_state(new_state: TopViewState):
	match new_state:
		TopViewState.SCOREBOARD:
			toggle_top_view_button.text = "Show Turn Order"
			turn_order_list_view.hide()
			scoreboard.show()
		TopViewState.TURN_QUEUE:
			toggle_top_view_button.text = "Hide"
			turn_order_list_view.show()
			scoreboard.hide()
		TopViewState.HIDDEN:
			toggle_top_view_button.text = "Show Scoreboard"
			scoreboard.hide()
			turn_order_list_view.hide()
	top_view_state = new_state

func toggle_top_view():
	match top_view_state:
		TopViewState.SCOREBOARD:
			set_top_view_state(TopViewState.TURN_QUEUE)
		TopViewState.TURN_QUEUE:
			set_top_view_state(TopViewState.HIDDEN)
		TopViewState.HIDDEN:
			set_top_view_state(TopViewState.SCOREBOARD)

func get_turn_queue_agents():
	return turn_queue.map(func (agent_name): return get_agent_for_name(agent_name))

func start_plant_bomb(planter: Agent):
	planter.rem_action_points = 0
	action_menu.update_all()
	if planter.curr_side == Side.PLAYER:
		agent_controller.complete_turn()
	scoreboard.plant_container.show()
	scoreboard.incr_defuse_container()
	planter.is_planting = true

func continue_bomb_plant(planter: Agent):
	planter.rem_action_points = 0
	action_menu.update_all()
	scoreboard.incr_plant_container()
	if scoreboard.plant_progress == Scoreboard.PLANT_REQ_TURNS:
		planter.has_bomb = false
		planter.is_planting = false
		planter.did_plant_this_round = true
		var plant_pos = planter.global_position
		bomb.global_position = Vector2(plant_pos.x, plant_pos.y)
		bomb.show()
		bomb.set_bomb_state(Bomb.BombState.PLANTED)
		scoreboard.plant_container.hide()
		scoreboard.switch_to_phase(Scoreboard.Phase.POST_PLANT)

func stop_plant_bomb(planter: Agent):
	planter.is_planting = false
	action_menu.update_all()
	scoreboard.reset_plant_container()

func start_defuse_bomb(defuser: Agent):
	defuser.rem_action_points = 0
	action_menu.update_all()
	bomb.set_bomb_state(Bomb.BombState.DEFUSING)
	if defuser.curr_side == Side.PLAYER:
		agent_controller.complete_turn()
	scoreboard.defuse_container.show()
	scoreboard.incr_defuse_container()
	defuser.is_defusing = true

func continue_bomb_defuse(defuser: Agent):
	defuser.rem_action_points = 0
	action_menu.update_all()
	scoreboard.incr_defuse_container()
	if scoreboard.defuse_progress == Scoreboard.DEFUSE_REQ_TURNS:
		defuser.did_defuse_this_round = true

func stop_defuse_bomb(defuser: Agent):
	defuser.is_defusing = false
	action_menu.update_all()
	bomb.set_bomb_state(Bomb.BombState.PLANTED)
	scoreboard.reset_defuse_container()

func incr_score_and_go_to_buy_phase(last_winning_side: GameRound.Side):
	scoreboard.incr_score(last_winning_side)
	scoreboard.incr_round()
	curr_turn_index = 0
	scoreboard.reset()
	for a in player_team.agents:
		var agent = a as Agent
		agent.update_tiles_in_view()
		agent.show()
	place_bomb()
	bomb.set_bomb_state(Bomb.BombState.DROPPED)
	scoreboard.switch_to_phase(Scoreboard.Phase.BUY)
	setup_player_buy_menu(last_winning_side)

func setup_player_buy_menu(last_winning_side: GameRound.Side):
	toggle_top_view_button.hide()
	buy_menu.show()
	buy_menu.init_agent_info(player_team.agents)
	buy_menu.setup_credits(player_team.agents, last_winning_side)
	player_team_status.hide()
	cpu_team_status.hide()
	action_menu.hide()

func on_buy_finished():
	is_round_over = false
	player_team.reset_agents()
	cpu_team.reset_agents()
	map.temp_barrier_layer.show()
	pathfinding.setup_solid_tiles()	
	scoreboard.switch_to_phase(Scoreboard.Phase.SETUP)
	buy_menu.hide()
	player_team_status.update_from_team(player_team.agents)
	cpu_team_status.update_from_team(cpu_team.agents)
	player_team_status.show()
	cpu_team_status.show()
	action_menu.show()
	curr_turn_index = 0
	start_turn_for_next_agent()

func is_tile_smoked(point: Vector2i):
	for s in smokes_on_field:
		var smoke = s as Smoke.InGameSmoke
		if smoke.is_position_smoked(point):
			return true
	return false

func handle_smoke_timers():
	for s in smokes_on_field:
		var smoke = s as Smoke.InGameSmoke
		smoke.turns_to_live -= 1
		if smoke.turns_to_live == 0:
			smoke.dissipate()
	smokes_on_field = smokes_on_field.filter(func (smoke): return smoke.turns_to_live > 0)
	for a in player_team.agents:
		var agent = a as Agent
		agent.update_tiles_in_view()

func is_round_underway():
	var curr_phase = scoreboard.curr_phase
	var valid_phases = [Scoreboard.Phase.PRE_PLANT, Scoreboard.Phase.POST_PLANT, Scoreboard.Phase.SETUP]
	return valid_phases.has(curr_phase)

func can_move_to_pos(curr_world_pos, new_world_pos: Vector2):
	var new_tile_pos = map.get_tile_pos_from_world_pos(new_world_pos)
	var curr_tile_pos = map.get_tile_pos_from_world_pos(curr_world_pos)
	var has_path_to_pos = pathfinding.get_shortest_path(curr_tile_pos, new_tile_pos).size() > 0
	return has_path_to_pos and map.is_tile_pos_in_bounds(new_tile_pos) and !map.is_tile_pos_obstructed(new_tile_pos) and !is_position_occupied(new_tile_pos)

func add_util_above_player(util: Node):
	util_above_player.add_child(util)

func add_util_below_player(util: Node):
	util_below_player.add_child(util)

func get_enemy_holding_agent(agent: Agent, world_pos: Vector2):
	var tile_pos = map.get_tile_pos_from_world_pos(world_pos)
	var enemy_agents = cpu_team.get_all_living_agents() if agent.curr_side == Side.PLAYER else player_team.get_all_living_agents()
	for a in enemy_agents:
		var enemy_agent = a as Agent
		for ht in enemy_agent.holding_tiles:
			var ht_tile_pos = map.get_tile_pos_from_world_pos(ht.global_position)
			if ht_tile_pos.x == tile_pos.x and ht_tile_pos.y == tile_pos.y:
				return enemy_agent
	return null
