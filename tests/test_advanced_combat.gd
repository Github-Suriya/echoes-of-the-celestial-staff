extends Node

## Automated Advanced Combat & Defense Test Suite
## Validates all 42 required Phase 4 defensive, aerial, charged, and cancellation mechanics.

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 4 ADVANCED COMBAT & DEFENSE TEST SUITE")
	print("==================================================")
	
	_test_01_components_and_architecture()
	_test_02_ground_dodge_and_iframes()
	_test_03_perfect_dodge_mechanics()
	_test_04_ground_parry_windows()
	_test_05_perfect_parry_and_interruption()
	_test_06_failed_and_unparryable_defense()
	_test_07_aerial_attack_mechanics()
	_test_08_charged_heavy_attack()
	_test_09_attack_recovery_cancellation()
	_test_10_combat_training_attacker_and_arena()
	
	print("==================================================")
	print(" ADVANCED COMBAT TEST RESULTS: %d / %d PASSED (%d FAILED)" % [
		_tests_passed,
		_tests_passed + _tests_failed,
		_tests_failed
	])
	print("==================================================")
	
	if _tests_failed == 0:
		print("\nSUCCESS: All Phase 4 Advanced Combat and Defense tests passed cleanly.\n")
		get_tree().quit(0)
	else:
		push_error("FAILURE: %d advanced combat tests failed." % _tests_failed)
		get_tree().quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[PASS] %s" % test_name)
	else:
		_tests_failed += 1
		push_error("[FAIL] %s" % test_name)

