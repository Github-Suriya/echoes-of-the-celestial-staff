class_name BossPhaseTransitionState
extends BossState

## BossPhaseTransitionState
## Non-aggressive phase transition state.
## Cancels active attacks, deactivates hitboxes, plays readable stone resonance visual cues,
## updates combat parameters, and smoothly resumes combat.

var _timer: float = 0.0

func enter(_from_state: State = null) -> void:
	var duration: float = 1.8
	if boss != null and boss.boss_data != null:
		duration = boss.boss_data.phase_transition_duration
	_timer = duration
	
	if boss != null:
		boss.velocity.x = 0.0
		
		# Safely cancel active combat operations
		if boss.hitbox != null:
			boss.hitbox.deactivate()
		if boss.combat_controller != null:
			boss.combat_controller.reset_combat()
		if boss.telegraph_controller != null:
			boss.telegraph_controller.stop_telegraph()
		
		# Apply visuals
		var aura_col: Color = Color(0.2, 0.8, 1.0, 0.45)
		if boss.phase_controller != null and boss.phase_controller.current_phase_data != null:
			aura_col = boss.phase_controller.current_phase_data.aura_color
		
		if boss.anim_controller != null:
			boss.anim_controller.play_phase_transition(aura_col, duration)

func physics_update(delta: float) -> void:
	if boss == null:
		return
	
	boss.apply_gravity(delta)
	boss.velocity.x = move_toward(boss.velocity.x, 0.0, 650.0 * delta)
	
	_timer -= delta
	if _timer <= 0.0:
		if boss.phase_controller != null:
			boss.phase_controller.complete_phase_transition()
			if boss.combat_controller != null and boss.phase_controller.current_phase_data != null:
				boss.combat_controller.set_phase_data(boss.phase_controller.current_phase_data)
		state_machine.change_state(&"Combat")

func physics_process_state(delta: float) -> void:
	physics_update(delta)
