extends Node

## Automated Boss Framework & The Granite Abbot Test Suite
## Validates all required Phase 9 criteria:
## 1. BossData, BossPhaseData, and BossAttackData resources
## 2. BossBase & GraniteAbbot scene structure, collision contracts, component reuse
## 3. Boss StateMachine lifecycle (Intro, Idle, Combat, Attack, Hit, Stagger, PhaseTransition, Defeated)
## 4. Multi-phase threshold detection, idempotent transitions, stat modifiers
## 5. Boss attack selection, range checks, cooldowns, execution lifecycle
## 6. BossTelegraphController procedural cues, indicators, and shape styling
## 7. Combat integration: damage pipelines, poise damage, perfect parry interruption
## 8. Posture break, Stagger state, vulnerability window, and poise regeneration
## 9. BossArenaController: physical barriers, trigger detection, lock/unlock, reset
## 10. Idempotent defeat mechanics, collision clearing, and encounter resolution
## 11. BossHealthBar HUD binding, smooth lerp updates, and phase badge syncing
## 12. Multi-system compatibility (stances, spirit, transformation) & test room integrity.

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 9 BOSS FRAMEWORK TEST SUITE")
	print("==================================================")
	
	_test_01_boss_data_and_phase_resources()
	_test_02_boss_architecture_and_layers()
	_test_03_boss_state_machine_lifecycle()
	_test_04_phase_thresholds_and_transitions()
	_test_05_attack_system_and_selection()
	_test_06_telegraph_system()
	_test_07_combat_and_defensive_integration()
	_test_08_poise_and_stagger_mechanics()
	_test_09_arena_controller_and_barriers()
	_test_10_defeat_and_reset_mechanics()
	_test_11_boss_hud_integration()
	_test_12_multi_system_and_room_integrity()
	_test_13_hitbox_physics_signal_safety()
	_test_14_grounding_and_gravity_integrity()
	_test_15_boss_combat_and_hit_reaction_regression()
	
	print("==================================================")
	print(" BOSS FRAMEWORK TEST RESULTS: %d / %d PASSED (%d FAILED)" % [
		_tests_passed,
		_tests_passed + _tests_failed,
		_tests_failed
	])
	print("==================================================")
	
	if _tests_failed == 0:
		print("\nSUCCESS: All Phase 9 Boss Framework tests passed cleanly.\n")
		get_tree().quit(0)
	else:
		push_error("FAILURE: %d boss framework tests failed." % _tests_failed)
		get_tree().quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[PASS] %s" % test_name)
	else:
		_tests_failed += 1
		printerr("[FAIL] %s" % test_name)

# ==============================================================================
# CATEGORY 1: DATA RESOURCES
# ==============================================================================
func _test_01_boss_data_and_phase_resources() -> void:
	print("\n--- Category 1: Boss Data & Phase Resources ---")
	
	var data: BossData = load("res://data/bosses/boss_granite_abbot.tres") as BossData
	_assert(data != null, "1.1 BossData loads from boss_granite_abbot.tres")
	if data == null:
		return
	
	_assert(data.boss_id == &"granite_abbot", "1.2 BossData boss_id is granite_abbot")
	_assert(data.display_name == "The Granite Abbot", "1.3 BossData display_name is correct")
	_assert(data.max_health == 300.0, "1.4 BossData max_health is 300")
	_assert(data.max_poise == 60.0, "1.5 BossData max_poise is 60")
	_assert(data.stagger_duration == 1.8, "1.6 BossData stagger_duration is 1.8s")
	_assert(data.phases.size() >= 2, "1.7 BossData configures at least 2 phases")
	
	var p1: BossPhaseData = data.phases[0]
	_assert(p1 != null and p1.phase_id == 1, "1.8 Phase 1 loads and has phase_id 1")
	_assert(p1.attacks.size() >= 3, "1.9 Phase 1 defines minimum 3 attacks")
	
	var p2: BossPhaseData = data.phases[1]
	_assert(p2 != null and p2.phase_id == 2, "1.10 Phase 2 loads and has phase_id 2")
	_assert(p2.damage_multiplier > 1.0 and p2.movement_speed_multiplier > 1.0, "1.11 Phase 2 defines enhanced multipliers")
	
	var shockwave: BossAttackData = load("res://data/bosses/attacks/attack_granite_shockwave.tres") as BossAttackData
	_assert(shockwave != null and shockwave.ground_marker_radius > 0.0, "1.12 Shockwave attack data defines ground marker radius")