# 1. Architecture & Component Loading
func _test_01_components_and_architecture() -> void:
	print("\n--- Testing Defensive Components Architecture ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	_assert(player_scene != null, "ARCH-01: Player scene loads successfully")
	
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var defense: DefenseController = player.get_node_or_null("Components/DefenseController") as DefenseController
	_assert(defense != null, "ARCH-02: Player has DefenseController component attached")
	
	var hurtbox: Hurtbox = player.get_node_or_null("Combat/PlayerHurtbox") as Hurtbox
	_assert(hurtbox != null and hurtbox.defense_controller == defense, "ARCH-03: PlayerHurtbox references DefenseController")
	
	var sm: StateMachine = player.get_node_or_null("StateMachine") as StateMachine
	_assert(sm != null, "ARCH-04: Player has StateMachine")
	_assert(sm.get_node_or_null("Dodge") is PlayerDodgeState, "ARCH-05: StateMachine has Dodge state")
	_assert(sm.get_node_or_null("Parry") is PlayerParryState, "ARCH-06: StateMachine has Parry state")
	_assert(sm.get_node_or_null("AirAttack") is PlayerAirAttackState, "ARCH-07: StateMachine has AirAttack state")
	
	# Verify EventBus defensive signals
	var bus: Node = get_node_or_null("/root/EventBus")
	_assert(bus != null, "ARCH-08: EventBus autoload is present")
	if bus != null:
		_assert(bus.has_signal("dodge_started"), "ARCH-09: EventBus has dodge_started signal")
		_assert(bus.has_signal("dodge_completed"), "ARCH-10: EventBus has dodge_completed signal")
		_assert(bus.has_signal("perfect_dodge"), "ARCH-11: EventBus has perfect_dodge signal")
		_assert(bus.has_signal("parry_started"), "ARCH-12: EventBus has parry_started signal")
		_assert(bus.has_signal("parry_success"), "ARCH-13: EventBus has parry_success signal")
		_assert(bus.has_signal("perfect_parry"), "ARCH-14: EventBus has perfect_parry signal")
		_assert(bus.has_signal("attack_interrupted"), "ARCH-15: EventBus has attack_interrupted signal")
	
	player.queue_free()

# 2. Ground Dodge & I-frames
func _test_02_ground_dodge_and_iframes() -> void:
	print("\n--- Testing Ground Dodge & I-frames ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var defense: DefenseController = player.get_node("Components/DefenseController") as DefenseController
	
	# Test neutral dodge direction follows facing
	player.facing_direction = 1
	defense.start_dodge(0.0, player.facing_direction)
	_assert(defense.is_dodging, "DODGE-01: Dodge starts and sets is_dodging to true")
	_assert(defense.dodge_direction == 1, "DODGE-02: Neutral dodge with facing=+1 dodges right")
	_assert(player.velocity.x > 0.0, "DODGE-03: Positive dodge velocity applied")
	_assert(player.collision_layer == 2 and player.collision_mask == 1, "DODGE-04: World collision remains intact during dodge")
	
	# Test opposite direction when moving left
	defense.finish_dodge()
	defense.start_dodge(-1.0, 1)
	_assert(defense.dodge_direction == -1, "DODGE-05: Dodge with negative move axis dodges left")
	_assert(player.velocity.x < 0.0, "DODGE-06: Negative dodge velocity applied")
	
	# Test I-frames timing
	defense.finish_dodge()
	defense.start_dodge(0.0, 1)
	# At t=0.01 (startup vulnerable)
	defense.process_dodge(0.01)
	_assert(not defense.is_invulnerable_to_damage, "DODGE-07: Dodge is vulnerable during startup (t=0.01s)")
	
	# Advance into I-frames (t=0.05s, within 0.033s - 0.200s)
	defense.process_dodge(0.04) # elapsed = 0.05s
	_assert(defense.is_invulnerable_to_damage, "DODGE-08: Dodge has active I-frames at t=0.05s")
	
	# Advance past I-frames into recovery (t=0.25s)
	defense.process_dodge(0.20) # elapsed = 0.25s
	_assert(not defense.is_invulnerable_to_damage, "DODGE-09: Dodge I-frames expire in recovery phase (t=0.25s)")
	
	# Advance past total duration (0.35s)
	var still_dodging: bool = defense.process_dodge(0.15) # elapsed = 0.40s
	_assert(not still_dodging and not defense.is_dodging, "DODGE-10: Dodge finishes after total duration")
	
	player.queue_free()

# 3. Perfect Dodge Mechanics
func _test_03_perfect_dodge_mechanics() -> void:
	print("\n--- Testing Perfect Dodge Mechanics ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var defense: DefenseController = player.get_node("Components/DefenseController") as DefenseController
	var attacker_scene: PackedScene = load("res://scenes/enemies/combat_training_attacker.tscn")
	var dummy: CombatTrainingAttacker = attacker_scene.instantiate() as CombatTrainingAttacker
	add_child(dummy)
	
	var damage_info: DamageInfo = DamageInfo.new()
	damage_info.damage = 20.0
	damage_info.attacker = dummy
	damage_info.is_dodgeable = true
	
	var perfect_dodge_received: Array[bool] = [false]
	defense.perfect_dodge.connect(func(_attacker): perfect_dodge_received[0] = true)
	
	defense.start_dodge(0.0, 1)
	# Step into perfect dodge window (t=0.05s, window is 0.033s to 0.100s)
	defense.process_dodge(0.05)
	_assert(defense.is_in_perfect_dodge_window(), "PERF-DODGE-01: In perfect dodge window at t=0.05s")
	
	var result: int = defense.try_intercept_hit(damage_info)
	_assert(result == DefenseController.DefenseResult.DODGE_PERFECT, "PERF-DODGE-02: try_intercept_hit returns DODGE_PERFECT")
	_assert(perfect_dodge_received[0], "PERF-DODGE-03: perfect_dodge signal emitted")
	
	# Reset and test normal dodge interception outside perfect window (t=0.15s)
	defense.finish_dodge()
	defense.start_dodge(0.0, 1)
	defense.process_dodge(0.15)
	_assert(defense.is_invulnerable_to_damage and not defense.is_in_perfect_dodge_window(), "PERF-DODGE-04: I-frame active but outside perfect dodge window at t=0.15s")
	
	result = defense.try_intercept_hit(damage_info)
	_assert(result == DefenseController.DefenseResult.DODGE_NORMAL, "PERF-DODGE-05: try_intercept_hit returns DODGE_NORMAL")
	
	dummy.queue_free()
	player.queue_free()

# 4. Ground Parry Windows
func _test_04_ground_parry_windows() -> void:
	print("\n--- Testing Ground Parry Windows ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var defense: DefenseController = player.get_node("Components/DefenseController") as DefenseController
	defense.start_parry()
	_assert(defense.is_parrying, "PARRY-01: Parry begins and sets is_parrying to true")
	
	# At t=0.01s (vulnerable startup, startup is 0.033s)
	defense.process_parry(0.01)
	_assert(not defense.is_in_parry_window(), "PARRY-02: Parry is inactive during startup window (t=0.01s)")
	
	# Advance into active parry window (t=0.06s, window 0.033s to 0.253s)
	defense.process_parry(0.05)
	_assert(defense.is_in_parry_window(), "PARRY-03: Active parry window is active at t=0.06s")
	
	# Advance into parry recovery (t=0.28s)
	defense.process_parry(0.22)
	_assert(not defense.is_in_parry_window(), "PARRY-04: Parry window expired in recovery phase (t=0.28s)")
	
	# Advance past total duration
	var still_parrying: bool = defense.process_parry(0.20)
	_assert(not still_parrying and not defense.is_parrying, "PARRY-05: Parry finishes after total duration")
	
	player.queue_free()

# 5. Perfect Parry & Attacker Interruption
func _test_05_perfect_parry_and_interruption() -> void:
	print("\n--- Testing Perfect Parry & Attacker Interruption ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var defense: DefenseController = player.get_node("Components/DefenseController") as DefenseController
	
	var attacker_scene: PackedScene = load("res://scenes/enemies/combat_training_attacker.tscn")
	var attacker: CombatTrainingAttacker = attacker_scene.instantiate() as CombatTrainingAttacker
	add_child(attacker)
	attacker.trigger_attack()
	
	var damage_info: DamageInfo = DamageInfo.new()
	damage_info.damage = 15.0
	damage_info.attacker = attacker
	damage_info.is_parryable = true
	
	var perfect_parry_received: Array[bool] = [false]
	defense.perfect_parry.connect(func(_attacker): perfect_parry_received[0] = true)
	
	defense.start_parry()
	# Step into perfect parry window (t=0.05s, parry_startup=0.033, perfect_window_duration=0.083 -> ends at 0.116s)
	defense.process_parry(0.05)
	_assert(defense.is_in_perfect_parry_window(), "PERF-PARRY-01: Inside perfect parry window at t=0.05s")
	
	var initial_attacker_poise: float = attacker.poise_component.current_poise
	var result: int = defense.try_intercept_hit(damage_info)
	_assert(result == DefenseController.DefenseResult.PARRY_PERFECT, "PERF-PARRY-02: try_intercept_hit returns PARRY_PERFECT")
	_assert(perfect_parry_received[0], "PERF-PARRY-03: perfect_parry signal emitted")
	_assert(attacker.poise_component.current_poise < initial_attacker_poise, "PERF-PARRY-04: Perfect parry inflicts poise damage on attacker")
	_assert(attacker.current_state == CombatTrainingAttacker.AttackerState.INTERRUPTED, "PERF-PARRY-05: Attacker state changed to INTERRUPTED")
	
	# Normal Parry Test (t=0.15s, inside active parry but outside perfect window)
	defense.finish_parry()
	defense.start_parry()
	defense.process_parry(0.15)
	_assert(defense.is_in_parry_window() and not defense.is_in_perfect_parry_window(), "PARRY-06: Active parry but outside perfect window at t=0.15s")
	
	var normal_parry_received: Array[bool] = [false]
	defense.parry_success.connect(func(_attacker): normal_parry_received[0] = true)
	result = defense.try_intercept_hit(damage_info)
	_assert(result == DefenseController.DefenseResult.PARRY_NORMAL, "PARRY-07: try_intercept_hit returns PARRY_NORMAL")
	_assert(normal_parry_received[0], "PARRY-08: parry_success signal emitted on normal parry")
	
	attacker.queue_free()
	player.queue_free()

# 6. Failed & Unparryable Defense
func _test_06_failed_and_unparryable_defense() -> void:
	print("\n--- Testing Failed Defense Scenarios ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var defense: DefenseController = player.get_node("Components/DefenseController") as DefenseController
	var hurtbox: Hurtbox = player.get_node("Combat/PlayerHurtbox") as Hurtbox
	
	var damage_info: DamageInfo = DamageInfo.new()
	damage_info.damage = 20.0
	damage_info.poise_damage = 15.0
	damage_info.is_parryable = false
	damage_info.is_dodgeable = true
	
	# Unparryable attack during parry window must NOT be intercepted
	defense.start_parry()
	defense.process_parry(0.06)
	var intercept_result: int = defense.try_intercept_hit(damage_info)
	_assert(intercept_result == DefenseController.DefenseResult.NONE, "FAIL-DEF-01: Unparryable attack is not intercepted by parry")
	
	# Hit received during parry startup (t=0.01s)
	damage_info.is_parryable = true
	defense.finish_parry()
	defense.start_parry()
	defense.process_parry(0.01)
	intercept_result = defense.try_intercept_hit(damage_info)
	_assert(intercept_result == DefenseController.DefenseResult.NONE, "FAIL-DEF-02: Attack received during parry startup is not intercepted")
	
	# Hit received during dodge recovery (t=0.25s)
	defense.finish_parry()
	defense.start_dodge(0.0, 1)
	defense.process_dodge(0.25)
	intercept_result = defense.try_intercept_hit(damage_info)
	_assert(intercept_result == DefenseController.DefenseResult.NONE, "FAIL-DEF-03: Attack received during dodge recovery is not intercepted")
	
	player.queue_free()

# 7. Aerial Attack Mechanics
func _test_07_aerial_attack_mechanics() -> void:
	print("\n--- Testing Aerial Attack Mechanics ---")
	var air_attack_res: AttackData = load("res://data/attacks/attack_air_1.tres") as AttackData
	_assert(air_attack_res != null, "AIR-01: attack_air_1.tres loads successfully")
	_assert(air_attack_res.damage == 14.0, "AIR-02: Air attack damage matches specification (14.0)")
	_assert(air_attack_res.poise_damage == 16.0, "AIR-03: Air attack poise damage matches specification (16.0)")
	
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var combat: CombatController = player.combat_controller
	var sm: StateMachine = player.get_node("StateMachine") as StateMachine
	
	# Start air attack
	var started: bool = combat.start_air_attack()
	_assert(started, "AIR-04: start_air_attack() returns true")
	_assert(combat.get_current_attack() == air_attack_res, "AIR-05: Current attack set to attack_air_1")
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.STARTUP, "AIR-06: Initial phase is STARTUP")
	
	# Air state transitions
	sm.change_state(&"AirAttack")
	_assert(sm.current_state is PlayerAirAttackState, "AIR-07: State machine transitioned to PlayerAirAttackState")
	
	player.queue_free()

# 8. Charged Heavy Attack Mechanics
func _test_08_charged_heavy_attack() -> void:
	print("\n--- Testing Charged Heavy Attack ---")
	var heavy_res: AttackData = load("res://data/attacks/attack_heavy_1.tres") as AttackData
	_assert(heavy_res != null and heavy_res.is_chargeable, "CHARGE-01: attack_heavy_1 is marked chargeable")
	_assert(heavy_res.maximum_damage_multiplier == 2.0, "CHARGE-02: Maximum damage multiplier is 2.0x")
	_assert(heavy_res.maximum_poise_multiplier == 2.0, "CHARGE-03: Maximum poise multiplier is 2.0x")
	
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var combat: CombatController = player.combat_controller
	
	# Start charge
	combat.start_heavy_charge()
	_assert(combat.is_charging_heavy, "CHARGE-04: start_heavy_charge sets is_charging_heavy to true")
	_assert(combat.get_attack_phase_name() == "CHARGING", "CHARGE-05: Phase name reports CHARGING")
	
	# Update charge partially
	combat.update_heavy_charge(0.45) # halfway between 0.15 and 0.75
	_assert(combat.get_charge_ratio() > 0.4 and combat.get_charge_ratio() < 0.6, "CHARGE-06: Charge ratio interpolates smoothly")
	_assert(combat.charge_multiplier > 1.4 and combat.charge_multiplier < 1.6, "CHARGE-07: Damage multiplier scales proportionally")
	
	# Update charge to maximum
	combat.update_heavy_charge(0.50) # total >= 0.75s
	_assert(combat.get_charge_ratio() == 1.0, "CHARGE-08: Charge ratio caps at 1.0")
	_assert(combat.charge_multiplier == 2.0, "CHARGE-09: Charge multiplier reaches 2.0x")
	_assert(combat.poise_charge_multiplier == 2.0, "CHARGE-10: Poise multiplier reaches 2.0x")
	
	# Release heavy attack
	var released: bool = combat.release_heavy_attack()
	_assert(released, "CHARGE-11: release_heavy_attack executes successfully")
	_assert(not combat.is_charging_heavy, "CHARGE-12: is_charging_heavy resets to false")
	_assert(combat.hitbox.damage_multiplier == 2.0, "CHARGE-13: Hitbox damage multiplier configured to 2.0x")
	_assert(combat.hitbox.poise_multiplier == 2.0, "CHARGE-14: Hitbox poise multiplier configured to 2.0x")
	
	player.queue_free()

# 9. Attack Recovery Cancellation
func _test_09_attack_recovery_cancellation() -> void:
	print("\n--- Testing Attack Recovery Cancellation ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var combat: CombatController = player.combat_controller
	combat.start_light_attack()
	
	# In STARTUP phase
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.STARTUP, "CANCEL-01: Attack in STARTUP phase")
	_assert(not combat.can_cancel_attack(), "CANCEL-02: Attack CANNOT be cancelled during STARTUP")
	
	# Advance into ACTIVE phase
	combat.process_combat(0.08)
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.ACTIVE, "CANCEL-03: Attack in ACTIVE phase")
	_assert(not combat.can_cancel_attack(), "CANCEL-04: Attack CANNOT be cancelled during ACTIVE")
	
	# Advance into RECOVERY phase
	combat.process_combat(0.08)
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.RECOVERY, "CANCEL-05: Attack in RECOVERY phase")
	_assert(combat.can_cancel_attack(), "CANCEL-06: Attack CAN be cancelled during RECOVERY")
	
	player.queue_free()

# 10. Combat Training Attacker & Defense Room
func _test_10_combat_training_attacker_and_arena() -> void:
	print("\n--- Testing Training Attacker & Arena Scene ---")
	var attacker_scene: PackedScene = load("res://scenes/enemies/combat_training_attacker.tscn")
	_assert(attacker_scene != null, "ROOM-01: CombatTrainingAttacker scene loads successfully")
	
	var attacker: CombatTrainingAttacker = attacker_scene.instantiate() as CombatTrainingAttacker
	add_child(attacker)
	_assert(attacker.has_node("Combat/EnemyHitbox"), "ROOM-02: Training Attacker has EnemyHitbox")
	_assert(attacker.has_node("Hurtbox"), "ROOM-03: Training Attacker has Hurtbox")
	_assert(attacker.has_node("Components/PoiseComponent"), "ROOM-04: Training Attacker has PoiseComponent")
	
	# Test attack trigger and telegraph
	var triggered: bool = attacker.trigger_attack()
	_assert(triggered, "ROOM-05: trigger_attack() succeeds")
	_assert(attacker.current_state == CombatTrainingAttacker.AttackerState.TELEGRAPH, "ROOM-06: Attacker enters TELEGRAPH state")
	
	# Test interruption
	attacker.interrupt_attack()
	_assert(attacker.current_state == CombatTrainingAttacker.AttackerState.INTERRUPTED, "ROOM-07: Attacker interrupted cleanly")
	
	attacker.queue_free()
	
	# Test arena room loading
	var room_scene: PackedScene = load("res://scenes/world/test_defense_room.tscn")
	_assert(room_scene != null, "ROOM-08: TestDefenseRoom scene loads successfully")
	
	var room: TestDefenseRoom = room_scene.instantiate() as TestDefenseRoom
	add_child(room)
	_assert(room.player != null, "ROOM-09: Defense room instantiates Player")
	_assert(room.attacker != null, "ROOM-10: Defense room instantiates CombatTrainingAttacker")
	_assert(room.dummy != null, "ROOM-11: Defense room instantiates CombatTestDummy")
	
	room.queue_free()
