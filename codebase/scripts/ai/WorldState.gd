class_name WorldState
extends Node

enum MapControlState {
	PLAYER,
	CPU,
	NEUTRAL,
	CONTESTED
}

class WaypointControlData:
	var control_state := MapControlState.NEUTRAL
	# -1 represents "unknown"
	var num_player_agents := -1
	var num_cpu_agents := 0

var last_known_player_agent_pos_map := {}
var agent_assignments := {}
var game_round: GameRound
var cpu_agent_controller: CPUAgentController
var map_control_view := {}
var tiles_being_held := []

func initialize(_cpu_agent_controller: CPUAgentController):
	cpu_agent_controller = _cpu_agent_controller
	game_round = cpu_agent_controller.game_round

func report_enemy_agent(agent_name: String, tile_pos: Vector2):
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

func update_map_control_view():
	var map_data = game_round.map.map_data as MultiTileMapData
	var cpu_agent_positions = get_cpu_agent_tile_positions()
	var player_agent_positions = last_known_player_agent_pos_map.values()
	for wp in map_data.waypoints:
		var waypoint = wp as TileMapWaypoint
		var num_cpu_agents = get_num_agents_in_proximity(waypoint.waypoint_tile_pos, cpu_agent_positions, 10)
		var num_player_agents = get_num_agents_in_proximity(waypoint.waypoint_tile_pos, player_agent_positions, 10)
		if !map_control_view.has(waypoint.waypoint_name):
			map_control_view[waypoint.waypoint_name] = WaypointControlData.new()
		var waypoint_control_data = map_control_view[waypoint.waypoint_name] as WaypointControlData
		waypoint_control_data.num_cpu_agents = num_cpu_agents
		# If no info on player positions yet, assume their spawn is controlled by them
		if player_agent_positions.is_empty():
			var opp_side_prefix = "DEFENDER" if game_round.attack_side == GameRound.Side.CPU else "ATTACKER"
			if waypoint.waypoint_name.begins_with(opp_side_prefix):
				waypoint_control_data.control_state = MapControlState.PLAYER
				waypoint_control_data.num_player_agents = 5
		else:
			waypoint_control_data.num_player_agents = num_player_agents
		# Update waypoint control depending on number of agents nearby
		if num_cpu_agents > 0 and num_player_agents == 0:
			waypoint_control_data.control_state = MapControlState.CPU
		elif num_player_agents > 0 and num_cpu_agents == 0:
			waypoint_control_data.control_state = MapControlState.PLAYER
		else:
			if num_cpu_agents == 0 and num_player_agents == 0:
				waypoint_control_data.control_state = MapControlState.NEUTRAL
			else:
				waypoint_control_data.control_state = MapControlState.CONTESTED

func update_tiles_being_held():
	var cpu_agents = game_round.cpu_team
	for a in cpu_agents:
		var agent = a as Agent
		if agent.is_holding:
			var tiles = agent.get_tiles_in_view()
			tiles_being_held.append_array(tiles)

func get_cpu_agent_tile_positions():
	var map = game_round.map
	return game_round.cpu_team.agents.map(func(a): return map.get_tile_pos_from_world_pos(a.global_position))

func get_num_agents_in_proximity(waypoint_center_tile_pos: Vector2, agent_tile_positions: Array, dist_threshold: int) -> int:
	var count := 0
	for agent_pos in agent_tile_positions:
		var dist_to_center = agent_pos.distance_to(waypoint_center_tile_pos)
		if dist_to_center <= dist_threshold:
			count += 1
	return count

func get_nearest_waypoint(tile_pos: Vector2, dist_threshold: int):
	var map_data = game_round.map.map_data as MultiTileMapData
	var nearest_waypoint: TileMapWaypoint = null
	var closest_dist := dist_threshold
	for wp in map_data.waypoints:
		var waypoint = wp as TileMapWaypoint
		var distance = waypoint.waypoint_tile_pos.distance_to(tile_pos)
		if distance < closest_dist:
			closest_dist = distance
			nearest_waypoint = waypoint
	return nearest_waypoint

func is_waypoint_dangerous(waypoint: TileMapWaypoint):
	var waypoint_name = waypoint.waypoint_name
	if !map_control_view.has(waypoint_name):
		return false
	var waypoint_control_data = map_control_view[waypoint_name] as WaypointControlData
	return waypoint_control_data.num_player_agents > waypoint_control_data.num_cpu_agents

func is_waypoint_safe(waypoint: TileMapWaypoint):
	var waypoint_name = waypoint.waypoint_name
	if !map_control_view.has(waypoint_name):
		return false
	var waypoint_control_data = map_control_view[waypoint_name] as WaypointControlData
	return waypoint_control_data.num_player_agents < waypoint_control_data.num_cpu_agents or tiles_being_held.has(waypoint.waypoint_tile_pos)

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