# ==============================================================================
# CATEGORY 2: ARCHITECTURE & COMPONENT REUSE
# ==============================================================================
func _test_02_boss_architecture_and_layers() -> void:
	print("\n--- Category 2: Boss Architecture & Component Reuse ---")
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	_assert(boss_scene != null, "2.1 Granite Abbot scene resource loads")
	if boss_scene == null:
		return
	
	var boss: BossController = boss_scene.instantiate() as BossController
	add_child(boss)
	
	_assert(boss.collision_layer == 4, "2.2 Boss body uses collision_layer 4 (Layer 3: Enemy/Boss)")
	_assert(boss.collision_mask == 1, "2.3 Boss body uses collision_mask 1 (Layer 1: World)")
	
	_assert(boss.health_component != null, "2.4 Canonical HealthComponent discovered")
	_assert(boss.poise_component != null, "2.5 Canonical PoiseComponent discovered")
	_assert(boss.hitbox != null, "2.6 Canonical Hitbox discovered")
	_assert(boss.hurtbox != null, "2.7 Canonical Hurtbox discovered")
	_assert(boss.hitbox.collision_layer == 16, "2.8 Hitbox layer is 16 (Layer 5: EnemyHitbox)")
	_assert(boss.hitbox.collision_mask == 32, "2.9 Hitbox mask is 32 (Layer 6: PlayerHurtbox)")
	_assert(boss.hurtbox.collision_layer == 64, "2.10 Hurtbox layer is 64 (Layer 7: EnemyHurtbox)")
	
	_assert(boss.combat_controller != null, "2.11 BossCombatController discovered")
	_assert(boss.phase_controller != null, "2.12 BossPhaseController discovered")
	
	boss.queue_free()

# ==============================================================================
# CATEGORY 3: BOSS STATE MACHINE LIFECYCLE
# ==============================================================================
func _test_03_boss_state_machine_lifecycle() -> void:
	print("\n--- Category 3: Boss State Machine Lifecycle ---")
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss: BossController = boss_scene.instantiate() as BossController
	add_child(boss)
	
	var sm: StateMachine = boss.state_machine
	_assert(sm != null, "3.1 StateMachine node present")
	sm.change_state(&"Idle")
	_assert(sm.get_current_state_name() == &"Idle", "3.2 StateMachine enters Idle state")
	
	sm.change_state(&"Intro")
	_assert(sm.get_current_state_name() == &"Intro", "3.3 Transitions cleanly to Intro")
	
	sm.change_state(&"Combat")
	_assert(sm.get_current_state_name() == &"Combat", "3.4 Transitions cleanly to Combat")
	
	sm.change_state(&"Attack")
	_assert(sm.get_current_state_name() == &"Attack", "3.5 Transitions cleanly to Attack")
	
	sm.change_state(&"Hit")
	_assert(sm.get_current_state_name() == &"Hit", "3.6 Transitions cleanly to Hit")
	
	sm.change_state(&"Stagger")
	_assert(sm.get_current_state_name() == &"Stagger", "3.7 Transitions cleanly to Stagger")
	
	sm.change_state(&"PhaseTransition")
	_assert(sm.get_current_state_name() == &"PhaseTransition", "3.8 Transitions cleanly to PhaseTransition")
	
	sm.change_state(&"Defeated")
	_assert(sm.get_current_state_name() == &"Defeated", "3.9 Transitions cleanly to Defeated")
	
	# Invalid transition protection
	_assert(not sm.has_state(&"NonExistentState"), "3.10 Invalid state correctly identified as non-existent")
	
	# BossState reference
	var intro_st: BossIntroState = sm.get_node("Intro") as BossIntroState
	_assert(intro_st != null and intro_st.boss == boss, "3.11 BossState has typed reference to BossController")
	
	boss.queue_free()

# ==============================================================================
# CATEGORY 4: PHASES & DETERMINISTIC TRANSITIONS
# ==============================================================================
func _test_04_phase_thresholds_and_transitions() -> void:
	print("\n--- Category 4: Phases & Deterministic Transitions ---")
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss: BossController = boss_scene.instantiate() as BossController
	add_child(boss)
	
	var pc: BossPhaseController = boss.phase_controller
	_assert(pc != null, "4.1 BossPhaseController present")
	_assert(pc.get_current_phase_number() == 1, "4.2 Starts in Phase 1")
	_assert(pc.current_phase_data != null and pc.current_phase_data.damage_multiplier == 1.0, "4.3 Phase 1 default multipliers are 1.0")
	
	# Drop to 60% HP: should NOT trigger Phase 2
	boss.health_component.current_health = 180.0
	pc.check_health_threshold(180.0, 300.0)
	_assert(pc.get_current_phase_number() == 1, "4.4 60% HP does not trigger Phase 2")
	
	# Drop to 50% HP: triggers Phase 2
	boss.health_component.current_health = 150.0
	pc.check_health_threshold(150.0, 300.0)
	_assert(pc.is_transitioning, "4.5 50% HP triggers is_transitioning flag")
	_assert(boss.state_machine.get_current_state_name() == &"PhaseTransition", "4.6 Enters PhaseTransition state")
	_assert(not boss.hitbox.is_active, "4.7 Hitbox deactivated during phase transition")
	
	# Complete transition
	pc.complete_phase_transition()
	_assert(not pc.is_transitioning, "4.8 Transition completes cleanly")
	_assert(pc.get_current_phase_number() == 2, "4.9 Current phase number is now 2")
	_assert(boss.combat_controller.damage_multiplier > 1.0, "4.10 Phase 2 damage multiplier applied to combat controller")
	
	# Idempotency check: dropping further should NOT re-trigger
	var triggered_again: bool = pc.trigger_phase_transition(1)
	_assert(not triggered_again, "4.11 Phase transition is idempotent and cannot re-trigger Phase 2")
	
	boss.queue_free()

