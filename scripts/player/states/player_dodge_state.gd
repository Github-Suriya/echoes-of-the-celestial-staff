class_name PlayerDodgeState
extends PlayerState

## PlayerDodgeState
## Active during ground evasion/dodge maneuver.
## Grants combat damage invulnerability while maintaining physical environment collisions.

func enter() -> void:
	var defense: DefenseController = _get_defense_controller()
	if defense != null:
		var axis: float = 0.0
		var movement: Node = get_movement()
		if movement != null and movement.get("current_move_axis") != null:
			axis = movement.get("current_move_axis")
		else:
			axis = Input.get_axis(&"move_left", &"move_right")
		
		var facing: int = player.get_facing_direction() if player != null and player.has_method("get_facing_direction") else 1
		defense.start_dodge(axis, facing)

func physics_update(delta: float) -> void:
	if player == null:
		return
	
	# Apply gravity if airborne or rolling off small ledge
	if not player.is_on_floor():
		player.velocity.y += 980.0 * delta
	
	var defense: DefenseController = _get_defense_controller()
	if defense != null:
		var still_dodging: bool = defense.process_dodge(delta)
		if not still_dodging:
			_return_to_locomotion()

func exit() -> void:
	var defense: DefenseController = _get_defense_controller()
	if defense != null and defense.is_dodging:
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
