class_name GameRound
extends Node2D

@export var agent_scene: PackedScene
@onready var map = $Map as Map

var hovered_tile_pos: Vector2

func _ready():
	var new_agent = agent_scene.instantiate() as Agent
	add_child(new_agent)
	map.move_node_to_pos(new_agent, 10, 11)