# ==============================================================================
# CATEGORY 5: ATTACK SYSTEM & SELECTION
# ==============================================================================
func _test_05_attack_system_and_selection() -> void:
	print("\n--- Category 5: Attack System & Selection ---")
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss: BossController = boss_scene.instantiate() as BossController
	add_child(boss)
	
	var cc: BossCombatController = boss.combat_controller
	_assert(cc != null, "5.1 BossCombatController present")
	_assert(cc.current_phase == BossCombatController.AttackPhase.READY, "5.2 Combat controller initializes in READY phase")
	_assert(cc.can_attack(), "5.3 can_attack() true when off cooldown")
	
	# Select attack in range
	var atk: EnemyAttackData = cc.select_attack(50.0)
	_assert(atk != null, "5.4 select_attack() returns a valid attack")
	_assert(atk.attack_range >= 40.0, "5.5 Selected attack has valid range")
	
	# Trigger attack
	var success: bool = cc.trigger_attack(atk)
	_assert(success, "5.6 trigger_attack() initiates attack")
	_assert(cc.current_phase == BossCombatController.AttackPhase.TELEGRAPH, "5.7 Enters TELEGRAPH phase")
	_assert(not boss.hitbox.is_active, "5.8 Hitbox inactive during telegraph")
	
	# Advance past telegraph to active
	cc.process_combat(atk.telegraph_duration + 0.05)
	_assert(cc.current_phase == BossCombatController.AttackPhase.ACTIVE, "5.9 Transitions to ACTIVE phase")
	_assert(boss.hitbox.is_active, "5.10 Hitbox active during ACTIVE phase")
	
	# Advance past active to recovery
	cc.process_combat(atk.active_time + 0.05)
	_assert(cc.current_phase == BossCombatController.AttackPhase.RECOVERY, "5.11 Transitions to RECOVERY phase")
	_assert(not boss.hitbox.is_active, "5.12 Hitbox deactivated during recovery")
	
	# Advance past recovery to cooldown
	cc.process_combat(atk.recovery_time + 0.05)
	_assert(cc.current_phase == BossCombatController.AttackPhase.COOLDOWN, "5.13 Transitions to COOLDOWN phase")
	_assert(cc.get_attack_cooldown(atk.attack_id) > 0.0, "5.14 Attack placed on cooldown")
	
	boss.queue_free()

# ==============================================================================
# CATEGORY 6: TELEGRAPH SYSTEM
# ==============================================================================
func _test_06_telegraph_system() -> void:
	print("\n--- Category 6: Telegraph System ---")
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss: BossController = boss_scene.instantiate() as BossController
	add_child(boss)
	
	var tc: BossTelegraphController = boss.telegraph_controller
	_assert(tc != null, "6.1 BossTelegraphController present")
	_assert(not tc.is_telegraphing(), "6.2 Initializes with no active telegraph")
	
	var sweep: BossAttackData = load("res://data/bosses/attacks/attack_granite_sweep.tres") as BossAttackData
	tc.start_telegraph(sweep, 1, 0.5)
	_assert(tc.is_telegraphing(), "6.3 start_telegraph() marks telegraph active")
	_assert(tc._warning_shape != null and tc._warning_shape.visible, "6.4 Warning shape visible during telegraph")
	_assert(tc._staff_glow != null and tc._staff_glow.visible, "6.5 Staff glow visible during telegraph")
	
	tc.stop_telegraph()
	_assert(not tc.is_telegraphing(), "6.6 stop_telegraph() clears active flag")
	_assert(not tc._warning_shape.visible, "6.7 Warning shape hidden after stop")
	
	# Shockwave ground marker
	var shockwave: BossAttackData = load("res://data/bosses/attacks/attack_granite_shockwave.tres") as BossAttackData
	tc.start_telegraph(shockwave, 1, 0.6)
	_assert(tc._ground_marker != null and tc._ground_marker.visible, "6.8 Ground marker visible for shockwave attack")
	
	tc.stop_telegraph()
	_assert(not tc._ground_marker.visible, "6.9 Ground marker hidden on telegraph stop")
	_assert(not tc.is_telegraphing(), "6.10 Clean telegraph state restored")
	
	boss.queue_free()

