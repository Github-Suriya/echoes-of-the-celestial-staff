class_name EnemyPatrolState
extends EnemyState

## EnemyPatrolState
## Horizontal patrol movement between boundaries or waypoints.

func enter() -> void:
	if enemy != null and enemy.anim_controller != null:
		enemy.anim_controller.play_walk()

func physics_update(delta: float) -> void:
	if enemy == null:
		return
	
	if enemy.movement != null:
		enemy.movement.apply_gravity(delta)
	
	# Target detection check
	if enemy.perception != null and enemy.perception.has_target():
		state_machine.change_state(&"Alert")
		return
	
	# Step patrol logic
	if enemy.movement != null:
		var reached_waypoint: bool = enemy.movement.step_patrol(delta)
		if reached_waypoint:
			state_machine.change_state(&"Idle")
