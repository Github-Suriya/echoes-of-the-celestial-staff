class_name BossHitState
extends BossState

## BossHitState
## Flinch and deflection recoil state for boss attacks interrupted or deflected by the player.

var _timer: float = 0.0

func enter(_from_state: State = null) -> void:
	_timer = 0.25
	if boss != null:
		boss.velocity.x = 0.0
		if boss.anim_controller != null:
			boss.anim_controller.play_hit_flash(_timer)

func physics_process_state(delta: float) -> void:
	if boss == null:
		return
	
	boss.apply_gravity(delta)
	boss.velocity.x = move_toward(boss.velocity.x, 0.0, 600.0 * delta)
	
	_timer -= delta
	if _timer <= 0.0:
		state_machine.change_state(&"Combat")
