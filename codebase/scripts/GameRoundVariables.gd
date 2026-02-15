extends Node

# Store agent stats between rounds
class AgentGameStats:
	var kill_count := 0
	var death_count := 0
	var assist_count := 0
	var credits := 0
	var primary_weapon_name := WeaponStats.WeaponNames.NO_WEAPON
	var sidearm_weapon_name := WeaponStats.WeaponNames.CLASSIC

	func _init() -> void:
			pass

# Class for storing round results
class RoundResultRecord:
	var winning_side: GameRound.Side
	var win_condition: RoundResult.WinCondition

	func _init() -> void:
		pass

var agent_game_stat_mapping = {}
var credits := 0
var round_result_record_list = []

func update_kill_count_for_agent(agent_name):
	var agent_game_stats = get_or_create_agent_game_stat(agent_name)
	agent_game_stats.kill_count += 1

func update_death_count_for_agent(agent_name):
	var agent_game_stats = get_or_create_agent_game_stat(agent_name)
	agent_game_stats.death_count += 1

func get_or_create_agent_game_stat(agent_name):
	if !agent_game_stat_mapping.has(agent_name):
		agent_game_stat_mapping[agent_name] = AgentGameStats.new()
	return agent_game_stat_mapping[agent_name]

func update_assist_counts(killed_enemy: Agent, killer_name: String):
	var enemy_damage_map = killed_enemy.damage_source_mapping
	for source in enemy_damage_map:
		if source != killer_name:
			var agent_game_stats = get_or_create_agent_game_stat(source)
			agent_game_stats.assist_count += 1

func load_weapon_from_name(weapon_name: WeaponStats.WeaponNames):
	var weapon_name_str = ""
	for enum_name in WeaponStats.WeaponNames.keys():
		if WeaponStats.WeaponNames[enum_name] == weapon_name:
				weapon_name_str = enum_name
	if weapon_name != WeaponStats.WeaponNames.NO_WEAPON:
		var weapon_resource = load("res://resources/weapons/" + weapon_name_str.to_pascal_case() + ".tres")
		return Weapon.new(weapon_resource)
	return null