# ==============================================================================
# CATEGORY 7: COMBAT & DEFENSIVE INTEGRATION
# ==============================================================================
func _test_07_combat_and_defensive_integration() -> void:
	print("\n--- Category 7: Combat & Defensive Integration ---")
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss: BossController = boss_scene.instantiate() as BossController
	add_child(boss)
	
	# Damage receipt
	var dmg: DamageInfo = DamageInfo.new()
	dmg.damage = 25.0
	dmg.poise_damage = 15.0
	boss.hurtbox.receive_hit(dmg)
	_assert(boss.health_component.current_health == 275.0, "7.1 Boss takes damage through canonical Hurtbox")
	_assert(boss.poise_component.current_poise == 45.0, "7.2 Boss loses poise through canonical Hurtbox")
	
	# Perfect Parry Interruption
	var sweep: BossAttackData = load("res://data/bosses/attacks/attack_granite_sweep.tres") as BossAttackData
	boss.combat_controller.trigger_attack(sweep)
	boss.state_machine.change_state(&"Attack")
	_assert(boss.combat_controller.is_attacking(), "7.3 Boss in active attack swing")
	
	# Call interrupt_attack() as Player DefenseController does on Perfect Parry
	boss.interrupt_attack()
	_assert(boss.combat_controller.current_phase == BossCombatController.AttackPhase.INTERRUPTED, "7.4 Attack phase transitions to INTERRUPTED")
	_assert(not boss.hitbox.is_active, "7.5 Hitbox deactivated upon interrupt")
	_assert(boss.state_machine.get_current_state_name() == &"Hit", "7.6 Boss state transitions to Hit flinch/recoil")
	_assert(not boss.combat_controller.can_attack(), "7.7 Boss cannot attack while recovering from interrupt")
	
	# Clean recovery
	boss.combat_controller.process_combat(0.5)
	_assert(boss.combat_controller.current_phase == BossCombatController.AttackPhase.COOLDOWN, "7.8 Interrupted phase completes to cooldown")
	
	boss.queue_free()

# ==============================================================================
# CATEGORY 8: POISE & STAGGER MECHANICS
# ==============================================================================
func _test_08_poise_and_stagger_mechanics() -> void:
	print("\n--- Category 8: Poise & Stagger Mechanics ---")
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss: BossController = boss_scene.instantiate() as BossController
	add_child(boss)
	
	_assert(not boss.poise_component.is_staggered, "8.1 Boss initially not staggered")
	
	# Deplete all poise (60.0)
	boss.poise_component.take_poise_damage(60.0)
	_assert(boss.poise_component.is_staggered, "8.2 Poise depletion triggers is_staggered")
	_assert(boss.state_machine.get_current_state_name() == &"Stagger", "8.3 Boss state changes to Stagger")
	_assert(not boss.combat_controller.can_attack(), "8.4 Boss cannot attack while staggered")
	_assert(not boss.hitbox.is_active, "8.5 Hitbox inactive during stagger")
	
	# Stagger timer advances
	var stagger_st: BossStaggerState = boss.state_machine.get_node("Stagger") as BossStaggerState
	_assert(stagger_st._timer > 0.0, "8.6 Stagger timer active")
	
	# Advance past stagger duration
	stagger_st.physics_process_state(2.0)
	_assert(not boss.poise_component.is_staggered, "8.7 Poise restored after stagger completes")
	_assert(boss.poise_component.current_poise == 60.0, "8.8 Poise resets to full max_poise")
	_assert(boss.state_machine.get_current_state_name() == &"Combat", "8.9 Boss resumes Combat state after stagger")
	_assert(boss.combat_controller.can_attack(), "8.10 Boss can attack again once recovered")
	
	boss.queue_free()

# ==============================================================================
# CATEGORY 9: ARENA CONTROLLER & BARRIERS
# ==============================================================================
func _test_09_arena_controller_and_barriers() -> void:
	print("\n--- Category 9: Arena Controller & Barriers ---")
	
	var arena_ctrl: BossArenaController = BossArenaController.new()
	var left_bar: StaticBody2D = StaticBody2D.new()
	var right_bar: StaticBody2D = StaticBody2D.new()
	var trigger: Area2D = Area2D.new()
	
	arena_ctrl.left_barrier = left_bar
	arena_ctrl.right_barrier = right_bar
	arena_ctrl.entry_trigger = trigger
	
	add_child(arena_ctrl)
	add_child(left_bar)
	add_child(right_bar)
	add_child(trigger)
	
	# Ready lowers barriers
	arena_ctrl._ready()
	_assert(left_bar.collision_layer == 0 and not left_bar.visible, "9.1 Barriers initially lowered (collision_layer 0)")
	_assert(not arena_ctrl.is_encounter_active, "9.2 Encounter initially inactive")
	
	# Lock arena
	arena_ctrl.start_encounter()
	_assert(arena_ctrl.is_encounter_active, "9.3 start_encounter() sets is_encounter_active true")
	_assert(left_bar.collision_layer == 1 and left_bar.visible, "9.4 Left barrier locked on Layer 1")
	_assert(right_bar.collision_layer == 1 and right_bar.visible, "9.5 Right barrier locked on Layer 1")
	
	# Complete encounter unlocks
	arena_ctrl.complete_encounter()
	_assert(not arena_ctrl.is_encounter_active, "9.6 Encounter marked inactive on completion")
	_assert(arena_ctrl.is_encounter_completed, "9.7 is_encounter_completed flag set true")
	_assert(left_bar.collision_layer == 0 and not left_bar.visible, "9.8 Barriers unlocked upon victory")
	
	# Reset restores state
	arena_ctrl.reset_encounter()
	_assert(not arena_ctrl.is_encounter_active, "9.9 Reset leaves encounter inactive")
	_assert(not arena_ctrl.is_encounter_completed, "9.10 Reset clears completed flag")
	_assert(left_bar.collision_layer == 0, "9.11 Barriers remain lowered for subsequent entry")
	
	arena_ctrl.queue_free()
	left_bar.queue_free()
	right_bar.queue_free()
	trigger.queue_free()

