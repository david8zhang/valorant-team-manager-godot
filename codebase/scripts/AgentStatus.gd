class_name AgentStatus
extends PanelContainer

@onready var agent_name_label = $VBoxContainer/HBoxContainer/AgentNameLabel as Label
@onready var shield_bar = $VBoxContainer/ShieldBar as ProgressBar
@onready var health_bar = $VBoxContainer/HealthBar as ProgressBar
@onready var kill_count = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/HBoxContainer/KillCount
@onready var death_count = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/HBoxContainer2/DeathCount
@onready var assist_count = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/HBoxContainer3/AssistCount
@onready var weapon_texture = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/WeaponTexture as TextureRect

func update_from_agent(agent: Agent):
    agent_name_label.text = agent.agent_name
    shield_bar.value = agent.shield_bar.value
    health_bar.value = agent.health_bar.value

    var agent_game_stat_mapping = GameRoundVariables.agent_game_stat_mapping
    if agent_game_stat_mapping.has(agent.agent_name):
        var agent_game_stat = agent_game_stat_mapping[agent.agent_name] as GameRoundVariables.AgentGameStats
        kill_count.text = str(agent_game_stat.kill_count)
        death_count.text = str(agent_game_stat.death_count)
        assist_count.text = str(agent_game_stat.assist_count)
        if agent.primary_weapon != null:
            weapon_texture.texture = agent.primary_weapon.weapon_stats.texture
        else:
            weapon_texture.texture = agent.sidearm_weapon.weapon_stats.texture