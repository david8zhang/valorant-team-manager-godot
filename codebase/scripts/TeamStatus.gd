class_name TeamStatus
extends Control

@export var agent_status_scene: PackedScene
@onready var v_container = $VBoxContainer

var agent_status_mapping = {}

func update_from_team(agents):
	for a in agents:
		var agent = a as Agent
		var agent_status_box: AgentStatus
		if !agent_status_mapping.has(agent.agent_name):
			agent_status_box = agent_status_scene.instantiate() as AgentStatus
			agent_status_mapping[agent.agent_name] = agent_status_box
			v_container.add_child(agent_status_box)
		else:
			agent_status_box = agent_status_mapping[agent.agent_name]
		agent_status_box.update_from_agent(agent)
