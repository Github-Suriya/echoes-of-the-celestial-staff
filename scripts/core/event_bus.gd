extends Node

## EventBus
## Centralized, decoupled signal broker for Echoes of the Celestial Staff.
## Registered as global Autoload singleton "EventBus".

# --- Game Lifecycle Signals ---
signal game_state_changed(old_state: int, new_state: int)
signal game_paused(is_paused: bool)
signal game_resumed()

# --- Player Domain Signals ---
signal player_spawned(player: Node2D)
signal player_died()
signal player_health_changed(current_health: float, max_health: float)
signal player_stamina_changed(current_stamina: float, max_stamina: float)
signal player_spirit_changed(current_spirit: float, max_spirit: float)
signal player_stance_changed(new_stance_id: StringName)

# --- Combat Domain Signals ---
signal damage_dealt(target: Node2D, amount: float, is_critical: bool)
signal damage_received(victim: Node2D, amount: float)
signal poise_broken(target: Node2D)
signal hitstop_requested(duration_frames: int)
signal screen_shake_requested(trauma: float, duration: float)

# --- Defensive Combat Signals ---
signal dodge_started(entity: Node2D, direction: int)
signal dodge_completed(entity: Node2D)
signal perfect_dodge(entity: Node2D, attacker: Node2D)
signal parry_started(entity: Node2D)
signal parry_success(defender: Node2D, attacker: Node2D)
signal perfect_parry(defender: Node2D, attacker: Node2D)
signal attack_interrupted(target: Node2D, reason: StringName)

# --- Enemy & Boss Domain Signals ---
signal enemy_spawned(enemy: Node2D)
signal enemy_staggered(enemy: Node2D)
signal enemy_died(enemy: Node2D, bounty_qi: int)
signal boss_started(boss_name: String)
signal boss_phase_changed(boss_name: String, phase_index: int)
signal boss_defeated(boss_name: String)
signal boss_arena_locked()
signal boss_arena_unlocked()
signal boss_staggered(boss_name: String)
signal boss_attack_interrupted(boss_name: String)

# --- Transformation Domain Signals ---
signal transformation_started(transformation_id: StringName, duration: float)
signal transformation_ended(transformation_id: StringName)
signal transformation_state_changed(new_state: int)

# --- World & Progression Domain Signals ---
signal scene_loaded(scene_path: String)
signal scene_unloaded(scene_path: String)
signal checkpoint_activated(checkpoint_id: String)
signal ability_unlocked(ability_id: String)

func _ready() -> void:
	if is_inside_tree() and has_node("/root/DebugManager"):
		var dm: Node = get_node("/root/DebugManager")
		if dm != null and dm.has_method("log_info"):
			dm.log_info("EventBus initialized with core domain signals.", "EVENT_BUS")
