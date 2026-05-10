class_name HoldAngle
extends SingleAgentAction

var angle_to_hold: Vector2

func get_utility(agent: Agent, world_state: WorldState) -> float:
	# 1. Get all visible tiles in each compass direction angle (N, S, E, W, NE, NW, SE, SW)
	# 2. For each visible tile set, check if it covers a dangerous waypoint
	# 3. Determining a "dangerous" choke point is based on proximity to enemy controlled map areas (danger heatmap)
	var directions = [
		Vector2.UP,
		Vector2.DOWN,
		Vector2.LEFT,
		Vector2.RIGHT,
		Vector2(1, 1).normalized(), # Southeast
		Vector2(-1, 1).normalized(), # Southwest
		Vector2(1, -1).normalized(), # Northeast
		Vector2(-1, -1).normalized(), # Northwest
	]
	var max_angle_score = 0
	var get_wp_tile_pos = func _get_wp_tile_pos(wp: TileMapWaypoint):
		return Vector2i(wp.waypoint_tile_pos)
	var dangerous_wp = world_state.get_dangerous_waypoints().map(get_wp_tile_pos)
	var tiles_being_held = world_state.tiles_being_held
	for dir in directions:
		var curr_angle_score = 0
		var visible_tiles_dict = convert_arr_to_dict(agent.get_tiles_in_view_for_direction(dir))
		# Add bonus if the held angle covers dangerous waypoints
		var dangerous_wp_visible = get_intersection(dangerous_wp, visible_tiles_dict)
		curr_angle_score += 0.3 * dangerous_wp_visible.size()
		# Subtract penalty if overlaps with angle already being held by other agents
		var tiles_already_held = get_intersection(tiles_being_held, visible_tiles_dict)
		curr_angle_score -= 0.1 * tiles_already_held.size()
		if curr_angle_score > max_angle_score:
			max_angle_score = curr_angle_score
			angle_to_hold = dir
	return max_angle_score

func get_intersection(arr: Array, dict: Dictionary):
	return arr.filter(func(a): return dict.has(a))

func convert_arr_to_dict(arr: Array):
	var dict = {}
	for a in arr:
		dict[a] = true
	return dict

func execute(agent: Agent, _world_state: WorldState, on_complete: Callable) -> void:
	var map = agent.game_round.map as Map
	print("Holding angle: " + str(angle_to_hold))
	var target_tile_pos_to_watch = angle_to_hold + Vector2(map.get_tile_pos_from_world_pos(agent.global_position))
	var target_world_pos = map.get_world_pos_from_tile_pos(target_tile_pos_to_watch)
	agent.look_at_position(target_world_pos)
	agent.is_holding = true
	agent.pos_to_watch = target_world_pos
	on_complete.call()
