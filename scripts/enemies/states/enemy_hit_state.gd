class_name EnemyHitState
extends EnemyState

## EnemyHitState
## Brief flinch reaction when struck by player attacks.

var _timer: float = 0.0

func enter() -> void:
	_timer = 0.15
	if enemy != null and enemy.anim_controller != null:
		enemy.anim_controller.play_hit()

func physics_update(delta: float) -> void:
	if enemy == null:
		return
	
	if enemy.movement != null:
		enemy.movement.apply_gravity(delta)
		enemy.movement.stop_horizontal(delta)
	
	_timer -= delta
	if _timer <= 0.0:
		if enemy.perception != null and enemy.perception.has_target():
			state_machine.change_state(&"Combat")
		else:
			state_machine.change_state(&"Idle")
