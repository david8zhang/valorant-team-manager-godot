class_name Ability
extends Node

var ability_stats: AbilityStats
var source_agent: Agent

func handle_hover(_x_pos: int, _y_pos: int):
	pass

func handle_click(_x_pos: int, _y_pos: int):
	pass

func is_valid_target(_target_agent: Agent) -> bool:
	return true

func execute():
	pass