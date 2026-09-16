class_name PlayerAttackState
extends PlayerState

## PlayerAttackState
## Active during light attack combo sequences.
## Handles forward friction, combat timer progression, and transition back to locomotion.

func enter() -> void:
	var combat: CombatController = _get_combat_controller()
	if combat != null:
		combat.start_light_attack()

func physics_update(delta: float) -> void:
	if player == null:
		return
	
	# Apply gravity if airborne during attack
	if not player.is_on_floor():
		player.velocity.y += 980.0 * delta
	
	# Apply ground deceleration to forward attack step
	player.velocity.x = move_toward(player.velocity.x, 0.0, 750.0 * delta)
	player.move_and_slide()
	
	var combat: CombatController = _get_combat_controller()
	if combat != null:
		var still_attacking: bool = combat.process_combat(delta)
		
		# Check branching to HeavyAttack if heavy attack was buffered
		if combat.has_buffered_attack and combat.buffered_is_heavy:
			combat.has_buffered_attack = false
			state_machine.change_state(&"HeavyAttack")
			return
		
		if not still_attacking:
			_return_to_locomotion()

func exit() -> void:
	var combat: CombatController = _get_combat_controller()
	if combat != null and combat.is_attacking():
		combat.cancel_combat()

func _return_to_locomotion() -> void:
	if player == null or state_machine == null:
		return
	
	if not player.is_on_floor():
		state_machine.change_state(&"Fall")
		return
	
	var movement: Node = get_movement()
	var axis: float = 0.0
	if movement != null and movement.get("current_move_axis") != null:
		axis = movement.get("current_move_axis")
	else:
		axis = Input.get_axis(&"move_left", &"move_right")
	
	if absf(axis) > 0.05:
		state_machine.change_state(&"Run")
	else:
		state_machine.change_state(&"Idle")

func _get_combat_controller() -> CombatController:
	if player != null and player.has_node("Components/CombatController"):
		return player.get_node("Components/CombatController") as CombatController
	return null
