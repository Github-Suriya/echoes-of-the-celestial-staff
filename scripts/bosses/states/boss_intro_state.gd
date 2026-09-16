class_name BossIntroState
extends BossState

## BossIntroState
## Initial encounter state. Boss awakens, faces the entering player, and establishes presence.

var _timer: float = 0.0

func enter(_from_state: State = null) -> void:
	var duration: float = 1.5
	if boss != null and boss.boss_data != null:
		duration = boss.boss_data.intro_duration
	_timer = duration
	
	if boss != null:
		boss.velocity.x = 0.0
		if boss.anim_controller != null:
			boss.anim_controller.play_intro(duration)
		if boss.perception != null and boss.perception.has_target():
			boss.face_target()

func physics_update(delta: float) -> void:
	if boss == null:
		return
	
	boss.apply_gravity(delta)
	boss.velocity.x = move_toward(boss.velocity.x, 0.0, 500.0 * delta)
	
	if boss.perception != null and boss.perception.has_target():
		boss.face_target()
	
	_timer -= delta
	if _timer <= 0.0:
		if boss.perception != null and boss.perception.has_target():
			state_machine.change_state(&"Combat")
		else:
			state_machine.change_state(&"Idle")

func physics_process_state(delta: float) -> void:
	physics_update(delta)
