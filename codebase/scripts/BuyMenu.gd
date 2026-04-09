class_name BuyMenu
extends Control

@onready var agent_buy_menu_container = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer as VBoxContainer
@onready var credits_amount_label = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer/PanelContainer/MarginContainer/HBoxContainer/CreditsAmount as Label
@onready var continue_button = $Button as Button
@onready var game_round = get_node("/root/GameRound") as GameRound

# Buy menu options
@onready var classic_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Sidearms/Classic as GunBuyMenuOption
@onready var frenzy_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Sidearms/Frenzy as GunBuyMenuOption
@onready var ghost_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Sidearms/Ghost as GunBuyMenuOption
@onready var sheriff_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Sidearms/Sheriff as GunBuyMenuOption
@onready var stinger_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/SMGsAndShotguns/SMGs/Stinger as GunBuyMenuOption
@onready var spectre_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/SMGsAndShotguns/SMGs/Spectre as GunBuyMenuOption
@onready var bucky_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/SMGsAndShotguns/Shotguns/Bucky as GunBuyMenuOption
@onready var judge_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/SMGsAndShotguns/Shotguns/Judge as GunBuyMenuOption
@onready var vandal_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Rifles/Vandal as GunBuyMenuOption
@onready var phantom_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Rifles/Phantom as GunBuyMenuOption
@onready var guardian_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Rifles/Guardian as GunBuyMenuOption
@onready var bulldog_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/Rifles/Bulldog as GunBuyMenuOption
@onready var marshall_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/SnipersAndMGs/SniperRifles/Marshall as GunBuyMenuOption
@onready var operator_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/SnipersAndMGs/SniperRifles/Operator as GunBuyMenuOption
@onready var ares_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/SnipersAndMGs/MachineGuns/Ares as GunBuyMenuOption
@onready var odin_buy_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/GridContainer/SnipersAndMGs/MachineGuns/Odin as GunBuyMenuOption
@onready var ability_1_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/Abilities/HBoxContainer/Ability1 as GunBuyMenuOption
@onready var ability_2_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/Abilities/HBoxContainer/Ability2 as GunBuyMenuOption
@onready var shields_option = $PanelContainer/VBoxContainer/HBoxContainer/VBoxContainer2/HBoxContainer2/Armor/HBoxContainer/Shields as GunBuyMenuOption

@export var agent_buy_menu_scene: PackedScene

var agent_to_buy_for: AgentBuyMenu
var primary_weapon_option: GunBuyMenuOption
var sidearm_weapon_option: GunBuyMenuOption
var original_primary_weapon_option: GunBuyMenuOption
var original_sidearm_weapon_option: GunBuyMenuOption

var all_buy_options = []

static var CREDITS_WIN = 3000
static var CREDITS_SURVIVE_LOSS = 1000
static var CREDITS_ONE_LOSS = 1900
static var CREDITS_TWO_LOSS = 2400
static var CREDITS_THREE_LOSS = 2900
static var CREDITS_SPIKE_PLANT = 300
static var CREDITS_KILL = 200

func _ready() -> void:
	all_buy_options = [
		classic_buy_option,
		frenzy_buy_option,
		ghost_buy_option,
		sheriff_buy_option,
		stinger_buy_option,
		spectre_buy_option,
		bucky_buy_option,
		bulldog_buy_option,
		judge_buy_option,
		vandal_buy_option,
		phantom_buy_option,
		guardian_buy_option,
		marshall_buy_option,
		operator_buy_option,
		ares_buy_option,
		odin_buy_option,
		ability_1_option,
		ability_2_option,
		shields_option
	]
	for o in all_buy_options:
		var option = o as GunBuyMenuOption
		option.on_click.connect(buy_option_if_possible)
		option.on_undo.connect(undo_if_possible)
	if game_round != null:
		continue_button.pressed.connect(game_round.on_buy_finished)

func init_agent_info(agents):
	for c in agent_buy_menu_container.get_children():
		if c is AgentBuyMenu:
			c.queue_free()
	for a in agents:
		var agent = a as Agent
		var agent_buy_menu = agent_buy_menu_scene.instantiate() as AgentBuyMenu
		agent_buy_menu_container.add_child(agent_buy_menu)
		agent_buy_menu.init_from_agent(agent)
		agent_buy_menu.on_click.connect(select_agent_to_buy_for)

func select_agent_to_buy_for(agent_buy_menu: AgentBuyMenu):
	if agent_to_buy_for != null:
		agent_to_buy_for.de_highlight()
		dehighlight_all_gun_buy_menu_options()
	agent_to_buy_for = agent_buy_menu
	agent_to_buy_for.select_to_buy(self)

func undo_if_possible(gun_buy_menu_option: GunBuyMenuOption):
	agent_to_buy_for.undo_if_possible(gun_buy_menu_option)
	credits_amount_label.text = str(GameRoundVariables.credits)

func buy_option_if_possible(gun_buy_menu_option: GunBuyMenuOption):
	var curr_credits = GameRoundVariables.credits
	var weapon_stats = gun_buy_menu_option.weapon_stats
	if curr_credits >= weapon_stats.cost:
		agent_to_buy_for.purchase_weapon(gun_buy_menu_option)
		credits_amount_label.text = str(GameRoundVariables.credits)

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

func dehighlight_all_gun_buy_menu_options():
	for o in all_buy_options:
		var option = o as GunBuyMenuOption
		option.de_highlight()

func get_gun_buy_menu_option_for_name(gun_name: WeaponStats.WeaponNames):
	for o in all_buy_options:
		var option = o as GunBuyMenuOption
		if option.weapon_stats.weapon_name == gun_name:
			return option
	return null
