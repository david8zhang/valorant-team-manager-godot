class_name Team
extends Node2D

@onready var game_round = get_node("/root/GameRound") as GameRound

@export var side: GameRound.Side
@export var team_status: TeamStatus
@export var agent_scene: PackedScene
@export var num_agents = 5
@export var map: Map
@export var start_x = 0
@export var start_y = 0
@export var space_btwn_agents = 2
@export var name_prefix := ""

var agents := []

func _ready() -> void:
	var x_pos = start_x
	var y_pos = start_y
	for i in range(0, num_agents):
		var new_agent = agent_scene.instantiate() as Agent
		new_agent.map = map
		new_agent.agent_name = name_prefix + "_" + str(i)
		new_agent.curr_side = side
		add_child(new_agent)
		var outline_color = Color8(39, 239, 190) if side == GameRound.Side.PLAYER else Color.RED
		new_agent.set_outline(outline_color)
		agents.append(new_agent)
		map.move_node_to_pos(new_agent, x_pos, y_pos)
		x_pos += space_btwn_agents
	
	await game_round.ready
	team_status.update_from_team(agents)

func get_all_visible_tiles():
	var all_visible_tiles := []
	for agent in (agents as Array[Agent]):
		if !agent.is_dead():
			all_visible_tiles += agent.visible_tiles
	return all_visible_tiles

func reset_agents():
	var x_pos = start_x
	var y_pos = start_y
	for a in agents:
		var agent = a as Agent
		agent.set_curr_health(Agent.MAX_HEALTH)
		agent.rem_action_points = Agent.TOTAL_ACTION_POINTS
		agent.has_completed_turn = false
		map.move_node_to_pos(agent, x_pos, y_pos)
		x_pos += space_btwn_agents
