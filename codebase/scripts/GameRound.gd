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

var curr_turn_side = Side.PLAYER

func _ready():
	agent_controller.on_complete_turn.connect(on_complete_turn)
	cpu_agent_controller.on_complete_turn.connect(on_complete_turn)

func on_complete_turn():
	pass
	# if curr_turn_side == Side.PLAYER:
	# 	curr_turn_side = Side.CPU
	# 	cpu_agent_controller.move_agent()
	# else:
	# 	curr_turn_side = Side.PLAYER

func is_position_occupied(tile_pos: Vector2):
	var all_agents = cpu_team.agents + player_team.agents
	for agent in all_agents:
		# Get agent position in tilemap coordinates
		var curr_agent_pos = map.get_tile_pos_from_world_pos(agent.global_position)
		if curr_agent_pos.x == tile_pos.x and curr_agent_pos.y == tile_pos.y:
			return true
	return false