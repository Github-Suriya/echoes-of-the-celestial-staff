class_name PlayerAirAttackState
extends PlayerState

## PlayerAirAttackState
## Active during airborne staff strikes (Celestial Falling Strike).
## Applies controlled aerial glide and transitions to Land upon floor contact or Fall upon completion.

func enter() -> void:
	var combat: CombatController = _get_combat_controller()
	if combat != null:
		combat.start_air_attack()

func physics_update(delta: float) -> void:
	if player == null:
		return
	
	# Ground landing immediately truncates aerial attack into Land
	if player.is_on_floor():
		var combat: CombatController = _get_combat_controller()
		if combat != null:
			combat.finish_combat()
		state_machine.change_state(&"Land")
		return
	
	# Controlled downward glide with mild gravity
	player.velocity.y = minf(420.0, player.velocity.y + 600.0 * delta)
	player.velocity.x = move_toward(player.velocity.x, 0.0, 180.0 * delta)
	player.move_and_slide()
	
	var combat: CombatController = _get_combat_controller()
	if combat != null:
		var still_attacking: bool = combat.process_combat(delta)
		if not still_attacking:
			state_machine.change_state(&"Fall")

func exit() -> void:
	var combat: CombatController = _get_combat_controller()
	if combat != null and combat.is_attacking():
		combat.cancel_combat()

func _get_combat_controller() -> CombatController:
	if player != null and player.has_node("Components/CombatController"):
		return player.get_node("Components/CombatController") as CombatController
	return null