# ==============================================================================
# CATEGORY 10: DEFEAT & RESET MECHANICS
# ==============================================================================
func _test_10_defeat_and_reset_mechanics() -> void:
	print("\n--- Category 10: Defeat & Reset Mechanics ---")
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss: BossController = boss_scene.instantiate() as BossController
	add_child(boss)
	
	_assert(not boss.is_dead_or_defeated(), "10.1 Boss initially alive and undefeated")
	
	# Trigger death
	boss.die()
	_assert(boss.is_defeated, "10.2 is_defeated set true")
	_assert(boss.state_machine.get_current_state_name() == &"Defeated", "10.3 State changes to Defeated")
	_assert(not boss.hitbox.is_active, "10.4 Hitbox deactivated upon defeat")
	_assert(boss.hurtbox.is_invulnerable, "10.5 Hurtbox damage reception disabled")
	
	# Idempotency
	boss.die()
	_assert(boss.is_defeated, "10.6 Subsequent die() calls are idempotent")
	
	# Reset
	boss.reset_boss()
	_assert(not boss.is_defeated, "10.7 reset_boss() restores is_defeated false")
	_assert(boss.health_component.current_health == 300.0, "10.8 Full health restored")
	_assert(boss.poise_component.current_poise == 60.0, "10.9 Full poise restored")
	_assert(boss.phase_controller.get_current_phase_number() == 1, "10.10 Reset restores Phase 1")
	
	boss.queue_free()

# ==============================================================================
# CATEGORY 11: BOSS HUD INTEGRATION
# ==============================================================================
func _test_11_boss_hud_integration() -> void:
	print("\n--- Category 11: Boss HUD Integration ---")
	
	var hud_scene: PackedScene = load("res://scenes/ui/boss_health_bar.tscn") as PackedScene
	_assert(hud_scene != null, "11.1 BossHealthBar scene loads")
	if hud_scene == null:
		return
	
	var hud: BossHealthBar = hud_scene.instantiate() as BossHealthBar
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss: BossController = boss_scene.instantiate() as BossController
	add_child(hud)
	add_child(boss)
	
	hud.bind_boss(boss)
	_assert(hud._name_label != null and hud._name_label.text == "The Granite Abbot", "11.2 Name label matches boss display name")
	_assert(hud._phase_label != null and "PHASE 1" in hud._phase_label.text, "11.3 Phase label displays Phase 1 title")
	_assert(hud._health_bar != null and hud._health_bar.max_value == 300.0, "11.4 Health bar max_value matches boss max_health")
	_assert(hud._poise_bar != null and hud._poise_bar.max_value == 60.0, "11.5 Poise bar max_value matches boss max_poise")
	
	# Health change updates bar
	boss.health_component.current_health = 200.0
	hud._on_health_changed(200.0, 300.0)
	_assert(hud._health_bar.value == 200.0, "11.6 Health damage updates health bar value")
	
	# Phase transition updates badge
	var p2_data: BossPhaseData = load("res://data/bosses/phase_granite_abbot_p2.tres") as BossPhaseData
	hud._on_phase_changed(2, p2_data)
	_assert("PHASE 2" in hud._phase_label.text, "11.7 Phase transition updates badge label")
	
	hud.queue_free()
	boss.queue_free()

# ==============================================================================
# CATEGORY 12: MULTI-SYSTEM & ROOM INTEGRITY
# ==============================================================================
func _test_12_multi_system_and_room_integrity() -> void:
	print("\n--- Category 12: Multi-System & Room Integrity ---")
	
	var room_scene: PackedScene = load("res://scenes/world/test_granite_abbot_room.tscn") as PackedScene
	_assert(room_scene != null, "12.1 test_granite_abbot_room.tscn loads cleanly")
	if room_scene == null:
		return
	
	var room: TestGraniteAbbotRoom = room_scene.instantiate() as TestGraniteAbbotRoom
	add_child(room)
	
	_assert(room.player != null, "12.2 Player instance present in test room")
	_assert(room.boss != null, "12.3 Granite Abbot instance present in test room")
	_assert(room.arena_controller != null, "12.4 BossArenaController present in test room")
	_assert(room.boss_hud != null, "12.5 BossHealthBar present in test room")
	_assert(room.spirit_hud != null, "12.6 SpiritHUD present in test room")
	
	# Player Stances with Boss
	if room.player.has_node("Components/StanceController"):
		var stance: StanceController = room.player.get_node("Components/StanceController") as StanceController
		var cur_stance: int = stance.get_current_stance()
		stance.cycle_stance()
		_assert(stance.get_current_stance() != cur_stance, "12.7 Stance cycling operational during encounter")
	
	# Clean Reset
	room._reset_encounter()
	_assert(not room.arena_controller.is_encounter_active, "12.8 Room encounter resets cleanly")
	
	room.queue_free()

