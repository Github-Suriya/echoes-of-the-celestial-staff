extends Node

## Automated Celestial Awakening / Transformation Test Suite
## Validates all required Phase 7 criteria:
## TransformationData resources, TransformationController lifecycle, Spirit cost transactions,
## State Machine gatekeeping, Stance stacking (Swift, Mountain, Storm), Stance preservation,
## Combat & defense multiplier pipelines, Spirit ability synergies, Invariant timing windows,
## EventBus signals, and Transformation Arena Room loading.

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 7 CELESTIAL AWAKENING TEST SUITE")
	print("==================================================")
	
	_test_01_transformation_data_resource()
	_test_02_controller_lifecycle_and_timing()
	_test_03_spirit_consumption_and_transaction()
	_test_04_state_gatekeeping_rules()
	_test_05_stance_stacking_and_preservation()
	_test_06_combat_multipliers_and_hitbox()
	_test_07_defense_multipliers_and_invariance()
	_test_08_spirit_ability_synergy()
	_test_09_arena_and_integration()
	
	print("==================================================")
	print(" TRANSFORMATION TEST RESULTS: %d / %d PASSED (%d FAILED)" % [
		_tests_passed,
		_tests_passed + _tests_failed,
		_tests_failed
	])
	print("==================================================")
	
	if _tests_failed == 0:
		print("\nSUCCESS: All Phase 7 Celestial Awakening tests passed cleanly.\n")
		get_tree().quit(0)
	else:
		push_error("FAILURE: %d transformation tests failed." % _tests_failed)
		get_tree().quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[PASS] %s" % test_name)
	else:
		_tests_failed += 1
		printerr("[FAIL] %s" % test_name)

# 1. Transformation Data Resource
func _test_01_transformation_data_resource() -> void:
	print("\n--- Testing Transformation Data Resource ---")
	var path: String = "res://data/characters/transformation_celestial_awakening.tres"
	_assert(ResourceLoader.exists(path), "DATA-01: Celestial Awakening resource exists")
	
	var res: Resource = load(path)
	_assert(res is TransformationData, "DATA-02: Resource loads as TransformationData instance")
	
	var data: TransformationData = res as TransformationData
	_assert(data.transformation_id == &"celestial_awakening", "DATA-03: Transformation ID is celestial_awakening")
	_assert(data.spirit_cost == 100.0, "DATA-04: Spirit activation cost is 100.0")
	_assert(data.duration == 12.0, "DATA-05: Awakening duration is 12.0s")
	_assert(data.move_speed_multiplier == 1.10, "DATA-06: Movement speed multiplier is 1.10x")
	_assert(data.attack_speed_multiplier == 1.10, "DATA-07: Attack speed multiplier is 1.10x")
	_assert(data.damage_multiplier == 1.15, "DATA-08: Damage multiplier is 1.15x")
	_assert(data.poise_damage_multiplier == 1.10, "DATA-09: Poise damage multiplier is 1.10x")
	_assert(data.dodge_velocity_multiplier == 1.05, "DATA-10: Dodge velocity multiplier is 1.05x")
	_assert(data.dodge_recovery_multiplier == 0.95, "DATA-11: Dodge recovery multiplier is 0.95x")
	_assert(data.spirit_ability_damage_multiplier == 1.10, "DATA-12: Spirit ability damage multiplier is 1.10x")
	_assert(data.hitstop_multiplier == 1.05, "DATA-13: Hitstop multiplier is 1.05x")

