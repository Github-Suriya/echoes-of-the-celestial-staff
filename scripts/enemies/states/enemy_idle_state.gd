class_name EnemyIdleState
extends EnemyState

## EnemyIdleState
## Stationary waiting state between patrols or when scanning for targets.

var _timer: float = 0.0

func enter() -> void:
	if enemy != null and enemy.anim_controller != null:
		enemy.anim_controller.play_idle()
	
	_timer = enemy.enemy_data.patrol_wait_time if (enemy != null and enemy.enemy_data != null) else 1.2

func physics_update(delta: float) -> void:
	if enemy == null:
		return
	
	if enemy.movement != null:
		enemy.movement.stop_horizontal(delta)
		enemy.movement.apply_gravity(delta)
	
	# Target detection trigger
	if enemy.perception != null and enemy.perception.has_target():
		state_machine.change_state(&"Alert")
		return
	
	_timer -= delta
	if _timer <= 0.0:
		state_machine.change_state(&"Patrol")