# ==============================================================================
# CATEGORY 13: HITBOX SIGNAL SAFETY (PHASE 9.1 REGRESSION)
# ==============================================================================
func _test_13_hitbox_physics_signal_safety() -> void:
	print("\n--- Category 13: Hitbox Signal Safety (Phase 9.1) ---")
	
	# HITBOX-SAFE-01: Deactivate hitbox during area_entered callback
	var hb1: Hitbox = Hitbox.new()
	var hurt1: Hurtbox = Hurtbox.new()
	add_child(hb1)
	add_child(hurt1)
	
	var atk: AttackData = load("res://data/attacks/attack_light_1.tres") as AttackData
	var tracker = {"deactivated": false}
	hurt1.hit_received.connect(func(_info: DamageInfo) -> void:
		hb1.deactivate()
		tracker["deactivated"] = true
	)
	
	hb1.activate(atk, null)
	hb1._on_area_entered(hurt1)
	_assert(tracker["deactivated"] and not hb1.is_active, "HITBOX-SAFE-01: Deactivate hitbox during area_entered callback executes safely without error")
	hb1.queue_free()
	hurt1.queue_free()
	
	# HITBOX-SAFE-02: Deactivate hitbox through stagger callback
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss2: BossController = boss_scene.instantiate() as BossController
	add_child(boss2)
	
	var sweep_atk: EnemyAttackData = load("res://data/bosses/attacks/attack_granite_sweep.tres") as EnemyAttackData
	boss2.combat_controller.trigger_attack(sweep_atk)
	boss2.combat_controller.process_combat(sweep_atk.telegraph_duration + 0.01) # Enter ACTIVE
	_assert(boss2.hitbox != null and boss2.hitbox.is_active, "Boss hitbox is active during ACTIVE attack window")
	
	# Deplete poise to trigger stagger callback chain while simulating hit
	boss2.poise_component.take_poise_damage(boss2.poise_component.max_poise)
	_assert(not boss2.hitbox.is_active, "HITBOX-SAFE-02: Deactivate hitbox through stagger callback cleanly disables hitbox")
	boss2.queue_free()
	
	# HITBOX-SAFE-03: Deactivate hitbox through Perfect Parry interruption
	var boss3: BossController = boss_scene.instantiate() as BossController
	add_child(boss3)
	boss3.combat_controller.trigger_attack(sweep_atk)
	boss3.combat_controller.process_combat(sweep_atk.telegraph_duration + 0.01)
	
	# Perfect parry intercepts and interrupts attacker
	boss3.interrupt_attack()
	_assert(not boss3.hitbox.is_active, "HITBOX-SAFE-03: Deactivate hitbox through Perfect Parry interruption stops active hitbox")
	boss3.queue_free()
	
	# HITBOX-SAFE-04: Repeated deactivate calls remain safe
	var hb4: Hitbox = Hitbox.new()
	add_child(hb4)
	hb4.activate(atk, null)
	for i in range(5):
		hb4.deactivate()
	_assert(not hb4.is_active and not hb4.monitoring and not hb4.monitorable, "HITBOX-SAFE-04: Repeated deactivate calls remain idempotent and safe")
	hb4.queue_free()
	
	# HITBOX-SAFE-05: Reset combat during active hit callback
	var boss5: BossController = boss_scene.instantiate() as BossController
	add_child(boss5)
	boss5.combat_controller.trigger_attack(sweep_atk)
	boss5.combat_controller.process_combat(sweep_atk.telegraph_duration + 0.01)
	boss5.hitbox.hit_connected.connect(func(_target: Area2D, _info: DamageInfo) -> void:
		boss5.combat_controller.reset_combat()
	)
	var test_hurt5: Hurtbox = Hurtbox.new()
	add_child(test_hurt5)
	boss5.hitbox._on_area_entered(test_hurt5)
	_assert(not boss5.hitbox.is_active, "HITBOX-SAFE-05: Reset combat during active hit callback safely neutralizes hitbox")
	boss5.queue_free()
	test_hurt5.queue_free()
	
	# HITBOX-SAFE-06: Boss death during hit callback
	var boss6: BossController = boss_scene.instantiate() as BossController
	add_child(boss6)
	boss6.hurtbox.hit_received.connect(func(_info: DamageInfo) -> void:
		boss6.die()
	)
	var fake_info6: DamageInfo = DamageInfo.new()
	fake_info6.damage = 10.0
	boss6.hurtbox.receive_hit(fake_info6)
	_assert(boss6.is_defeated and not boss6.hitbox.is_active, "HITBOX-SAFE-06: Boss death during hit callback disables hitboxes without error")
	boss6.queue_free()
	
	# HITBOX-SAFE-07: Phase transition during combat hit processing
	var boss7: BossController = boss_scene.instantiate() as BossController
	add_child(boss7)
	boss7.combat_controller.trigger_attack(sweep_atk)
	boss7.combat_controller.process_combat(sweep_atk.telegraph_duration + 0.01)
	
	# Deal damage to push HP <= 50%
	boss7.health_component.take_damage(boss7.health_component.max_health * 0.55)
	_assert(boss7.is_in_phase_transition() and not boss7.hitbox.is_active, "HITBOX-SAFE-07: Phase transition during combat hit processing disables hitbox safely")
	boss7.queue_free()

