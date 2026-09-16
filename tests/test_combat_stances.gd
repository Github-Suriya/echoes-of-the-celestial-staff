extends Node

## Automated Combat Stances Test Suite
## Validates all 42 required Phase 5 stance criteria:
## StanceData resources, StanceController, Movement, Attack, Poise, Dodge, Parry,
## State Machine safety gatekeeping, State persistence, and Regression tests.

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 5 COMBAT STANCES TEST SUITE")
	print("==================================================")
	
	_test_01_stance_data_resources()
	_test_02_stance_controller_api()
	_test_03_movement_modifiers()
	_test_04_attack_speed_and_damage_modifiers()
	_test_05_poise_modifiers()
	_test_06_dodge_modifiers()
	_test_07_parry_integration()
	_test_08_state_machine_safety_rules()
	_test_09_state_persistence()
	_test_10_arena_room_loading()
	
	print("==================================================")
	print(" COMBAT STANCES TEST RESULTS: %d / %d PASSED (%d FAILED)" % [
		_tests_passed,
		_tests_passed + _tests_failed,
		_tests_failed
	])
	print("==================================================")
	
	if _tests_failed == 0:
		print("\nSUCCESS: All Phase 5 Combat Stances tests passed cleanly.\n")
		get_tree().quit(0)
	else:
		push_error("FAILURE: %d combat stance tests failed." % _tests_failed)
		get_tree().quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[PASS] %s" % test_name)
	else:
		_tests_failed += 1
		push_error("[FAIL] %s" % test_name)

# 1. Stance Data Resources
func _test_01_stance_data_resources() -> void:
	print("\n--- Testing Stance Data Resources ---")
	var swift_res: StanceData = load("res://data/characters/stance_swift.tres") as StanceData
	_assert(swift_res != null, "DATA-01: Swift stance resource loads cleanly")
	if swift_res != null:
		_assert(swift_res.stance_type == StanceData.StanceType.SWIFT, "DATA-02: Swift resource has SWIFT enum value")
		_assert(swift_res.movement_speed_multiplier == 1.10, "DATA-03: Swift has 1.10x movement speed multiplier")
		_assert(swift_res.attack_speed_multiplier == 1.12, "DATA-04: Swift has 1.12x attack speed multiplier")
		_assert(swift_res.damage_multiplier == 0.90, "DATA-05: Swift has 0.90x damage multiplier")
	
	var mountain_res: StanceData = load("res://data/characters/stance_mountain.tres") as StanceData
	_assert(mountain_res != null, "DATA-06: Mountain stance resource loads cleanly")
	if mountain_res != null:
		_assert(mountain_res.stance_type == StanceData.StanceType.MOUNTAIN, "DATA-07: Mountain resource has MOUNTAIN enum value")
		_assert(mountain_res.movement_speed_multiplier == 0.90, "DATA-08: Mountain has 0.90x movement speed multiplier")
		_assert(mountain_res.attack_speed_multiplier == 0.88, "DATA-09: Mountain has 0.88x attack speed multiplier")
		_assert(mountain_res.damage_multiplier == 1.18, "DATA-10: Mountain has 1.18x damage multiplier")
		_assert(mountain_res.poise_damage_multiplier == 1.30, "DATA-11: Mountain has 1.30x poise damage multiplier")
	
	var storm_res: StanceData = load("res://data/characters/stance_storm.tres") as StanceData
	_assert(storm_res != null, "DATA-12: Storm stance resource loads cleanly")
	if storm_res != null:
		_assert(storm_res.stance_type == StanceData.StanceType.STORM, "DATA-13: Storm resource has STORM enum value")
		_assert(storm_res.movement_speed_multiplier == 1.00, "DATA-14: Storm has 1.00x movement speed multiplier")
		_assert(storm_res.damage_multiplier == 1.08, "DATA-15: Storm has 1.08x damage multiplier")

