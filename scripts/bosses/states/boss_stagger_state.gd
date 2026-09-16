class_name BossStaggerState
extends BossState

## BossStaggerState
## Vulnerability state triggered upon posture / poise breakage.
## Locks out locomotion and offensive actions, creating an execution window for the player.

var _timer: float = 0.0

func enter(_from_state: State = null) -> void:
	var duration: float = 1.8
	if boss != null:
		if boss.poise_component != null:
			duration = boss.poise_component.stagger_duration
		elif boss.boss_data != null:
			duration = boss.boss_data.stagger_duration
		
		boss.velocity.x = 0.0
		if boss.hitbox != null:
			boss.hitbox.deactivate()
		if boss.combat_controller != null:
			boss.combat_controller.reset_combat()
		if boss.anim_controller != null:
			boss.anim_controller.play_stagger(duration)
		
		if has_node("/root/EventBus"):
			var bus: Node = get_node("/root/EventBus")
			if bus != null and bus.has_signal("boss_staggered"):
				var bname: String = boss.boss_data.display_name if boss.boss_data != null else "Boss"
				bus.boss_staggered.emit(bname)
	
	_timer = duration

func physics_update(delta: float) -> void:
	if boss == null:
		return
	
	boss.apply_gravity(delta)
	boss.velocity.x = move_toward(boss.velocity.x, 0.0, 700.0 * delta)
	
	_timer -= delta
	if _timer <= 0.0:
		if boss.poise_component != null:
			boss.poise_component.end_stagger()
		state_machine.change_state(&"Combat")

func physics_process_state(delta: float) -> void:
	physics_update(delta)
