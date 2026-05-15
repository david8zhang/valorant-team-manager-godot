class_name AttackEnemy
extends SingleAgentAction

var enemy_to_attack: Agent

func get_utility(agent: Agent, _world_state: WorldState) -> float:
	var enemy_agents_in_view = agent.get_enemies_in_view()
	var max_score := 0.0
	for e in enemy_agents_in_view:
		var base_score = 0.25
		var enemy = e as Agent
		# Add bonus to fight utility score if:
		# 1. Enemy agent health is lower than ours
		if enemy.get_curr_health() < agent.get_curr_health():
			base_score += 0.1
		# 2. Enemy agent is looking away			
		if !enemy.has_vision_of_agent(agent):
			base_score += 0.2
		# 3. Enemy has worse guns
		var enemy_gun: Weapon = enemy.primary_weapon if enemy.primary_weapon != null else enemy.sidearm_weapon
		var this_agent_gun: Weapon = agent.primary_weapon if agent.primary_weapon != null else agent.sidearm_weapon
		if enemy_gun.weapon_stats.cost < this_agent_gun.weapon_stats.cost:
			base_score += 0.1
		# 4. Ally has enemy in their sight also
		if ally_has_sight(agent, enemy):
			base_score += 0.1
		if base_score > max_score:
			base_score = max_score
			enemy_to_attack = enemy
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
		var should_retaliate = enemy_to_attack.has_vision_of_agent(agent)
		agent.attack_enemy_agent(enemy_to_attack, should_retaliate, on_complete)
