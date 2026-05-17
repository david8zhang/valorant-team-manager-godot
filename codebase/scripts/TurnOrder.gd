class_name TurnOrder
extends Control

@onready var game_round = get_node("/root/GameRound") as GameRound
@onready var hbox_container = $HBoxContainer as HBoxContainer
@export var turn_order_card_scene: PackedScene

func init_turn_order_list(agents_list):
	for a in agents_list:
		var agent = a as Agent
		var new_turn_order_card = turn_order_card_scene.instantiate() as TurnOrderCard
		hbox_container.add_child(new_turn_order_card)
		new_turn_order_card.update_from_agent(agent)
		if agent.agent_name == game_round.turn_queue[game_round.curr_turn_index]:
			new_turn_order_card.highlight_curr_card()
		else:
			new_turn_order_card.dehighlight_curr_card()

func update_turn_order_list(agents_list, next_agent):
	for i in range(0, hbox_container.get_child_count()):
		var turn_order_card = hbox_container.get_child(i) as TurnOrderCard
		var agent = agents_list[i] as Agent
		if agent.is_dead():
			turn_order_card.hide()
		elif next_agent != null and agent.agent_name == next_agent.agent_name:
			turn_order_card.highlight_curr_card()
		else:
			turn_order_card.dehighlight_curr_card()

func reset_turn_order():
	pass