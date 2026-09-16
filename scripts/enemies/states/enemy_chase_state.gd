class_name EnemyChaseState
extends EnemyState

## EnemyChaseState
## Pursues the acquired target at chase_speed until entering attack range or losing the target.

func enter() -> void:
	if enemy != null and enemy.anim_controller != null:
		enemy.anim_controller.play_walk()

func physics_update(delta: float) -> void:
	if enemy == null:
		return
	
	# Validate target
	if enemy.perception == null or not enemy.perception.has_target():
		state_machine.change_state(&"Idle")
		return
	
	if enemy.movement != null:
		enemy.movement.apply_gravity(delta)
	
	var target: Node2D = enemy.perception.current_target
	var dist: float = enemy.perception.get_target_distance()
	var attack_range: float = enemy.combat_controller.get_attack_range() if enemy.combat_controller != null else 42.0
	
	# Check if reached attack range
	if dist <= attack_range:
		state_machine.change_state(&"Combat")
		return
	
	# Pursue target horizontally
	if enemy.movement != null:
		var chase_speed: float = enemy.enemy_data.chase_speed if enemy.enemy_data != null else 110.0
		enemy.movement.move_toward_x(target.global_position.x, chase_speed, delta)
