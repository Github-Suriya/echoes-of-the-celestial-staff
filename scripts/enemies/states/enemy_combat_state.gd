class_name EnemyCombatState
extends EnemyState

## EnemyCombatState
## Manages combat spacing, approaches, attack triggers, and cooldown pacing.

func enter() -> void:
	if enemy != null and enemy.anim_controller != null:
		enemy.anim_controller.play_idle()

func exit() -> void:
	pass

func physics_update(delta: float) -> void:
	if enemy == null:
		return
	
	# Target loss verification
	if enemy.perception == null or not enemy.perception.has_target():
		state_machine.change_state(&"Idle")
		return
	
	if enemy.movement != null:
		enemy.movement.apply_gravity(delta)
	
	var target: Node2D = enemy.perception.current_target
	var dist: float = enemy.perception.get_target_distance()
	var attack_range: float = enemy.combat_controller.get_attack_range() if enemy.combat_controller != null else 42.0
	var preferred_dist: float = enemy.enemy_data.preferred_combat_distance if enemy.enemy_data != null else 34.0
	
	# If enemy is actively mid-attack, stop locomotion and face target during telegraph
	if enemy.combat_controller != null and enemy.combat_controller.is_attacking():
		if enemy.movement != null:
			enemy.movement.stop_horizontal(delta)
			if enemy.combat_controller.current_phase == EnemyCombatController.AttackPhase.TELEGRAPH:
				enemy.movement.face_target(target)
		return
	
	# If target has fled beyond combat range, resume chase
	if dist > attack_range * 1.5:
		state_machine.change_state(&"Chase")
		return
	
	# Face target
	if enemy.movement != null:
		enemy.movement.face_target(target)
	
	# Can we trigger an attack?
	if enemy.combat_controller != null and enemy.combat_controller.can_attack():
		if dist <= attack_range:
			enemy.combat_controller.trigger_attack()
			return
	
	# Position spacing (approach or hold ground with deadzone)
	if enemy.movement != null:
		var deadzone: float = 6.0
		if dist > preferred_dist + deadzone:
			var approach_speed: float = enemy.enemy_data.patrol_speed if enemy.enemy_data != null else 50.0
			enemy.movement.move_toward_x(target.global_position.x, approach_speed, delta)
		elif dist < preferred_dist - deadzone:
			# Too close: smoothly decelerate or hold ground
			enemy.movement.stop_horizontal(delta)
		else:
			enemy.movement.stop_horizontal(delta)
