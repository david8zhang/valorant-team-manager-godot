class_name GameRound
extends Node2D

@export var agent_scene: PackedScene
@onready var map = $Map as Map
@onready var highlight_overlay = $HighlightOverlay as HighlightOverlay

var selected_agent: Agent

func _ready():
	var new_agent = agent_scene.instantiate() as Agent
	add_child(new_agent)
	map.move_node_to_pos(new_agent, 10, 11)
	selected_agent = new_agent

func _process(_delta):
	if Input.is_action_just_pressed("mouse_left"):
		var pos_to_move_to = map.ground_layer.map_to_local(highlight_overlay.hovered_tile_pos)
		selected_agent.move_to_position(pos_to_move_to)
