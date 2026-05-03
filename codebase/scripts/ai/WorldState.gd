class_name WorldState
extends Node

var last_known_player_agent_pos_map := {}
var agent_assignments := {}
var game_round: GameRound
var cpu_agent_controller: CPUAgentController

func initialize(_cpu_agent_controller: CPUAgentController):
	cpu_agent_controller = _cpu_agent_controller
	game_round = cpu_agent_controller.game_round

func report_player_agent(agent_name: String, tile_pos: Vector2):
	last_known_player_agent_pos_map[agent_name] = tile_pos

func get_closest_known_enemy(curr_tile_pos: Vector2):
	var min_dist = INF
	var closest_enemy_name := ""
	for k in last_known_player_agent_pos_map.keys():
		var position = last_known_player_agent_pos_map[k] as Vector2
		var distance = position.distance_to(curr_tile_pos)
		if distance <= min_dist:
			distance = min_dist
			closest_enemy_name = k
	return game_round.get_agent_for_name(closest_enemy_name)

func get_team_strategy():
	return cpu_agent_controller.team_strategy

func get_site_positions(site: TeamStrategy.Site):
	var prefix_matcher := ""
	match site:
		TeamStrategy.Site.A:
			prefix_matcher = "A_"
		TeamStrategy.Site.B:
			prefix_matcher = "B_"
		TeamStrategy.Site.C:
			prefix_matcher = "C_"
	var positions = []
	var waypoints = game_round.map.map_data.waypoints
	for wp in waypoints:
		var waypoint = wp as TileMapWaypoint
		if waypoint.waypoint_name.begins_with(prefix_matcher):
			positions.append(wp)
	return positions