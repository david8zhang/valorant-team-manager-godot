extends Node

@onready var game_round = get_node("/root/GameRound") as GameRound

func create_ability(ability_stats: AbilityStats) -> Ability:
	match ability_stats.ability_type:
		AbilityStats.AbilityType.SMOKE:
			return Smoke.new(game_round, ability_stats)
		AbilityStats.AbilityType.MOLLY:
			return Molly.new(game_round, ability_stats)
	return null
