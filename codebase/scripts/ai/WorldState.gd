class_name WorldState
extends Node

var last_known_player_agent_pos_map := {}
var strategy: TeamStrategy

func report_player_agent(agent_name: String, tile_pos: Vector2):
	last_known_player_agent_pos_map[agent_name] = tile_pos

func get_closest_known_enemy(curr_tile_pos: Vector2):
	pass
