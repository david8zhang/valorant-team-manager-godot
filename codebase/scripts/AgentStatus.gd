class_name AgentStatus
extends PanelContainer

@onready var agent_name_label = $VBoxContainer/HBoxContainer/AgentNameLabel as Label
@onready var shield_bar = $VBoxContainer/ShieldBar as ProgressBar
@onready var health_bar = $VBoxContainer/HealthBar as ProgressBar

func update_from_agent(agent: Agent):
    agent_name_label.text = agent.agent_name
    shield_bar.value = agent.shield_bar.value
    health_bar.value = agent.health_bar.value