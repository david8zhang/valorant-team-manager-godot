class_name DebugMenu
extends Control

@onready var game_round = get_node("/root/GameRound") as GameRound
@onready var show_cpu_vision_button = $VBoxContainer/ShowCPUVision as Button
@onready var show_player_vision_button = $VBoxContainer/ShowPlayerVision as Button
@onready var force_player_win_elim_button = $VBoxContainer/ForcePlayerElimWin as Button
@onready var force_player_win_detonate_button = $VBoxContainer/ForcePlayerDetonateWin as Button
@onready var force_cpu_win_elim_button = $VBoxContainer/ForceCPUElimWin as Button
@onready var force_cpu_win_defuse_button = $VBoxContainer/ForceCPUDefuseWin as Button
@onready var kill_curr_agent_button = $VBoxContainer/KillCurrAgent as Button

var vision_side_to_show := GameRound.Side.PLAYER

func _ready() -> void:
	show_cpu_vision_button.pressed.connect(show_cpu_vision)
	show_player_vision_button.pressed.connect(show_player_vision)
	force_player_win_elim_button.pressed.connect(force_player_win_elim)
	kill_curr_agent_button.pressed.connect(kill_curr_agent)
	await game_round.ready
	game_round.cpu_agent_controller.on_complete_move.connect(update_cpu_vision_after_move)

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_menu"):
		visible = !visible

func update_cpu_vision_after_move():
	if vision_side_to_show == GameRound.Side.CPU:
		show_cpu_vision()

func show_cpu_vision():
	vision_side_to_show = GameRound.Side.CPU
	for a in game_round.cpu_team.agents:
		var agent = a as Agent
		if !agent.is_dead():
			agent.show()
	var all_visible_tiles = game_round.cpu_team.get_all_visible_tiles()
	game_round.map.vision_layer.clear()
	game_round.map.show_specific_visible_tiles(all_visible_tiles)
	game_round.update_specific_visible_enemies(all_visible_tiles, game_round.player_team.agents)

func show_player_vision():
	vision_side_to_show = GameRound.Side.PLAYER
	for a in game_round.player_team.agents:
		var agent = a as Agent
		if !agent.is_dead():
			agent.show()
	game_round.map.show_player_team_visible_tiles()
	game_round.update_visible_enemies_to_player()

func force_player_win_elim():
	for a in game_round.player_team.agents:
		var agent = a as Agent
		GameRoundVariables.update_kill_count_for_agent(agent.agent_name)
		agent.kills_this_round += 1
	for a in game_round.cpu_team.agents:
		var agent = a as Agent
		agent.health_bar.value = 0
	game_round.handle_win_condition(RoundResult.WinCondition.ELIMINATION)
	visible = false

func kill_curr_agent():
	var agent_controller = game_round.agent_controller
	var selected_agent = agent_controller.selected_agent
	selected_agent.take_damage(1000)