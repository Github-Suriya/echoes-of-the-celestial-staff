class_name PlayerJumpState
extends PlayerState

## PlayerJumpState
## Active during the ascending phase of a jump.

func enter() -> void:
	var movement: Node = get_movement()
	if movement != null and movement.has_method("apply_jump_impulse"):
		movement.call("apply_jump_impulse")

func physics_update(_delta: float) -> void:
	if player == null:
		return
	
	# Transition to Fall as soon as upward velocity reaches apex
	if player.velocity.y >= 0.0:
		state_machine.change_state(&"Fall")
		return
	
	# If player somehow lands (e.g. slopes/ceilings)
	if player.is_on_floor():
		state_machine.change_state(&"Land")
