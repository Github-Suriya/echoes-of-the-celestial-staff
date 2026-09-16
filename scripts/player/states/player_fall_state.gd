class_name PlayerFallState
extends PlayerState

## PlayerFallState
## Active when the player is airborne and descending.
## Supports coyote-time jumps when walking off edges.

func enter() -> void:
	pass

func physics_update(_delta: float) -> void:
	if player == null:
		return
	
	var movement: Node = get_movement()
	if movement == null:
		return
	
	# Check for coyote-time jump or mid-air jump intent
	if movement.has_method("consume_jump_intent") and movement.call("consume_jump_intent"):
		state_machine.change_state(&"Jump")
		return
	
	# Check air attack trigger
	if Input.is_action_just_pressed(&"light_attack"):
		state_machine.change_state(&"AirAttack")
		return
	
	# Ground impact
	if player.is_on_floor():
		state_machine.change_state(&"Land")
