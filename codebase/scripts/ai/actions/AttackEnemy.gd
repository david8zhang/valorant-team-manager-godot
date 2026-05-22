class_name AttackEnemy
extends SingleAgentAction

var enemy_to_attack: Agent

func get_utility(agent: Agent, _world_state: WorldState) -> float:
	var enemy_agents_in_view = agent.get_enemies_in_view()
	var max_score := 0.0
	enemy_to_attack = null
	
	for e in enemy_agents_in_view:
		var e_agent = e as Agent
		if e_agent.is_dead(): continue
		
		# Start with a base value of 0.3 for any visible threat
		var score = 0.3 
		
		# Add bonuses for tactical advantages to prioritize "easy" or "important" kills
		if e_agent.get_curr_health() < agent.get_curr_health(): score += 0.2
		if !e_agent.has_vision_of_agent(agent): score += 0.2
		if ally_has_sight(agent, e_agent): score += 0.1
		if e_agent.is_planting or e_agent.is_defusing: score += 0.2
		
		# Clamp to ensure it never exceeds 1.0, keeping utility consistent
		score = clamp(score, 0.0, 1.0)
		
		# Keep track of the highest scoring enemy to attack
		if score > max_score:
			max_score = score
			enemy_to_attack = e_agent
			
	return max_score

func ally_has_sight(agent: Agent, enemy: Agent):
	var game_round = agent.game_round as GameRound
	var living_allies = game_round.cpu_team.get_all_living_agents().filter(func (a: Agent): return a.agent_name != agent.agent_name)
	for ally in living_allies:
		var ally_agent = ally as Agent
		if ally_agent.has_vision_of_agent(enemy):
			return true
	return false

func execute(agent: Agent, _world_state: WorldState, on_complete: Callable) -> void:
	if enemy_to_attack != null:
		print("[" + agent.agent_name + "]" + " attacking " + enemy_to_attack.agent_name)
		var should_retaliate = enemy_to_attack.has_vision_of_agent(agent)
		agent.attack_enemy_agent(enemy_to_attack, should_retaliate, on_complete)
