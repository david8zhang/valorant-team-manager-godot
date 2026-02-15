class_name BuyMenu
extends Control

@onready var agent_buy_menu_container = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer as VBoxContainer
@onready var credits_amount_label = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/CreditsAmount as Label
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

func setup_credits(agents, winning_side: GameRound.Side):
	for a in agents:
		var agent = a as Agent
		var total_credits_earned := 0
		if winning_side == GameRound.Side.PLAYER:
			total_credits_earned = CREDITS_WIN
		else:
			if agent.is_dead():
				var losing_streak = 0
				var round_result_record_list = GameRoundVariables.round_result_record_list
				var list_size = round_result_record_list.size()
				for i in range(0, list_size):
					var result = round_result_record_list[list_size - 1 - i] as GameRoundVariables.RoundResultRecord
					if result.winning_side == GameRound.Side.CPU:
						losing_streak += 1
					else:
						break
				if losing_streak == 1:
					total_credits_earned = CREDITS_ONE_LOSS
				elif losing_streak == 2:
					total_credits_earned = CREDITS_TWO_LOSS
				else:
					total_credits_earned = CREDITS_THREE_LOSS
			else:
				total_credits_earned = CREDITS_SURVIVE_LOSS
		total_credits_earned += agent.kills_this_round * CREDITS_KILL
		if agent.did_defuse_this_round:
			pass
		elif agent.did_plant_this_round:
			total_credits_earned += CREDITS_SPIKE_PLANT
		GameRoundVariables.credits += total_credits_earned
	credits_amount_label.text = str(GameRoundVariables.credits)