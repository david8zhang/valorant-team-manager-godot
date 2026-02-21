class_name Ability
extends Node

var game_round: GameRound
var ability_stats: AbilityStats
var source_agent: Agent

func _init(_game_round: GameRound, _ability_stats: AbilityStats):
	game_round = _game_round
	ability_stats = _ability_stats

func handle_hover(_x_pos: int, _y_pos: int):
	pass

func handle_click(_x_pos: int, _y_pos: int):
	pass

func is_valid_target(_target_agent: Agent) -> bool:
	return true

func execute():
	pass

func deselect():
	pass