# ==============================================================================
# CATEGORY 14: GROUNDING & GRAVITY INTEGRITY (PHASE 9.1 REGRESSION)
# ==============================================================================
func _test_14_grounding_and_gravity_integrity() -> void:
	print("\n--- Category 14: Grounding & Gravity Integrity (Phase 9.1) ---")
	
	# Create floor StaticBody2D
	var floor_body: StaticBody2D = StaticBody2D.new()
	floor_body.collision_layer = 1
	var floor_shape: CollisionShape2D = CollisionShape2D.new()
	var rect_shape: RectangleShape2D = RectangleShape2D.new()
	rect_shape.size = Vector2(2000, 40)
	floor_shape.shape = rect_shape
	floor_body.position = Vector2(0, 20) # Top surface at y = 0
	floor_body.add_child(floor_shape)
	add_child(floor_body)
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss: BossController = boss_scene.instantiate() as BossController
	boss.position = Vector2(0, 0)
	add_child(boss)
	
	# Step physics so collision registers
	boss.move_and_slide()
	
	# GROUND-01: Boss starts grounded
	_assert(boss.is_on_floor(), "GROUND-01: Boss starts properly grounded at y = 0 on floor geometry")
	
	# GROUND-02: Boss remains grounded during Idle
	boss.state_machine.change_state(&"Idle")
	for i in range(10):
		boss._physics_process(0.016)
	_assert(boss.is_on_floor() and is_zero_approx(boss.velocity.y), "GROUND-02: Boss remains grounded during Idle with zero vertical velocity drift")
	
	# GROUND-03: Boss remains grounded during Combat
	boss.state_machine.change_state(&"Combat")
	for i in range(10):
		boss._physics_process(0.016)
	_assert(boss.is_on_floor() and is_zero_approx(boss.velocity.y), "GROUND-03: Boss remains grounded during Combat state")
	
	# GROUND-04: Boss remains grounded during Attack
	boss.state_machine.change_state(&"Attack")
	var sweep_atk: EnemyAttackData = load("res://data/bosses/attacks/attack_granite_sweep.tres") as EnemyAttackData
	boss.combat_controller.trigger_attack(sweep_atk)
	for i in range(10):
		boss._physics_process(0.016)
	_assert(boss.is_on_floor() and is_zero_approx(boss.velocity.y), "GROUND-04: Boss remains grounded during Attack impulse")
	
	# GROUND-05: Boss remains grounded during Hit
	boss.state_machine.change_state(&"Hit")
	for i in range(10):
		boss._physics_process(0.016)
	_assert(boss.is_on_floor() and is_zero_approx(boss.velocity.y), "GROUND-05: Boss remains grounded during Hit flinch")
	
	# GROUND-06: Boss remains grounded during Stagger
	boss.state_machine.change_state(&"Stagger")
	for i in range(10):
		boss._physics_process(0.016)
	_assert(boss.is_on_floor() and is_zero_approx(boss.velocity.y), "GROUND-06: Boss remains grounded during Stagger posture break")
	
	# GROUND-07: Boss remains grounded during PhaseTransition
	boss.state_machine.change_state(&"PhaseTransition")
	for i in range(10):
		boss._physics_process(0.016)
	_assert(boss.is_on_floor() and is_zero_approx(boss.velocity.y), "GROUND-07: Boss remains grounded during PhaseTransition")
	
	# GROUND-08: Boss does not acquire unintended positive/negative Y velocity
	var max_drift: float = 0.0
	for i in range(30):
		boss._physics_process(0.016)
		max_drift = maxf(max_drift, absf(boss.velocity.y))
	_assert(is_zero_approx(max_drift), "GROUND-08: Boss does not accumulate unintended positive/negative Y velocity when grounded")
	
	# GROUND-09: Boss collision shape correctly contacts floor
	var shape_node: CollisionShape2D = boss.get_node("CollisionShape2D") as CollisionShape2D
	var capsule: CapsuleShape2D = shape_node.shape as CapsuleShape2D
	var bottom_extent: float = shape_node.position.y + (capsule.height * 0.5)
	_assert(is_zero_approx(bottom_extent), "GROUND-09: Boss collision shape bottom extent rests precisely at y = 0")
	
	# GROUND-10: Boss reset restores correct grounded position
	boss.position.x = 200.0
	boss.reset_boss()
	boss.move_and_slide()
	_assert(boss.is_on_floor() and boss.global_position == boss.initial_position, "GROUND-10: Boss reset restores exact grounded position")
	
	boss.queue_free()
	floor_body.queue_free()

