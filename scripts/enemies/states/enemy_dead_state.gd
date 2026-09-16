class_name EnemyDeadState
extends EnemyState

## EnemyDeadState
## Terminal state entered upon health depletion.
## Disables combat actions, collision detection, and perception.

func enter() -> void:
	if enemy != null:
		if enemy.combat_controller != null:
			enemy.combat_controller.reset_combat()
		if enemy.perception != null:
			enemy.perception.clear_target()
		if enemy.hurtbox != null:
			enemy.hurtbox.set_deferred("monitoring", false)
			enemy.hurtbox.set_deferred("monitorable", false)
		if enemy.anim_controller != null:
			enemy.anim_controller.play_death()

func physics_update(delta: float) -> void:
	if enemy == null:
		return
	
	# Settle corpse onto floor if falling
	if not enemy.is_on_floor():
		if enemy.movement != null:
			enemy.movement.apply_gravity(delta)
			enemy.movement.stop_horizontal(delta)
	else:
		enemy.velocity = Vector2.ZERO
