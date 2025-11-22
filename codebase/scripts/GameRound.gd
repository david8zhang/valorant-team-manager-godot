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
@onready var camera := $Camera2D as Camera2D

var curr_turn_side = Side.PLAYER

func _ready():
	agent_controller.on_complete_turn.connect(on_complete_turn)
	cpu_agent_controller.on_complete_turn.connect(on_complete_turn)

func on_complete_turn():
	if curr_turn_side == Side.PLAYER:
		curr_turn_side = Side.CPU
		cpu_agent_controller.move_agent()
	else:
		curr_turn_side = Side.PLAYER

func update_vision_for_side():
	var team_to_hide = cpu_team if curr_turn_side == Side.PLAYER else player_team
	var curr_team = player_team if curr_turn_side == Side.PLAYER else cpu_team
	update_visible_enemies(curr_team, team_to_hide)

func update_visible_enemies(curr_team: Team, team_to_hide: Team):
	var visible_tiles = curr_team.get_all_visible_tiles() as Array
	var enemy_agents = team_to_hide.agents as Array[Agent]
	for agent in enemy_agents:
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
