class_name PlayerHeavyAttackState
extends PlayerState

## PlayerHeavyAttackState
## Active during heavy attack execution.
## High commitment strike with no combo branching, leading directly back to locomotion.

func enter() -> void:
	var combat: CombatController = _get_combat_controller()
	if combat != null:
		if Input.is_action_pressed(&"heavy_attack"):
			combat.start_heavy_charge()
		else:
			combat.start_heavy_attack()

func physics_update(delta: float) -> void:
	if player == null:
		return
	
	if not player.is_on_floor():
		player.velocity.y += 980.0 * delta
	
	player.velocity.x = move_toward(player.velocity.x, 0.0, 750.0 * delta)
	player.move_and_slide()
	
	var combat: CombatController = _get_combat_controller()
	if combat != null:
		# If in charging phase
		if combat.is_charging_heavy:
			# Allow dodge / parry out of charge
			if Input.is_action_just_pressed(&"dodge"):
				combat.cancel_combat()
				state_machine.change_state(&"Dodge")
				return
			if Input.is_action_just_pressed(&"parry"):
				combat.cancel_combat()
				state_machine.change_state(&"Parry")
				return
			
			if not Input.is_action_pressed(&"heavy_attack"):
				combat.release_heavy_attack()
			else:
				combat.update_heavy_charge(delta)
				var attack_data: AttackData = combat.get_current_attack()
				if attack_data != null and combat.charge_timer >= attack_data.maximum_charge_time:
					combat.release_heavy_attack()
			return
		
		# Check cancellation into Dodge or Parry during recovery phase
		if combat.can_cancel_attack():
			if Input.is_action_just_pressed(&"dodge"):
				state_machine.change_state(&"Dodge")
				return
			if Input.is_action_just_pressed(&"parry"):
				state_machine.change_state(&"Parry")
				return
		
		var still_attacking: bool = combat.process_combat(delta)
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
