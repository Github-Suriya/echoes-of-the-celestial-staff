class_name PlayerParryState
extends PlayerState

## PlayerParryState
## Active during staff parry deflection stance.
## Intercepts incoming attacks, triggering standard deflection or posture-breaking Perfect Parry.

func enter() -> void:
	var defense: DefenseController = _get_defense_controller()
	if defense != null:
		defense.start_parry()

func physics_update(delta: float) -> void:
	if player == null:
		return
	
	if not player.is_on_floor():
		player.velocity.y += 980.0 * delta
	
	var defense: DefenseController = _get_defense_controller()
	if defense != null:
		var still_parrying: bool = defense.process_parry(delta)
		if not still_parrying:
			_return_to_locomotion()

func exit() -> void:
	var defense: DefenseController = _get_defense_controller()
	if defense != null and defense.is_parrying:
		defense.cancel_defense()

func _return_to_locomotion() -> void:
	if player == null or state_machine == null:
		return
	
	if not player.is_on_floor():
		state_machine.change_state(&"Fall")
		return
	
	var axis: float = Input.get_axis(&"move_left", &"move_right")
	if absf(axis) > 0.05:
		state_machine.change_state(&"Run")
	else:
		state_machine.change_state(&"Idle")

func _get_defense_controller() -> DefenseController:
	if player != null and player.has_node("Components/DefenseController"):
		return player.get_node("Components/DefenseController") as DefenseController
	return null
