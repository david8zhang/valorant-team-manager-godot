class_name GameRound
extends Node2D

enum Side {
	PLAYER,
	CPU
}

@onready var agent_controller = $PlayerTeam/AgentController as AgentController
@onready var cpu_agent_controller = $CPUTeam/CPUAgentController as CPUAgentController
@onready var player_team = $PlayerTeam as Team
@onready var cpu_team = $CPUTeam as Team
@onready var map = $Map as Map
@onready var game_camera := $GameCamera as GameCamera
@onready var action_menu := $CanvasLayer/Control/ActionMenu as ActionMenu
@onready var battle_preview_menu := $CanvasLayer/Control/BattlePreview as BattlePreview

static var AP_COST_MOVE_PER_SQUARE = 0.1
static var AP_COST_PRIMARY_ATTACK = 1

var curr_turn_side = Side.PLAYER

func _ready():
	action_menu.agent_controller = agent_controller
	agent_controller.action_menu = action_menu
	agent_controller.on_complete_turn.connect(on_complete_turn)
	cpu_agent_controller.on_complete_turn.connect(on_complete_turn)
	agent_controller.start_turn()
	for a in player_team.agents:
		a.update_visible_tiles()
	map.show_player_team_visible_tiles()

func on_complete_turn():
	if curr_turn_side == Side.PLAYER:
		curr_turn_side = Side.CPU
		cpu_agent_controller.start_turn()
	else:
		curr_turn_side = Side.PLAYER
		agent_controller.start_turn()

func update_visible_enemies():
	var visible_tiles = player_team.get_all_visible_tiles() as Array
	var enemy_agents = cpu_team.agents as Array[Agent]
	update_specific_visible_enemies(visible_tiles, enemy_agents)

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
