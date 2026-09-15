class_name PlayerLandState
extends PlayerState

## PlayerLandState
## Brief landing compression state upon hitting the ground from fall.

var _land_timer: float = 0.0

func enter() -> void:
	var movement: Node = get_movement()
	if movement != null and movement.has_method("notify_landed"):
		movement.call("notify_landed")
	
	var duration: float = 0.08
	if movement != null and movement.get("config") != null:
		duration = movement.get("config").land_duration
	_land_timer = duration

func physics_update(delta: float) -> void:
	if player == null:
		return
	
	var movement: Node = get_movement()
	if movement == null:
		return
	
	# Immediate jump if buffered during fall
	if movement.has_method("consume_jump_intent") and movement.call("consume_jump_intent"):
		state_machine.change_state(&"Jump")
		return
	
	if not player.is_on_floor():
		state_machine.change_state(&"Fall")
		return
	
	_land_timer -= delta
	if _land_timer <= 0.0:
		var axis: float = movement.get("current_move_axis") if movement.get("current_move_axis") != null else 0.0
		if absf(axis) > 0.05:
			state_machine.change_state(&"Run")
		else:
			state_machine.change_state(&"Idle")
