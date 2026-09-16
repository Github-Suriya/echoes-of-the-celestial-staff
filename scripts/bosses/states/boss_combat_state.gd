class_name BossCombatState
extends BossState

## BossCombatState
## Core combat positioning and spacing state.
## Moves toward preferred combat distance without crowding the player,
## maintains facing, and transitions to Attack state when openings arise.

func physics_update(delta: float) -> void:
	if boss == null:
		return
	
	boss.apply_gravity(delta)
	
	if boss.perception == null or not boss.perception.has_target():
		state_machine.change_state(&"Idle")
		return
	
	var target: Node2D = boss.perception.current_target
	var diff_x: float = target.global_position.x - boss.global_position.x
	var dist_x: float = absf(diff_x)
	
	# Hysteresis facing to avoid jitter
	if dist_x > 12.0:
		boss.set_facing_direction(1 if diff_x > 0.0 else -1)
	
	# Check attack opportunity
	if boss.combat_controller != null and boss.combat_controller.can_attack():
		var preferred_atk: EnemyAttackData = boss.combat_controller.select_attack(dist_x)
		if preferred_atk != null and dist_x <= preferred_atk.attack_range * 1.15:
			state_machine.change_state(&"Attack")
			return
	
	# Spacing & Locomotion
	var preferred_dist: float = 50.0
	var speed: float = 60.0
	var accel: float = 400.0
	var decel: float = 650.0
	
	if boss.boss_data != null:
		preferred_dist = boss.boss_data.preferred_combat_distance
		speed = boss.boss_data.chase_speed
		accel = boss.boss_data.acceleration
		decel = boss.boss_data.deceleration
	
	if boss.combat_controller != null:
		speed *= boss.combat_controller.movement_speed_multiplier
	
	if dist_x > preferred_dist + 15.0:
		# Approach target
		var dir_sign: float = signf(diff_x)
		boss.velocity.x = move_toward(boss.velocity.x, dir_sign * speed, accel * delta)
	elif dist_x < preferred_dist - 20.0 and dist_x > 8.0:
		# Reposition slightly back if crowded
		var retreat_sign: float = -signf(diff_x)
		boss.velocity.x = move_toward(boss.velocity.x, retreat_sign * (speed * 0.5), accel * delta)
	else:
		# Stable combat stance
		boss.velocity.x = move_toward(boss.velocity.x, 0.0, decel * delta)

func physics_process_state(delta: float) -> void:
	physics_update(delta)