# 2. Stance Controller API
func _test_02_stance_controller_api() -> void:
	print("\n--- Testing Stance Controller API ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var stance_ctrl: StanceController = player.stance_controller
	_assert(stance_ctrl != null, "CTRL-01: Player has StanceController component")
	_assert(stance_ctrl.get_current_stance() == StanceData.StanceType.SWIFT, "CTRL-02: Initial stance defaults to SWIFT")
	_assert(stance_ctrl.get_current_stance_data() != null, "CTRL-03: Initial StanceData is non-null")
	
	# Signal verification
	var signals_received: Array[int] = []
	stance_ctrl.stance_changed.connect(func(new_st, _old_st): signals_received.append(new_st))
	
	# Switch to Mountain
	var success_mtn: bool = stance_ctrl.set_stance(StanceData.StanceType.MOUNTAIN)
	_assert(success_mtn and stance_ctrl.get_current_stance() == StanceData.StanceType.MOUNTAIN, "CTRL-04: set_stance to MOUNTAIN succeeds")
	
	# Switch to Storm
	var success_storm: bool = stance_ctrl.set_stance(StanceData.StanceType.STORM)
	_assert(success_storm and stance_ctrl.get_current_stance() == StanceData.StanceType.STORM, "CTRL-05: set_stance to STORM succeeds")
	
	# Cycle stance (Storm -> Swift -> Mountain)
	stance_ctrl.cycle_stance()
	_assert(stance_ctrl.get_current_stance() == StanceData.StanceType.SWIFT, "CTRL-06: cycle_stance from STORM cycles to SWIFT")
	stance_ctrl.cycle_stance()
	_assert(stance_ctrl.get_current_stance() == StanceData.StanceType.MOUNTAIN, "CTRL-07: cycle_stance from SWIFT cycles to MOUNTAIN")
	
	_assert(signals_received.size() >= 4, "CTRL-08: stance_changed signal emitted on every stance change")
	
	player.queue_free()

# 3. Movement Modifiers
func _test_03_movement_modifiers() -> void:
	print("\n--- Testing Movement Modifiers ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var stance_ctrl: StanceController = player.stance_controller
	var movement: PlayerMovement = player.movement
	
	# Swift movement speed
	stance_ctrl.set_stance(StanceData.StanceType.SWIFT)
	_assert(stance_ctrl.get_movement_speed_multiplier() == 1.10, "MOVE-01: Swift speed multiplier is 1.10x")
	_assert(stance_ctrl.get_acceleration_multiplier() == 1.10, "MOVE-02: Swift accel multiplier is 1.10x")
	
	# Mountain movement speed
	stance_ctrl.set_stance(StanceData.StanceType.MOUNTAIN)
	_assert(stance_ctrl.get_movement_speed_multiplier() == 0.90, "MOVE-03: Mountain speed multiplier is 0.90x")
	_assert(stance_ctrl.get_acceleration_multiplier() == 0.90, "MOVE-04: Mountain accel multiplier is 0.90x")
	
	# Storm movement speed
	stance_ctrl.set_stance(StanceData.StanceType.STORM)
	_assert(stance_ctrl.get_movement_speed_multiplier() == 1.00, "MOVE-05: Storm speed multiplier is 1.00x")
	
	player.queue_free()

# 4. Attack Speed & Damage Modifiers
func _test_04_attack_speed_and_damage_modifiers() -> void:
	print("\n--- Testing Attack Speed & Damage Modifiers ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var stance_ctrl: StanceController = player.stance_controller
	var combat: CombatController = player.combat_controller
	
	# Verify Swift attack speed and damage
	stance_ctrl.set_stance(StanceData.StanceType.SWIFT)
	combat.start_light_attack()
	var base_light_1: AttackData = load("res://data/attacks/attack_light_1.tres") as AttackData
	var expected_swift_startup: float = base_light_1.startup_time / 1.12
	_assert(absf(combat.phase_timer - expected_swift_startup) < 0.001, "ATK-01: Swift shortens attack startup time (1.12x speed)")
	_assert(combat.hitbox.stance_damage_multiplier == 0.90, "ATK-02: Swift applies 0.90x damage multiplier to hitbox")
	_assert(base_light_1.damage == 10.0, "ATK-03: Canonical base AttackData resource remains unmutated")
	
	combat.finish_combat()
	
	# Verify Mountain attack speed and damage
	stance_ctrl.set_stance(StanceData.StanceType.MOUNTAIN)
	combat.start_light_attack()
	var expected_mtn_startup: float = base_light_1.startup_time / 0.88
	_assert(absf(combat.phase_timer - expected_mtn_startup) < 0.001, "ATK-04: Mountain extends attack startup time (0.88x speed)")
	_assert(combat.hitbox.stance_damage_multiplier == 1.18, "ATK-05: Mountain applies 1.18x damage multiplier to hitbox")
	
	combat.finish_combat()
	
	# Verify Storm attack speed and damage
	stance_ctrl.set_stance(StanceData.StanceType.STORM)
	combat.start_light_attack()
	_assert(combat.hitbox.stance_damage_multiplier == 1.08, "ATK-06: Storm applies 1.08x damage multiplier to hitbox")
	
	combat.finish_combat()
	player.queue_free()

# 5. Poise Modifiers
func _test_05_poise_modifiers() -> void:
	print("\n--- Testing Poise Modifiers ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var stance_ctrl: StanceController = player.stance_controller
	var combat: CombatController = player.combat_controller
	
	stance_ctrl.set_stance(StanceData.StanceType.SWIFT)
	combat.start_light_attack()
	_assert(combat.hitbox.stance_poise_multiplier == 0.90, "POISE-01: Swift applies 0.90x poise damage multiplier")
	combat.finish_combat()
	
	stance_ctrl.set_stance(StanceData.StanceType.MOUNTAIN)
	combat.start_light_attack()
	_assert(combat.hitbox.stance_poise_multiplier == 1.30, "POISE-02: Mountain applies 1.30x poise damage multiplier")
	combat.finish_combat()
	
	stance_ctrl.set_stance(StanceData.StanceType.STORM)
	combat.start_light_attack()
	_assert(combat.hitbox.stance_poise_multiplier == 1.05, "POISE-03: Storm applies 1.05x poise damage multiplier")
	combat.finish_combat()
	
	player.queue_free()

# 6. Dodge Modifiers
func _test_06_dodge_modifiers() -> void:
	print("\n--- Testing Dodge Modifiers ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var stance_ctrl: StanceController = player.stance_controller
	var defense: DefenseController = player.defense_controller
	
	# Swift Dodge
	stance_ctrl.set_stance(StanceData.StanceType.SWIFT)
	defense.start_dodge(0.0, 1)
	var expected_swift_speed: float = defense.dodge_speed * 1.12
	_assert(absf(player.velocity.x - expected_swift_speed) < 0.01, "DODGE-01: Swift scales dodge velocity (1.12x)")
	defense.finish_dodge()
	
	# Mountain Dodge
	stance_ctrl.set_stance(StanceData.StanceType.MOUNTAIN)
	defense.start_dodge(0.0, 1)
	var expected_mtn_speed: float = defense.dodge_speed * 0.90
	_assert(absf(player.velocity.x - expected_mtn_speed) < 0.01, "DODGE-02: Mountain reduces dodge velocity (0.90x)")
	defense.finish_dodge()
	
	player.queue_free()

# 7. Parry Integration & Window Safety
func _test_07_parry_integration() -> void:
	print("\n--- Testing Parry Integration & Window Safety ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var stance_ctrl: StanceController = player.stance_controller
	var defense: DefenseController = player.defense_controller
	
	_assert(stance_ctrl.get_parry_window_multiplier() == 1.0, "PARRY-01: Parry window multiplier is 1.0 (strict precision timing preserved)")
	
	# Start parry and enter active parry window
	defense.start_parry()
	defense.process_parry(0.05)
	_assert(defense.is_in_parry_window(), "PARRY-02: Inside active parry window")
	_assert(not stance_ctrl.can_change_stance(), "PARRY-03: Stance switching is BLOCKED during active parry window")
	
	defense.finish_parry()
	_assert(stance_ctrl.can_change_stance(), "PARRY-04: Stance switching is ALLOWED once parry finishes")
	
	player.queue_free()

# 8. State Machine Safety Rules
func _test_08_state_machine_safety_rules() -> void:
	print("\n--- Testing State Machine Stance Switching Gatekeeping ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var stance_ctrl: StanceController = player.stance_controller
	var combat: CombatController = player.combat_controller
	var defense: DefenseController = player.defense_controller
	
	# Blocked during attack STARTUP
	combat.start_light_attack()
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.STARTUP, "SAFE-01: In attack STARTUP phase")
	_assert(not stance_ctrl.can_change_stance(), "SAFE-02: Stance switching is BLOCKED during attack STARTUP")
	_assert(not stance_ctrl.set_stance(StanceData.StanceType.MOUNTAIN), "SAFE-03: set_stance() returns false during STARTUP")
	
	# Blocked during attack ACTIVE
	combat.process_combat(0.08) # advance into active
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.ACTIVE, "SAFE-04: In attack ACTIVE phase")
	_assert(not stance_ctrl.can_change_stance(), "SAFE-05: Stance switching is BLOCKED during attack ACTIVE")
	
	# ALLOWED during attack RECOVERY
	combat.process_combat(0.08) # advance into recovery
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.RECOVERY, "SAFE-06: In attack RECOVERY phase")
	_assert(stance_ctrl.can_change_stance(), "SAFE-07: Stance switching is ALLOWED during attack RECOVERY")
	_assert(stance_ctrl.set_stance(StanceData.StanceType.MOUNTAIN), "SAFE-08: Stance successfully changes during RECOVERY")
	
	combat.finish_combat()
	
	# Blocked during Dodge I-frames
	defense.start_dodge(0.0, 1)
	defense.process_dodge(0.05) # inside I-frames (0.033s to 0.200s)
	_assert(defense.is_invulnerable_to_damage, "SAFE-09: Inside dodge invulnerability frames")
	_assert(not stance_ctrl.can_change_stance(), "SAFE-10: Stance switching is BLOCKED during dodge I-frames")
	defense.finish_dodge()
	
	# Blocked during Heavy Attack Charge
	combat.start_heavy_charge()
	_assert(combat.is_charging_heavy, "SAFE-11: Charging heavy attack")
	_assert(not stance_ctrl.can_change_stance(), "SAFE-12: Stance switching is BLOCKED while charging heavy attack")
	combat.cancel_combat()
	
	player.queue_free()

# 9. State Persistence
func _test_09_state_persistence() -> void:
	print("\n--- Testing State Persistence Across Stance Changes ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var stance_ctrl: StanceController = player.stance_controller
	var health: HealthComponent = player.health_component
	var poise: PoiseComponent = player.poise_component
	
	player.global_position = Vector2(250.0, -50.0)
	player.velocity = Vector2(120.0, 50.0)
	health.current_health = 75.0
	poise.current_poise = 30.0
	
	stance_ctrl.set_stance(StanceData.StanceType.MOUNTAIN)
	_assert(health.current_health == 75.0, "PERSIST-01: Health remains unchanged across stance switch")
	_assert(poise.current_poise == 30.0, "PERSIST-02: Poise remains unchanged across stance switch")
	_assert(player.global_position == Vector2(250.0, -50.0), "PERSIST-03: Position remains unchanged across stance switch")
	_assert(player.velocity == Vector2(120.0, 50.0), "PERSIST-04: Velocity is preserved across stance switch")
	
	player.queue_free()

# 10. Arena Room Loading
func _test_10_arena_room_loading() -> void:
	print("\n--- Testing Stance Sandbox Room Loading ---")
	var room_scene: PackedScene = load("res://scenes/world/test_stance_room.tscn")
	_assert(room_scene != null, "ROOM-01: test_stance_room.tscn loads successfully")
	
	var room: TestStanceRoom = room_scene.instantiate() as TestStanceRoom
	add_child(room)
	_assert(room.player != null, "ROOM-02: Arena contains Player instance")
	_assert(room.attacker != null, "ROOM-03: Arena contains CombatTrainingAttacker")
	_assert(room.dummy != null, "ROOM-04: Arena contains CombatTestDummy")
	_assert(room.stance_display != null, "ROOM-05: Arena contains Stance HUD display")
	
	room.queue_free()
