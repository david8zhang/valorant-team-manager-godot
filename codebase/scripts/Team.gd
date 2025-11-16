class_name Team
extends Node2D

@export var agent_scene: PackedScene
@export var num_agents = 5
@export var map: Map
@export var start_x = 0
@export var start_y = 0

var agents = []

func _ready() -> void:
	var x_pos = start_x
	var y_pos = start_y
	for i in range(0, num_agents):
		var new_agent = agent_scene.instantiate() as Agent
		add_child(new_agent)
		agents.append(new_agent)
		map.move_node_to_pos(new_agent, x_pos, y_pos)
		x_pos += 2