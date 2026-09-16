class_name EnemyStaggerState
extends EnemyState

## EnemyStaggerState
## Severe posture break state triggered when poise depletes to zero.
## Movement and attacks are disabled until PoiseComponent completes recovery.

func enter() -> void:
	if enemy != null:
		if enemy.combat_controller != null:
			enemy.combat_controller.reset_combat()
		if enemy.anim_controller != null:
			enemy.anim_controller.play_stagger()

func exit() -> void:
	if enemy != null and enemy.anim_controller != null:
		enemy.anim_controller.play_stagger_end()

func physics_update(delta: float) -> void:
	if enemy == null:
		return
	
	if enemy.movement != null:
		enemy.movement.apply_gravity(delta)
		enemy.movement.stop_horizontal(delta)
	
	# Check if poise component has finished stagger recovery
	if enemy.poise_component != null and not enemy.poise_component.is_staggered:
		if enemy.perception != null and enemy.perception.has_target():
			state_machine.change_state(&"Combat")
		else:
			state_machine.change_state(&"Idle")
