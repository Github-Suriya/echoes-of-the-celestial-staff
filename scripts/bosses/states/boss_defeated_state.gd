class_name BossDefeatedState
extends BossState

## BossDefeatedState
## Terminal encounter state. Disables hitboxes and hurtboxes, halts physics,
## triggers defeat presentation, and notifies the arena controller to unlock barriers.

func enter(_from_state: State = null) -> void:
	if boss == null:
		return
	
	boss.velocity.x = 0.0
	boss.is_defeated = true
	
	if boss.hitbox != null:
		boss.hitbox.deactivate()
	
	if boss.hurtbox != null:
		boss.hurtbox.set_deferred("monitoring", false)
		boss.hurtbox.set_deferred("monitorable", false)
	
	if boss.combat_controller != null:
		boss.combat_controller.reset_combat()
	
	if boss.telegraph_controller != null:
		boss.telegraph_controller.stop_telegraph()
	
	if boss.anim_controller != null:
		var duration: float = boss.boss_data.defeat_duration if boss.boss_data != null else 2.0
		boss.anim_controller.play_defeat(duration)
	
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("boss_defeated"):
			var bname: String = boss.boss_data.display_name if boss.boss_data != null else "Boss"
			bus.boss_defeated.emit(bname)

func physics_update(delta: float) -> void:
	if boss == null:
		return
	boss.apply_gravity(delta)
	boss.velocity.x = move_toward(boss.velocity.x, 0.0, 800.0 * delta)

func physics_process_state(delta: float) -> void:
	physics_update(delta)