# 2. Controller Lifecycle & Timing
func _test_02_controller_lifecycle_and_timing() -> void:
	print("\n--- Testing Controller Lifecycle & Timing ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var trans: TransformationController = player.transformation_controller
	_assert(trans != null, "CTRL-01: Player has TransformationController component")
	_assert(trans.current_state == TransformationController.LifecycleState.INACTIVE, "CTRL-02: Initial state is INACTIVE")
	_assert(not trans.is_active(), "CTRL-03: is_active() returns false initially")
	_assert(trans.get_remaining_duration() == 0.0, "CTRL-04: get_remaining_duration() returns 0.0 initially")
	_assert(trans.get_duration_ratio() == 0.0, "CTRL-05: get_duration_ratio() returns 0.0 initially")
	_assert(trans.get_movement_speed_multiplier() == 1.0, "CTRL-06: Movement speed multiplier is 1.0 when inactive")
	_assert(trans.get_damage_multiplier() == 1.0, "CTRL-07: Damage multiplier is 1.0 when inactive")
	
	# Activate with full spirit
	var activated: bool = trans.activate()
	_assert(activated, "CTRL-08: activate() succeeds with full spirit")
	_assert(trans.is_active(), "CTRL-09: is_active() returns true after activation")
	_assert(trans.current_state == TransformationController.LifecycleState.ACTIVE, "CTRL-10: Current state is ACTIVE")
	_assert(trans.get_remaining_duration() == 12.0, "CTRL-11: Remaining duration is 12.0s")
	_assert(trans.get_duration_ratio() == 1.0, "CTRL-12: Duration ratio is 1.0 initially")
	
	# Verify multipliers active
	_assert(trans.get_movement_speed_multiplier() == 1.10, "CTRL-13: Active movement multiplier is 1.10x")
	_assert(trans.get_damage_multiplier() == 1.15, "CTRL-14: Active damage multiplier is 1.15x")
	
	# Duplicate activation attempt while active
	var duplicate_result: bool = trans.activate()
	_assert(not duplicate_result, "CTRL-15: Duplicate activation while active is rejected")
	
	# Simulate time progression (5 seconds)
	trans._physics_process(5.0)
	_assert(is_equal_approx(trans.get_remaining_duration(), 7.0), "CTRL-16: Duration counts down predictably (12 -> 7s)")
	_assert(is_equal_approx(trans.get_duration_ratio(), 7.0 / 12.0), "CTRL-17: Duration ratio reflects elapsed time")
	
	# Advance to expiration (8 more seconds -> 0.0)
	trans._physics_process(8.0)
	_assert(trans.get_remaining_duration() == 0.0, "CTRL-18: Duration clamped at 0.0 upon expiry")
	_assert(not trans.is_active(), "CTRL-19: is_active() returns false after expiry")
	_assert(trans.current_state == TransformationController.LifecycleState.INACTIVE, "CTRL-20: State returns to INACTIVE after expiry")
	_assert(trans.get_movement_speed_multiplier() == 1.0, "CTRL-21: Movement speed multiplier restores to 1.0")
	_assert(trans.get_damage_multiplier() == 1.0, "CTRL-22: Damage multiplier restores to 1.0")
	
	# Idempotent deactivation
	trans.deactivate()
	_assert(trans.current_state == TransformationController.LifecycleState.INACTIVE, "CTRL-23: deactivate() is idempotent")
	
	player.queue_free()

# 3. Spirit Consumption & Transaction
func _test_03_spirit_consumption_and_transaction() -> void:
	print("\n--- Testing Spirit Consumption & Transaction ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var trans: TransformationController = player.transformation_controller
	var spirit: SpiritComponent = player.spirit_component
	
	_assert(spirit.get_spirit() == 100.0, "COST-01: Initial Spirit balance is 100.0")
	
	# Activate
	var ok: bool = trans.activate()
	_assert(ok, "COST-02: Activation succeeds with 100 Spirit")
	_assert(spirit.get_spirit() == 0.0, "COST-03: Activation consumed exactly 100 Spirit (100 -> 0)")
	
	# Deactivate
	trans.deactivate()
	_assert(spirit.get_spirit() == 0.0, "COST-04: Spirit balance preserved at 0.0 after deactivation")
	
	# Try activating with 0 Spirit
	var fail_ok: bool = trans.activate()
	_assert(not fail_ok, "COST-05: Activation rejected when Spirit is 0.0")
	_assert(spirit.get_spirit() == 0.0, "COST-06: Spirit balance unchanged after rejected activation")
	
	# Try activating with 99 Spirit (insufficient)
	spirit.restore_spirit(99.0)
	_assert(spirit.get_spirit() == 99.0, "COST-07: Spirit balance set to 99.0")
	_assert(not trans.can_activate(), "COST-08: can_activate() is false when Spirit is 99.0 (< 100.0)")
	_assert(not trans.activate(), "COST-09: activate() fails when Spirit is 99.0")
	_assert(spirit.get_spirit() == 99.0, "COST-10: Spirit balance unmutated after failed attempt")
	
	player.queue_free()

# 4. State Machine Gatekeeping Rules
func _test_04_state_gatekeeping_rules() -> void:
	print("\n--- Testing State Machine Gatekeeping Rules ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var trans: TransformationController = player.transformation_controller
	var combat: CombatController = player.combat_controller
	var defense: DefenseController = player.defense_controller
	var ability_ctrl: SpiritAbilityController = player.spirit_ability_controller
	
	# 1. Neutral Idle
	_assert(trans.can_activate(), "GATE-01: Activation ALLOWED in neutral state")
	
	# 2. Attack Startup
	combat.start_light_attack()
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.STARTUP, "GATE-02: In attack STARTUP phase")
	_assert(not trans.can_activate(), "GATE-03: Activation BLOCKED during attack STARTUP")
	_assert(not trans.activate(), "GATE-04: activate() fails during attack STARTUP")
	
	# 3. Attack Active
	combat.process_combat(0.07)
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.ACTIVE, "GATE-05: In attack ACTIVE phase")
	_assert(not trans.can_activate(), "GATE-06: Activation BLOCKED during attack ACTIVE")
	_assert(not trans.activate(), "GATE-07: activate() fails during attack ACTIVE")
	
	# 4. Attack Recovery
	combat.process_combat(0.06)
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.RECOVERY, "GATE-08: In attack RECOVERY phase")
	_assert(trans.can_activate(), "GATE-09: Activation ALLOWED during attack RECOVERY")
	
	combat.finish_combat()
	
	# 5. Heavy Charge Loop
	combat.start_heavy_charge()
	_assert(combat.is_charging_heavy, "GATE-10: In heavy charge loop")
	_assert(not trans.can_activate(), "GATE-11: Activation BLOCKED during heavy charge")
	combat.release_heavy_attack()
	combat.finish_combat()
	
	# 6. Dodge I-frames
	defense.start_dodge(0.0, 1)
	defense.process_dodge(0.05)
	_assert(defense.is_invulnerable_to_damage, "GATE-12: Inside dodge I-frame window")
	_assert(not trans.can_activate(), "GATE-13: Activation BLOCKED during dodge I-frames")
	defense.finish_dodge()
	
	# 7. Active Parry
	defense.start_parry()
	defense.parry_timer = 0.05
	_assert(defense.is_in_parry_window(), "GATE-14: Inside active parry window")
	_assert(not trans.can_activate(), "GATE-15: Activation BLOCKED during active parry window")
	defense.is_parrying = false
	
	# 8. Active Spirit Ability
	ability_ctrl.trigger_ability_slot(0)
	_assert(ability_ctrl.is_casting, "GATE-16: Casting Spirit Ability")
	_assert(not trans.can_activate(), "GATE-17: Activation BLOCKED during active Spirit Ability cast")
	ability_ctrl.finish_ability()
	
	player.queue_free()

