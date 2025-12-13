class_name DebugMenu
extends Control

@onready var game_round = get_node("/root/GameRound") as GameRound
@onready var show_cpu_vision_button = $VBoxContainer/ShowCPUVision as Button
@onready var show_player_vision_button = $VBoxContainer/ShowPlayerVision as Button

var vision_side_to_show := GameRound.Side.PLAYER

func _ready() -> void:
	show_cpu_vision_button.pressed.connect(show_cpu_vision)
	show_player_vision_button.pressed.connect(show_player_vision)
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
	game_round.update_visible_enemies()
