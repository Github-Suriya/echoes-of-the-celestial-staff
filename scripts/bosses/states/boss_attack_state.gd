class_name BossAttackState
extends BossState

## BossAttackState
## Executes the active attack lifecycle through BossCombatController.
## Connects telegraph cues, forward impulses, recovery windows, and deflection interruptions.

func enter(_from_state: State = null) -> void:
	if boss == null:
		return
	
	boss.velocity.x = 0.0
	
	if boss.combat_controller != null:
		if not boss.combat_controller.is_attacking():
			var dist: float = -1.0
			if boss.perception != null and boss.perception.has_target():
				dist = boss.perception.get_target_distance()
			var atk: EnemyAttackData = boss.combat_controller.select_attack(dist)
			boss.combat_controller.trigger_attack(atk)

func physics_process_state(delta: float) -> void:
	if boss == null:
		return
	
	boss.apply_gravity(delta)
	
	if boss.combat_controller != null:
		if boss.combat_controller.current_phase == BossCombatController.AttackPhase.ACTIVE:
			var atk: EnemyAttackData = boss.combat_controller.active_attack_data
			if atk != null and atk.forward_impulse > 0.0:
				var facing: int = boss.get_facing_direction()
				boss.velocity.x = float(facing) * atk.forward_impulse
			else:
				boss.velocity.x = move_toward(boss.velocity.x, 0.0, 500.0 * delta)
		else:
			boss.velocity.x = move_toward(boss.velocity.x, 0.0, 650.0 * delta)
		
		# If attack completed, transition back to Combat
		if boss.combat_controller.current_phase == BossCombatController.AttackPhase.COOLDOWN or boss.combat_controller.current_phase == BossCombatController.AttackPhase.READY:
			state_machine.change_state(&"Combat")

func exit(_to_state: State = null) -> void:
	if boss != null and boss.telegraph_controller != null:
		boss.telegraph_controller.stop_telegraph()
