extends Node

@onready var game_round = get_node("/root/GameRound") as GameRound

func create_ability(ability_stats: AbilityStats) -> Ability:
	match ability_stats.ability_type:
		AbilityStats.AbilityType.SMOKE:
			return Smoke.new(game_round, ability_stats)
		AbilityStats.AbilityType.STIM:
			return Stim.new(game_round, ability_stats)
		AbilityStats.AbilityType.DRONE:
			return Drone.new(game_round, ability_stats)
		AbilityStats.AbilityType.RECON_DART:
			return ReconDart.new(game_round, ability_stats)
		AbilityStats.AbilityType.FLASH:
			return Flash.new(game_round, ability_stats)
		AbilityStats.AbilityType.MOLLY:
			return Molly.new(game_round, ability_stats)
		AbilityStats.AbilityType.HEAL:
			return Heal.new(game_round, ability_stats)
		AbilityStats.AbilityType.WALL:
			return Wall.new(game_round, ability_stats)
	return null
