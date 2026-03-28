extends Node

# Store agent stats between rounds
class AgentGameStats:
	var kill_count := 0
	var death_count := 0
	var assist_count := 0
	var credits := 0
	var primary_weapon_name := GameRoundVariables.get_random_weapon(
		[WeaponStats.WeaponNames.ARES]
	)
	var sidearm_weapon_name := WeaponStats.WeaponNames.SHERIFF
	var ability_1_charges := 0
	var ability_2_charges := 0

	func _init() -> void:
			pass

# Class for storing round results
class RoundResultRecord:
	var winning_side: GameRound.Side
	var win_condition: RoundResult.WinCondition

	func _init() -> void:
		pass

static var AGENT_STAT_RESOURCES = [
	load("res://resources/agents/Brimstone.tres"),
	load("res://resources/agents/Phoenix.tres"),
	load("res://resources/agents/Sage.tres"),
	load("res://resources/agents/Sova.tres")
]
static var PLAYER_OUTLINE_COLOR = Color8(39, 239, 190)
static var CPU_OUTLINE_COLOR = Color.RED

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

func load_weapon_from_name(weapon_name: WeaponStats.WeaponNames, game_round: GameRound):
	var weapon_name_str = get_weapon_name_str(weapon_name)
	if weapon_name != WeaponStats.WeaponNames.NO_WEAPON:
		var weapon_resource = load("res://resources/weapons/" + weapon_name_str.to_pascal_case() + ".tres")
		return Weapon.new(weapon_resource, game_round)
	return null

func get_weapon_name_str(weapon_name: WeaponStats.WeaponNames):
	var weapon_name_str = ""
	for enum_name in WeaponStats.WeaponNames.keys():
		if WeaponStats.WeaponNames[enum_name] == weapon_name:
				weapon_name_str = enum_name	
	return weapon_name_str

func get_random_weapon(rand_weapon_list = []) -> WeaponStats.WeaponNames:
	return rand_weapon_list.pick_random()

func purchase_ability_charge(agent_name, ability_index):
	var agent_game_stats = get_or_create_agent_game_stat(agent_name)
	if ability_index == 1:
		agent_game_stats.ability_1_charges += 1
	elif ability_index == 2:
		agent_game_stats.ability_2_charges += 1
		
func load_random_agent_stat():
	return AGENT_STAT_RESOURCES.pick_random()
