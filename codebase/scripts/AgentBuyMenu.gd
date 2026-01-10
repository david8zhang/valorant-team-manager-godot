class_name AgentBuyMenu
extends Control

@onready var agent_name_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/Label
@onready var kill_count_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/HBoxContainer/KillCount
@onready var death_count_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/HBoxContainer2/DeathCount
@onready var assist_count_label = $PanelContainer/VBoxContainer/PanelContainer/MarginContainer2/HBoxContainer/HBoxContainer3/AssistCount

func init_from_agent(agent: Agent):
	agent_name_label.text = agent.agent_name
	var agent_stats = GameRoundVariables.get_or_create_agent_game_stat(agent.agent_name) as GameRoundVariables.AgentGameStats
	kill_count_label.text = str(agent_stats.kill_count)
	death_count_label.text = str(agent_stats.death_count)
	assist_count_label.text = str(agent_stats.assist_count)