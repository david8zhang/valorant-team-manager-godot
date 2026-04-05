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

static var PLAYER_SPAWN_ATLAS = Vector2(14, 2)
static var CPU_SPAWN_ATLAS = Vector2(13, 2)

# Start with 800 credits per agent (800 x 5)
var num_credits := 4000
var agents := []

func _ready() -> void:
	var spawn_positions = get_all_spawn_positions()
	var i = 0
	for cell in spawn_positions:
		var new_agent = agent_scene.instantiate() as Agent
		new_agent.map = map
		new_agent.agent_name = name_prefix + "_" + str(i)
		new_agent.curr_side = side
		new_agent.agent_stats = GameRoundVariables.load_random_agent_stat()
		add_child(new_agent)
		var outline_color = GameRoundVariables.PLAYER_OUTLINE_COLOR if side == GameRound.Side.PLAYER else GameRoundVariables.CPU_OUTLINE_COLOR
		new_agent.set_outline(outline_color)
		agents.append(new_agent)
		map.move_node_to_pos(new_agent, cell.x, cell.y)
		i += 1
	await game_round.ready
	team_status.update_from_team(agents)

func get_all_spawn_positions():
	var spawn_layer = map.spawn_layer
	var used_cells = spawn_layer.get_used_cells()
	var spawn_positions = []
	for cell in used_cells:
		var atlas_coords = spawn_layer.get_cell_atlas_coords(cell)
		var spawn_atlas_for_side = PLAYER_SPAWN_ATLAS if side == GameRound.Side.PLAYER else CPU_SPAWN_ATLAS
		if atlas_coords.x == spawn_atlas_for_side.x and atlas_coords.y == spawn_atlas_for_side.y:
			spawn_positions.append(cell)
	return spawn_positions

func get_all_visible_tiles():
	var all_visible_tiles := []
	for agent in (agents as Array[Agent]):
		if !agent.is_dead():
			all_visible_tiles += agent.visible_tiles
	return all_visible_tiles

func reset_agents():
	var spawn_positions = get_all_spawn_positions()
	for i in range(0, spawn_positions.size()):
		var spawn_pos = spawn_positions[i]
		var agent = agents[i] as Agent
		agent.reset()
		map.move_node_to_pos(agent, spawn_pos.x, spawn_pos.y)

func get_all_living_agents():
	return agents.filter(func (a): return !a.is_dead())
