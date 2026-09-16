class_name PlayerSpiritAbilityState
extends PlayerState

## PlayerSpiritAbilityState
## Active during Spirit Ability casting (Startup, Active, and Recovery).
## Processes ability frames and returns cleanly to locomotion upon completion.

func enter() -> void:
	if player == null and owner is CharacterBody2D:
		player = owner as CharacterBody2D

func physics_update(delta: float) -> void:
	if player == null:
		return
	
	var ability_ctrl: SpiritAbilityController = _get_ability_controller()
	if ability_ctrl == null:
		_return_to_locomotion()
		return
	
	# Allow cancellation into Dodge or Parry during recovery phase
	if ability_ctrl.current_phase == SpiritAbilityController.AbilityPhase.RECOVERY:
		if has_node("/root/InputManager"):
			var im: Node = get_node("/root/InputManager")
			if im != null and im.has_method("is_action_just_pressed"):
				if im.is_action_just_pressed(&"dodge"):
					state_machine.change_state(&"Dodge")
					return
				elif im.is_action_just_pressed(&"parry"):
					state_machine.change_state(&"Parry")
					return
	
	var still_casting: bool = ability_ctrl.process_ability(delta)
	if not still_casting:
		_return_to_locomotion()

func exit() -> void:
	var ability_ctrl: SpiritAbilityController = _get_ability_controller()
	if ability_ctrl != null and ability_ctrl.is_casting:
		ability_ctrl.cancel_ability()

func _return_to_locomotion() -> void:
	if state_machine == null or player == null:
		return
	
	if not player.is_on_floor():
		state_machine.change_state(&"Fall")
		return
	
	var movement: Node = get_movement()
	if movement != null and "current_move_axis" in movement and absf(movement.current_move_axis) > 0.05:
		state_machine.change_state(&"Run")
	else:
		state_machine.change_state(&"Idle")

func _get_ability_controller() -> SpiritAbilityController:
	if player != null and player.has_node("Components/SpiritAbilityController"):
		return player.get_node("Components/SpiritAbilityController") as SpiritAbilityController
	return null
