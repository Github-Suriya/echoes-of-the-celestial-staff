class_name BossIdleState
extends BossState

## BossIdleState
## Stationed stance between active combat loops or before target acquisition.

func enter(_from_state: State = null) -> void:
	if boss != null:
		boss.velocity.x = 0.0

func physics_update(delta: float) -> void:
	if boss == null:
		return
	
	boss.apply_gravity(delta)
	boss.velocity.x = move_toward(boss.velocity.x, 0.0, 650.0 * delta)
	
	if boss.perception != null and boss.perception.has_target():
		state_machine.change_state(&"Combat")

func physics_process_state(delta: float) -> void:
	physics_update(delta)
