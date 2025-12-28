extends Node

class AgentGameStats:
    var kill_count := 0
    var death_count := 0
    var assist_count := 0
    var credits := 0
    var primary_weapon_name := WeaponStats.WeaponNames.NO_WEAPON
    var sidearm_weapon_name := WeaponStats.WeaponNames.CLASSIC

    func _init() -> void:
        pass

var agent_game_stat_mapping = {}

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
    pass