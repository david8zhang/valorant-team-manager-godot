class_name BuyMenu
extends Control

@onready var agent_buy_menu_container = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer as VBoxContainer
@export var agent_buy_menu_scene: PackedScene

static var CREDITS_WIN = 3000
static var CREDITS_SURVIVE_LOSS = 1000
static var CREDITS_ONE_LOSS = 1900
static var CREDITS_TWO_LOSS = 2400
static var CREDITS_THREE_LOSS = 2900
static var CREDITS_SPIKE_PLANT = 300
static var CREDITS_KILL = 200

func init_agent_info(agents):
	for a in agents:
		var agent = a as Agent
		var agent_buy_menu = agent_buy_menu_scene.instantiate() as AgentBuyMenu
		agent_buy_menu_container.add_child(agent_buy_menu)
		agent_buy_menu.init_from_agent(agent)