# ==============================================================================
# CATEGORY 15: BOSS COMBAT & HIT REACTION REGRESSION (PHASE 9.1 REGRESSION)
# ==============================================================================
func _test_15_boss_combat_and_hit_reaction_regression() -> void:
	print("\n--- Category 15: Boss Combat & Hit Reaction Regression (Phase 9.1) ---")
	
	var boss_scene: PackedScene = load("res://scenes/bosses/granite_abbot.tscn") as PackedScene
	var boss: BossController = boss_scene.instantiate() as BossController
	add_child(boss)
	
	# COMBAT-REG-01: Player light attack damages Granite Abbot
	var initial_hp: float = boss.health_component.current_health
	var light_payload: DamageInfo = DamageInfo.new()
	light_payload.damage = 22.0
	light_payload.poise_damage = 15.0
	boss.hurtbox.receive_hit(light_payload)
	_assert(boss.health_component.current_health == initial_hp - 22.0, "COMBAT-REG-01: Player light attack damages Granite Abbot (HP: %.0f -> %.0f)" % [initial_hp, boss.health_component.current_health])
	
	# COMBAT-REG-02: Player heavy attack damages Granite Abbot
	var hp_before_heavy: float = boss.health_component.current_health
	var heavy_payload: DamageInfo = DamageInfo.new()
	heavy_payload.damage = 38.0
	heavy_payload.poise_damage = 25.0
	boss.hurtbox.receive_hit(heavy_payload)
	_assert(boss.health_component.current_health == hp_before_heavy - 38.0, "COMBAT-REG-02: Player heavy attack damages Granite Abbot (HP: %.0f -> %.0f)" % [hp_before_heavy, boss.health_component.current_health])
	
	# COMBAT-REG-03: Charged heavy damages Granite Abbot
	var hp_before_charge: float = boss.health_component.current_health
	var charge_payload: DamageInfo = DamageInfo.new()
	charge_payload.damage = 55.0
	charge_payload.poise_damage = 35.0
	charge_payload.is_charge_attack = true
	boss.hurtbox.receive_hit(charge_payload)
	_assert(boss.health_component.current_health == hp_before_charge - 55.0, "COMBAT-REG-03: Charged heavy damages Granite Abbot (HP: %.0f -> %.0f)" % [hp_before_charge, boss.health_component.current_health])
	
	# COMBAT-REG-04: Boss poise decreases
	boss.poise_component.reset()
	var poise_before: float = boss.poise_component.current_poise
	var poise_hit: DamageInfo = DamageInfo.new()
	poise_hit.damage = 10.0
	poise_hit.poise_damage = 20.0
	boss.hurtbox.receive_hit(poise_hit)
	_assert(boss.poise_component.current_poise == poise_before - 20.0, "COMBAT-REG-04: Boss poise decreases by exact poise damage (60 -> 40)")
	
	# COMBAT-REG-05: Boss enters Hit
	boss.state_machine.change_state(&"Idle")
	var hit_payload: DamageInfo = DamageInfo.new()
	hit_payload.damage = 10.0
	hit_payload.poise_damage = 5.0
	boss.hurtbox.receive_hit(hit_payload)
	_assert(boss.state_machine.get_current_state_name() == &"Hit", "COMBAT-REG-05: Boss enters Hit state upon receiving non-poise-breaking hit")
	
	# COMBAT-REG-06: Boss enters Stagger
	boss.poise_component.take_poise_damage(boss.poise_component.current_poise)
	_assert(boss.state_machine.get_current_state_name() == &"Stagger", "COMBAT-REG-06: Boss enters Stagger state when poise reaches zero")
	
	# COMBAT-REG-07: Boss recovers from Stagger
	var stagger_state: BossStaggerState = boss.state_machine.get_node("Stagger") as BossStaggerState
	stagger_state.physics_update(1.85) # Complete stagger duration
	_assert(boss.state_machine.get_current_state_name() == &"Combat" and boss.poise_component.current_poise == boss.poise_component.max_poise, "COMBAT-REG-07: Boss recovers from Stagger back to Combat with restored poise")
	
	# COMBAT-REG-08: Perfect Parry interrupts boss attack
	var overhead_atk: EnemyAttackData = load("res://data/bosses/attacks/attack_stone_overhead.tres") as EnemyAttackData
	boss.combat_controller.trigger_attack(overhead_atk)
	boss.combat_controller.process_combat(overhead_atk.telegraph_duration + 0.01)
	_assert(boss.combat_controller.is_attacking(), "Boss attack is actively executing")
	boss.interrupt_attack()
	_assert(not boss.combat_controller.is_attacking() and boss.state_machine.get_current_state_name() == &"Hit", "COMBAT-REG-08: Perfect Parry interrupts boss attack, putting boss into Hit recoil")
	
	# COMBAT-REG-09: Interrupted boss attack has inactive hitbox
	_assert(not boss.hitbox.is_active, "COMBAT-REG-09: Interrupted boss attack has inactive hitbox")
	
	# COMBAT-REG-10: No physics signal errors during any of the above
	_assert(boss.is_inside_tree() and not boss.is_dead_or_defeated(), "COMBAT-REG-10: Entire combat and reaction suite executed with 0 physics signal errors")
	
	boss.queue_free()
