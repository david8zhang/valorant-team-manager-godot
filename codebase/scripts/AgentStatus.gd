class_name AgentStatus
extends PanelContainer

@onready var agent_name_label = $VBoxContainer/HBoxContainer/AgentNameLabel as Label
@onready var agent_image = $VBoxContainer/HBoxContainer/TextureRect as TextureRect
@onready var shield_bar = $VBoxContainer/ShieldBar as ProgressBar
@onready var health_bar = $VBoxContainer/HealthBar as ProgressBar
@onready var kill_count = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/HBoxContainer/KillCount
@onready var death_count = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/HBoxContainer2/DeathCount
@onready var assist_count = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer3/HBoxContainer3/AssistCount
@onready var weapon_texture = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/WeaponTexture as TextureRect

@onready var ability_1_texture = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Ability1/TextureRect as TextureRect
@onready var ability_1_charges_container = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Ability1/HBoxContainer as HBoxContainer
@onready var ability_2_texture = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Ability2/TextureRect as TextureRect
@onready var ability_2_charges_container = $VBoxContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/Ability2/HBoxContainer as HBoxContainer

@export var ability_charge_scene: PackedScene

func update_from_agent(agent: Agent):
	agent_name_label.text = agent.agent_name
	agent_image.texture = agent.agent_stats.texture
	shield_bar.value = agent.shield_bar.value
	health_bar.value = agent.health_bar.value

	var agent_game_stat_mapping = GameRoundVariables.agent_game_stat_mapping
	if agent_game_stat_mapping.has(agent.agent_name):
		var agent_game_stat = agent_game_stat_mapping[agent.agent_name] as GameRoundVariables.AgentGameStats
		kill_count.text = str(agent_game_stat.kill_count)
		death_count.text = str(agent_game_stat.death_count)
		assist_count.text = str(agent_game_stat.assist_count)
		if agent.primary_weapon != null:
			weapon_texture.texture = agent.primary_weapon.weapon_stats.in_game_texture
		else:
			weapon_texture.texture = agent.sidearm_weapon.weapon_stats.in_game_texture
		weapon_texture.flip_h = agent.curr_side == GameRound.Side.CPU
		ability_1_texture.texture = agent.agent_stats.ability_1.ability_texture
		ability_2_texture.texture = agent.agent_stats.ability_2.ability_texture
		for c in ability_1_charges_container.get_children():
			ability_1_charges_container.remove_child(c)
		for c in ability_2_charges_container.get_children():
			ability_2_charges_container.remove_child(c)
		for i in range(0, agent.ability_1_charges):
			_add_ability_charge(ability_1_charges_container)
		for i in range(0, agent.ability_2_charges):
			_add_ability_charge(ability_2_charges_container)

func _add_ability_charge(container: HBoxContainer):
	var charge_rect = ability_charge_scene.instantiate() as AbilityChargeRect
	charge_rect.rect_width = 8
	charge_rect.rect_height = 8
	container.add_child(charge_rect)