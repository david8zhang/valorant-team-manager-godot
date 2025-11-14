class_name AgentController
extends Node2D

@export var map: Map
@export var highlight_overlay: HighlightOverlay
@export var team: Team

func _process(_delta):
	if Input.is_action_just_pressed("mouse_left"):
		var pos_to_move_to = map.ground_layer.map_to_local(highlight_overlay.hovered_tile_pos)
		team.selected_agent.move_to_position(pos_to_move_to)
