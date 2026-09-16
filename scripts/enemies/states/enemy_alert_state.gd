class_name EnemyAlertState
extends EnemyState

## EnemyAlertState
## Brief reaction pause upon spotting the player before engaging pursuit.

var _timer: float = 0.0

func enter() -> void:
	_timer = enemy.enemy_data.alert_duration if (enemy != null and enemy.enemy_data != null) else 0.35
	
	if enemy != null:
		if enemy.movement != null and enemy.perception != null and enemy.perception.has_target():
			enemy.movement.face_target(enemy.perception.current_target)
		if enemy.anim_controller != null:
			enemy.anim_controller.play_alert()

func physics_update(delta: float) -> void:
	if enemy == null:
		return
	
	if enemy.movement != null:
		enemy.movement.stop_horizontal(delta)
		enemy.movement.apply_gravity(delta)
		if enemy.perception != null and enemy.perception.has_target():
			enemy.movement.face_target(enemy.perception.current_target)
	
	# If target lost during alert
	if enemy.perception == null or not enemy.perception.has_target():
		state_machine.change_state(&"Idle")
		return
	
	_timer -= delta
	if _timer <= 0.0:
		state_machine.change_state(&"Chase")