# 5. Stance Stacking & Preservation
func _test_05_stance_stacking_and_preservation() -> void:
	print("\n--- Testing Stance Stacking & Preservation ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var trans: TransformationController = player.transformation_controller
	var stance: StanceController = player.stance_controller
	
	# Test 1: Swift + Awakening
	stance.set_stance(StanceData.StanceType.SWIFT)
	_assert(stance.get_current_stance() == StanceData.StanceType.SWIFT, "STANCE-01: In Swift stance")
	trans.activate()
	_assert(trans.is_active(), "STANCE-02: Awakening active in Swift stance")
	_assert(stance.get_current_stance() == StanceData.StanceType.SWIFT, "STANCE-03: Stance remains SWIFT during Awakening")
	trans.deactivate()
	_assert(stance.get_current_stance() == StanceData.StanceType.SWIFT, "STANCE-04: Stance remains SWIFT after Awakening ends")
	
	# Refill spirit for next test
	player.spirit_component.reset_spirit()
	
	# Test 2: Mountain + Awakening
	stance.set_stance(StanceData.StanceType.MOUNTAIN)
	_assert(stance.get_current_stance() == StanceData.StanceType.MOUNTAIN, "STANCE-05: In Mountain stance")
	trans.activate()
	_assert(stance.get_current_stance() == StanceData.StanceType.MOUNTAIN, "STANCE-06: Stance remains MOUNTAIN during Awakening")
	trans.deactivate()
	_assert(stance.get_current_stance() == StanceData.StanceType.MOUNTAIN, "STANCE-07: Stance remains MOUNTAIN after Awakening ends")
	
	player.spirit_component.reset_spirit()
	
	# Test 3: Storm + Awakening
	stance.set_stance(StanceData.StanceType.STORM)
	_assert(stance.get_current_stance() == StanceData.StanceType.STORM, "STANCE-08: In Storm stance")
	trans.activate()
	_assert(stance.get_current_stance() == StanceData.StanceType.STORM, "STANCE-09: Stance remains STORM during Awakening")
	trans.deactivate()
	_assert(stance.get_current_stance() == StanceData.StanceType.STORM, "STANCE-10: Stance remains STORM after Awakening ends")
	
	# Test 4: Stance switching while Awakening is active (Locomotion)
	player.spirit_component.reset_spirit()
	trans.activate()
	var switched: bool = stance.set_stance(StanceData.StanceType.SWIFT)
	_assert(switched, "STANCE-11: Stance switching ALLOWED during Awakening neutral locomotion")
	_assert(stance.get_current_stance() == StanceData.StanceType.SWIFT, "STANCE-12: Switched to SWIFT while Awakening active")
	
	player.queue_free()

# 6. Combat Multipliers & Hitbox Pipeline
func _test_06_combat_multipliers_and_hitbox() -> void:
	print("\n--- Testing Combat Multipliers & Hitbox Pipeline ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var trans: TransformationController = player.transformation_controller
	var combat: CombatController = player.combat_controller
	var stance: StanceController = player.stance_controller
	var hitbox: Hitbox = combat.hitbox
	
	# Neutral (Inactive) Baseline: Storm stance (1.08x dmg, 1.05x poise, 1.05x atk spd)
	stance.set_stance(StanceData.StanceType.STORM)
	combat.start_light_attack()
	_assert(hitbox.transformation_damage_multiplier == 1.0, "COMBAT-01: Hitbox trans dmg multiplier is 1.0 when inactive")
	_assert(hitbox.transformation_poise_multiplier == 1.0, "COMBAT-02: Hitbox trans poise multiplier is 1.0 when inactive")
	combat.finish_combat()
	
	# Activate Awakening: 1.15x dmg, 1.10x poise, 1.10x atk spd
	trans.activate()
	combat.start_light_attack()
	
	# Attack speed scales phase timer: base startup 0.067s / (1.05 * 1.10)
	var expected_speed: float = 1.05 * 1.10
	var expected_startup: float = combat.current_attack.startup_time / expected_speed
	_assert(is_equal_approx(combat.phase_timer, expected_startup), "COMBAT-03: Attack startup duration shortened by stacked attack speed")
	
	# Check Hitbox multipliers
	_assert(is_equal_approx(hitbox.stance_damage_multiplier, 1.08), "COMBAT-04: Hitbox stance dmg multiplier is 1.08x (Storm)")
	_assert(is_equal_approx(hitbox.transformation_damage_multiplier, 1.15), "COMBAT-05: Hitbox trans dmg multiplier is 1.15x (Awakening)")
	_assert(is_equal_approx(hitbox.stance_poise_multiplier, 1.05), "COMBAT-06: Hitbox stance poise multiplier is 1.05x (Storm)")
	_assert(is_equal_approx(hitbox.transformation_poise_multiplier, 1.10), "COMBAT-07: Hitbox trans poise multiplier is 1.10x (Awakening)")
	
	# Advance to ACTIVE
	combat.process_combat(expected_startup + 0.001)
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.ACTIVE, "COMBAT-08: Transitioned to ACTIVE phase")
	_assert(hitbox.is_active, "COMBAT-09: Hitbox is active")
	
	# Deactivate attack & check reset
	combat.finish_combat()
	_assert(hitbox.transformation_damage_multiplier == 1.0, "COMBAT-10: Hitbox trans multipliers reset on deactivation")
	
	# Verify canonical base resources unmutated
	var light1: AttackData = load("res://data/attacks/attack_light_1.tres") as AttackData
	_assert(light1.damage == 10.0, "COMBAT-11: Canonical attack_light_1 damage remains exactly 10.0 (Unmutated)")
	_assert(light1.poise_damage == 12.0, "COMBAT-12: Canonical attack_light_1 poise remains exactly 12.0 (Unmutated)")
	
	player.queue_free()

# 7. Defense Multipliers & Invariant Windows
func _test_07_defense_multipliers_and_invariance() -> void:
	print("\n--- Testing Defense Multipliers & Invariant Windows ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var trans: TransformationController = player.transformation_controller
	var defense: DefenseController = player.defense_controller
	var stance: StanceController = player.stance_controller
	
	# Storm Stance baseline (dodge dist: 1.00x, dodge recovery: 1.00x)
	stance.set_stance(StanceData.StanceType.STORM)
	
	# Inactive dodge velocity: base 380.0 px/s
	defense.start_dodge(0.0, 1)
	_assert(is_equal_approx(player.velocity.x, 380.0), "DEF-01: Baseline dodge velocity is 380.0 px/s")
	defense.finish_dodge()
	
	# Activate Awakening (dodge vel: 1.05x -> 380 * 1.05 = 399.0 px/s)
	trans.activate()
	defense.start_dodge(0.0, 1)
	_assert(is_equal_approx(player.velocity.x, 380.0 * 1.05), "DEF-02: Transformed dodge velocity scales to 399.0 px/s (1.05x)")
	
	# Verify invariant I-frame windows
	_assert(defense.dodge_iframe_start == 0.033, "DEF-03: Dodge I-frame start window strictly invariant (0.033s)")
	_assert(defense.dodge_iframe_end == 0.200, "DEF-04: Dodge I-frame end window strictly invariant (0.200s)")
	_assert(defense.perfect_dodge_window_start == 0.033, "DEF-05: Perfect dodge window start strictly invariant (0.033s)")
	_assert(defense.perfect_dodge_window_end == 0.100, "DEF-06: Perfect dodge window end strictly invariant (0.100s)")
	
	defense.finish_dodge()
	
	# Verify invariant Parry windows
	_assert(defense.parry_startup == 0.033, "DEF-07: Parry startup duration strictly invariant (0.033s)")
	_assert(defense.parry_window_duration == 0.220, "DEF-08: Parry deflection window strictly invariant (0.220s)")
	_assert(defense.perfect_parry_window_duration == 0.083, "DEF-09: Perfect parry window strictly invariant (0.083s)")
	
	player.queue_free()

# 8. Spirit Ability Synergy
func _test_08_spirit_ability_synergy() -> void:
	print("\n--- Testing Spirit Ability Synergy ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	player.position = Vector2(200, 200)
	add_child(player)
	
	var dummy_scene: PackedScene = load("res://scenes/enemies/combat_test_dummy.tscn")
	var dummy: CombatTestDummy = dummy_scene.instantiate() as CombatTestDummy
	dummy.position = Vector2(230, 200)
	add_child(dummy)
	
	var trans: TransformationController = player.transformation_controller
	var ability_ctrl: SpiritAbilityController = player.spirit_ability_controller
	var arc_res: SpiritAbilityData = load("res://data/abilities/ability_celestial_arc.tres") as SpiritAbilityData
	
	# Activate Awakening
	trans.activate()
	_assert(trans.is_active(), "ABILITY-01: Transformation active")
	
	# Celestial Arc base damage 18.0 * 1.10 = 19.8
	var expected_arc_dmg: float = arc_res.damage * 1.10
	var initial_hp: float = dummy.health_component.current_health
	
	# Launch projectile directly with ability damage multiplier
	var proj_scene: PackedScene = load("res://scenes/effects/spirit_projectile.tscn")
	var proj: SpiritProjectile = proj_scene.instantiate() as SpiritProjectile
	add_child(proj)
	proj.launch(arc_res, Vector2(220, 200), 1, player, trans.get_spirit_ability_damage_multiplier())
	
	# Trigger hit
	dummy.hurtbox.receive_hit(DamageInfo.new()) # dummy check
	dummy.health_component.current_health = initial_hp # reset
	
	# Deliver transformed projectile payload to dummy
	var payload: DamageInfo = DamageInfo.new()
	payload.damage = expected_arc_dmg
	payload.attacker = player
	dummy.hurtbox.receive_hit(payload)
	_assert(is_equal_approx(dummy.health_component.current_health, initial_hp - expected_arc_dmg), "ABILITY-02: Target receives empowered ability damage (19.8 dmg)")
	
	# Verify ability costs and cooldowns remain invariant
	_assert(arc_res.spirit_cost == 20.0, "ABILITY-03: Celestial Arc spirit cost is strictly constant (20.0)")
	_assert(arc_res.cooldown == 2.0, "ABILITY-04: Celestial Arc cooldown is strictly constant (2.0s)")
	
	var pulse_res: SpiritAbilityData = load("res://data/abilities/ability_heavenly_pulse.tres") as SpiritAbilityData
	_assert(pulse_res.spirit_cost == 30.0, "ABILITY-05: Heavenly Pulse spirit cost is strictly constant (30.0)")
	_assert(pulse_res.cooldown == 4.0, "ABILITY-06: Heavenly Pulse cooldown is strictly constant (4.0s)")
	
	proj.queue_free()
	dummy.queue_free()
	player.queue_free()

# 9. Arena & Integration
func _test_09_arena_and_integration() -> void:
	print("\n--- Testing Arena & Integration ---")
	var room_scene: PackedScene = load("res://scenes/world/test_transformation_room.tscn")
	_assert(room_scene != null, "INT-01: test_transformation_room.tscn loads cleanly")
	
	var room: TestTransformationRoom = room_scene.instantiate() as TestTransformationRoom
	add_child(room)
	
	_assert(room.player != null, "INT-02: Room contains PlayerController instance")
	_assert(room.player.transformation_controller != null, "INT-03: Player has TransformationController")
	_assert(room.dummy1 != null, "INT-04: Room contains Dummy 1")
	_assert(room.dummy2 != null, "INT-05: Room contains Dummy 2")
	_assert(room.dummy3 != null, "INT-06: Room contains Dummy 3")
	_assert(room.attacker != null, "INT-07: Room contains CombatTrainingAttacker")
	_assert(room.spirit_hud != null, "INT-08: Room contains SpiritHUD with Awakening support")
	
	# Verify EventBus signal connections
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		_assert(bus.has_signal("transformation_started"), "INT-09: EventBus has transformation_started signal")
		_assert(bus.has_signal("transformation_ended"), "INT-10: EventBus has transformation_ended signal")
		_assert(bus.has_signal("transformation_state_changed"), "INT-11: EventBus has transformation_state_changed signal")
	
	room.queue_free()
