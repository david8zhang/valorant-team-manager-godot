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

var curr_turn_side = Side.PLAYER

func _ready():
	agent_controller.on_complete_turn.connect(on_complete_turn)
	cpu_agent_controller.on_complete_turn.connect(on_complete_turn)
	agent_controller.start_turn()
	game_camera.on_zoom.connect(scale_from_zoom)

func scale_from_zoom(curr_zoom):
	scale_agents(player_team.agents, curr_zoom)
	scale_agents(cpu_team.agents, curr_zoom)

func scale_agents(agents, curr_zoom):
	for a in agents:
		var agent = a as Agent
		var scale_x = max(Agent.DEFAULT_SCALE, Agent.DEFAULT_SCALE / curr_zoom.x)
		var scale_y = max(Agent.DEFAULT_SCALE, Agent.DEFAULT_SCALE / curr_zoom.y)
		agent.sprite.scale = Vector2(scale_x, scale_y)

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
