class_name PlayerIdleState
extends PlayerState

## PlayerIdleState
## Active when player is grounded with zero horizontal movement intent.

func enter() -> void:
	pass

func physics_update(_delta: float) -> void:
	if player == null:
		return
	
	var movement: Node = get_movement()
	if movement == null:
		return
	
	# Check combat triggers
	if Input.is_action_just_pressed(&"light_attack"):
		state_machine.change_state(&"Attack")
		return
	if Input.is_action_just_pressed(&"heavy_attack"):
		state_machine.change_state(&"HeavyAttack")
		return
	
	# Check defense triggers
	if Input.is_action_just_pressed(&"dodge"):
		state_machine.change_state(&"Dodge")
		return
	if Input.is_action_just_pressed(&"parry"):
		state_machine.change_state(&"Parry")
		return
	
	# Check jump trigger (buffered or just pressed)
	if movement.has_method("consume_jump_intent") and movement.call("consume_jump_intent"):
		state_machine.change_state(&"Jump")
		return
	
	# Check falling off floor
	if not player.is_on_floor():
		state_machine.change_state(&"Fall")
		return
	
	# Check movement intent
	var axis: float = movement.get("current_move_axis") if movement.get("current_move_axis") != null else 0.0
	if absf(axis) > 0.05:
		state_machine.change_state(&"Run")
