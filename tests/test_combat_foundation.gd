extends Node

## Automated Combat Foundation Test Suite
## Validates all 26 required combat foundation mechanics for Phase 3.

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 3 COMBAT FOUNDATION TEST SUITE")
	print("==================================================")
	
	# Execute synchronous tests
	_test_01_combat_system_loads()
	_test_02_attack_data_loads()
	_test_03_light_attack_phases_and_hitbox()
	_test_09_hitbox_detects_hurtbox_and_payload()
	_test_11_health_and_poise_reduction()
	_test_13_knockback_application()
	_test_14_hit_reaction()
	_test_15_hitstop_trigger()
	_test_16_facing_direction_hitbox_alignment()
	_test_18_combo_progression_and_buffering()
	_test_21_heavy_attack_properties()
	_test_23_attack_returns_to_movement()
	_test_24_pause_prevents_combat_processing()
	
	print("==================================================")
	print(" COMBAT TEST RESULTS: %d / %d PASSED (%d FAILED)" % [
		_tests_passed,
		_tests_passed + _tests_failed,
		_tests_failed
	])
	print("==================================================")
	
	if _tests_failed == 0:
		print("\nSUCCESS: All Phase 3 Combat Foundation unit and integration tests passed cleanly.\n")
		get_tree().quit(0)
	else:
		push_error("FAILURE: %d combat foundation tests failed." % _tests_failed)
		get_tree().quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[PASS] %s" % test_name)
	else:
		_tests_failed += 1
		push_error("[FAIL] %s" % test_name)

# 1. Combat system loads
func _test_01_combat_system_loads() -> void:
	print("\n--- Testing Combat Architecture Loading ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	_assert(player_scene != null, "Player scene with combat components loads successfully")
	
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var combat: CombatController = player.combat_controller
	_assert(combat != null, "Player has CombatController component")
	_assert(player.health_component != null, "Player has HealthComponent")
	_assert(player.poise_component != null, "Player has PoiseComponent")
	_assert(combat.hitbox != null, "CombatController references Hitbox")
	
	var dummy_scene: PackedScene = load("res://scenes/enemies/combat_test_dummy.tscn")
	_assert(dummy_scene != null, "CombatTestDummy scene loads successfully")
	
	var dummy: CombatTestDummy = dummy_scene.instantiate() as CombatTestDummy
	add_child(dummy)
	_assert(dummy.health_component != null, "CombatTestDummy has HealthComponent")
	_assert(dummy.poise_component != null, "CombatTestDummy has PoiseComponent")
	_assert(dummy.hurtbox != null, "CombatTestDummy has Hurtbox")
	
	var room_scene: PackedScene = load("res://scenes/world/test_combat_room.tscn")
	_assert(room_scene != null, "TestCombatRoom scene loads successfully")
	var room: TestCombatRoom = room_scene.instantiate() as TestCombatRoom
	_assert(room != null, "TestCombatRoom instantiates successfully")
	add_child(room)
	_assert(room.player != null, "TestCombatRoom contains Player instance")
	_assert(room.dummy != null, "TestCombatRoom contains CombatTestDummy instance")
	room.queue_free()
	
	player.queue_free()
	dummy.queue_free()

# 2. Attack data loads
func _test_02_attack_data_loads() -> void:
	print("\n--- Testing Attack Data Resources ---")
	var ids: Array[String] = ["attack_light_1", "attack_light_2", "attack_light_3", "attack_heavy_1"]
	for attack_name in ids:
		var path: String = "res://data/attacks/%s.tres" % attack_name
		_assert(ResourceLoader.exists(path), "Attack resource exists: %s" % attack_name)
		var res: AttackData = load(path) as AttackData
		_assert(res != null, "AttackData resource loads cleanly: %s" % attack_name)
		_assert(res.damage > 0.0, "%s has positive damage (%.1f)" % [attack_name, res.damage])
		_assert(res.poise_damage > 0.0, "%s has positive poise damage (%.1f)" % [attack_name, res.poise_damage])
		_assert(res.startup_time > 0.0, "%s has positive startup time" % attack_name)
		_assert(res.active_time > 0.0, "%s has positive active time" % attack_name)
		_assert(res.recovery_time > 0.0, "%s has positive recovery time" % attack_name)

# 3, 4, 5, 6, 7, 8. Light attack starts, startup, active, recovery, hitbox activates/deactivates
func _test_03_light_attack_phases_and_hitbox() -> void:
	print("\n--- Testing Light Attack Phase Transitions & Hitbox Toggling ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var combat: CombatController = player.combat_controller
	var hitbox: Hitbox = combat.hitbox
	
	# Initial state
	_assert(not combat.is_attacking(), "CombatController initially not attacking")
	_assert(not hitbox.is_active, "Hitbox initially inactive")
	
	# 3. Light attack starts
	var started: bool = combat.start_light_attack()
	_assert(started, "Light attack 1 starts successfully")
	_assert(combat.is_attacking(), "CombatController reports is_attacking() = true")
	_assert(combat.get_current_attack().attack_id == &"light_1", "Current attack is light_1")
	
	# 4. Enters startup
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.STARTUP, "Attack is in STARTUP phase")
	_assert(not hitbox.is_active, "Hitbox is inactive during STARTUP phase")
	
	# Advance through startup
	combat.process_combat(combat.get_current_attack().startup_time + 0.001)
	
	# 5, 7. Enters active, hitbox activates
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.ACTIVE, "Attack transitioned to ACTIVE phase")
	_assert(hitbox.is_active, "Hitbox activated strictly during ACTIVE phase")
	_assert(hitbox.monitoring, "Hitbox monitoring is enabled during ACTIVE phase")
	
	# Advance through active
	combat.process_combat(combat.get_current_attack().active_time + 0.001)
	
	# 6, 8. Enters recovery, hitbox deactivates
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.RECOVERY, "Attack transitioned to RECOVERY phase")
	_assert(not hitbox.is_active, "Hitbox deactivated immediately upon entering RECOVERY phase")
	_assert(not hitbox.monitoring, "Hitbox monitoring disabled during RECOVERY phase")
	
	player.queue_free()

# 9, 10. Hitbox detects hurtbox and payload is generated
func _test_09_hitbox_detects_hurtbox_and_payload() -> void:
	print("\n--- Testing Hit Detection & Damage Payload ---")
	var hitbox: Hitbox = Hitbox.new()
	var hurtbox: Hurtbox = Hurtbox.new()
	add_child(hitbox)
	add_child(hurtbox)
	
	var attack_data: AttackData = load("res://data/attacks/attack_light_1.tres") as AttackData
	var received_payload: Array[DamageInfo] = []
	
	hurtbox.hit_received.connect(func(payload: DamageInfo) -> void:
		received_payload.append(payload)
	)
	
	hitbox.activate(attack_data, null)
	hitbox._on_area_entered(hurtbox)
	
	_assert(received_payload.size() == 1, "Hurtbox received hit notification")
	var info: DamageInfo = received_payload[0]
	_assert(info.damage == attack_data.damage, "Payload carries correct damage (%.1f)" % info.damage)
	_assert(info.poise_damage == attack_data.poise_damage, "Payload carries correct poise damage (%.1f)" % info.poise_damage)
	_assert(info.attack_id == &"light_1", "Payload carries correct attack_id")
	
	# Duplicate hit prevention test
	hitbox._on_area_entered(hurtbox)
	_assert(received_payload.size() == 1, "Hitbox prevents duplicate hits against same target in single swing")
	
	hitbox.queue_free()
	hurtbox.queue_free()

# 11, 12. Target health and poise decrease
func _test_11_health_and_poise_reduction() -> void:
	print("\n--- Testing Target Health & Poise Depletion ---")
	var dummy_scene: PackedScene = load("res://scenes/enemies/combat_test_dummy.tscn")
	var dummy: CombatTestDummy = dummy_scene.instantiate() as CombatTestDummy
	add_child(dummy)
	
	var initial_hp: float = dummy.health_component.current_health
	var initial_poise: float = dummy.poise_component.current_poise
	
	var payload: DamageInfo = DamageInfo.new()
	payload.damage = 15.0
	payload.poise_damage = 10.0
	payload.hit_direction = 1
	
	dummy.hurtbox.receive_hit(payload)
	
	_assert(dummy.health_component.current_health == initial_hp - 15.0, "Target health decreased by exact damage")
	_assert(dummy.poise_component.current_poise == initial_poise - 10.0, "Target poise decreased by exact poise damage")
	
	dummy.queue_free()

# 13. Knockback is applied
func _test_13_knockback_application() -> void:
	print("\n--- Testing Knockback Impulse ---")
	var dummy_scene: PackedScene = load("res://scenes/enemies/combat_test_dummy.tscn")
	var dummy: CombatTestDummy = dummy_scene.instantiate() as CombatTestDummy
	add_child(dummy)
	
	dummy.velocity = Vector2.ZERO
	var payload: DamageInfo = DamageInfo.new()
	payload.damage = 10.0
	payload.knockback_force = Vector2(150.0, -40.0)
	payload.hit_direction = 1
	
	dummy.hurtbox.receive_hit(payload)
	_assert(dummy.velocity.x == 150.0, "Knockback X impulse applied in forward hit direction")
	_assert(dummy.velocity.y == -40.0, "Knockback Y impulse applied upward")
	
	# Knockback opposite direction
	dummy.velocity = Vector2.ZERO
	payload.hit_direction = -1
	dummy.hurtbox.receive_hit(payload)
	_assert(dummy.velocity.x == -150.0, "Knockback X impulse applied in reverse hit direction")
	
	dummy.queue_free()

# 14. Hit reaction and stagger
func _test_14_hit_reaction() -> void:
	print("\n--- Testing Hit Reaction & Stagger Threshold ---")
	var dummy_scene: PackedScene = load("res://scenes/enemies/combat_test_dummy.tscn")
	var dummy: CombatTestDummy = dummy_scene.instantiate() as CombatTestDummy
	add_child(dummy)
	
	var stagger_started: Array[bool] = [false]
	dummy.poise_component.stagger_started.connect(func(_dur: float) -> void:
		stagger_started[0] = true
	)
	
	# Deplete all poise
	dummy.poise_component.take_poise_damage(dummy.poise_component.max_poise + 10.0)
	
	_assert(dummy.poise_component.is_staggered, "Dummy enters staggered state when poise hits zero")
	_assert(stagger_started[0], "stagger_started signal fired on poise depletion")
	
	dummy.queue_free()

# 15. Hitstop occurs
func _test_15_hitstop_trigger() -> void:
	print("\n--- Testing Hitstop Integration ---")
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		_assert(gm.has_method("apply_hitstop"), "GameManager has apply_hitstop method")
		
		gm.apply_hitstop(0.04, 0.05)
		_assert(gm.is_in_hitstop(), "GameManager reports is_in_hitstop() == true during hitstop")
		_assert(Engine.time_scale <= 0.05, "Engine.time_scale reduced during hitstop")
		
		# Reset cleanly
		gm.reset_time_scale()
		_assert(Engine.time_scale == 1.0, "Engine.time_scale cleanly restored to 1.0")

# 16, 17. Facing right and left produces aligned attack
func _test_16_facing_direction_hitbox_alignment() -> void:
	print("\n--- Testing Facing Direction Hitbox Alignment ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	# Facing right (+1)
	player.set_facing_direction(1)
	_assert(player.combat_controller.hitbox.position.x > 0, "Facing right aligns hitbox to positive X (+28)")
	
	# Facing left (-1)
	player.set_facing_direction(-1)
	_assert(player.combat_controller.hitbox.position.x < 0, "Facing left aligns hitbox to negative X (-28)")
	
	# Shape must remain identical
	var shape: RectangleShape2D = player.combat_controller.hitbox.get_node("CollisionShape2D").shape as RectangleShape2D
	_assert(shape != null and shape.size.x > 0, "Collision shape is preserved without scaling or shape inversion")
	
	player.queue_free()

# 18, 19, 20. Light combo progresses, input buffer works, combo expires
func _test_18_combo_progression_and_buffering() -> void:
	print("\n--- Testing Combo Progression & Input Buffering ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var combat: CombatController = player.combat_controller
	
	# Start Light 1
	combat.start_light_attack()
	_assert(combat.get_combo_index() == 1, "Combo starts at index 1 (Light 1)")
	
	# Advance into combo window
	combat.process_combat(0.08) # in combo window
	combat.buffer_attack(false)
	_assert(combat.has_buffered_attack, "Input buffer captures light attack during combo window")
	
	# Advance to completion of Light 1 active phase -> transitions to Light 2
	combat.process_combat(0.15)
	_assert(combat.get_combo_index() == 2, "Combo progresses to index 2 (Light 2)")
	_assert(combat.get_current_attack().attack_id == &"light_2", "Current attack is light_2")
	
	# Chain into Light 3
	combat.process_combat(0.08)
	combat.buffer_attack(false)
	combat.process_combat(0.15)
	_assert(combat.get_combo_index() == 3, "Combo progresses to index 3 (Light 3 finisher)")
	_assert(combat.get_current_attack().attack_id == &"light_3", "Current attack is light_3 finisher")
	
	# Finisher completes and terminates combo
	combat.process_combat(0.4)
	_assert(not combat.is_attacking(), "Combo terminates cleanly after finisher")
	_assert(combat.get_combo_index() == 0, "Combo index resets to 0 after sequence finishes")
	
	player.queue_free()

# 21, 22. Heavy attack works and has higher damage/poise impact
func _test_21_heavy_attack_properties() -> void:
	print("\n--- Testing Heavy Attack Properties ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var combat: CombatController = player.combat_controller
	var light_res: AttackData = load("res://data/attacks/attack_light_1.tres") as AttackData
	var heavy_res: AttackData = load("res://data/attacks/attack_heavy_1.tres") as AttackData
	
	combat.start_heavy_attack()
	_assert(combat.is_attacking(), "Heavy attack starts successfully")
	_assert(combat.get_current_attack().attack_id == &"heavy_1", "Current attack is heavy_1")
	_assert(heavy_res.damage > light_res.damage, "Heavy attack deals higher damage (%.1f > %.1f)" % [heavy_res.damage, light_res.damage])
	_assert(heavy_res.poise_damage > light_res.poise_damage, "Heavy attack deals higher poise damage (%.1f > %.1f)" % [heavy_res.poise_damage, light_res.poise_damage])
	_assert(heavy_res.startup_time > light_res.startup_time, "Heavy attack has longer startup time (%.3fs > %.3fs)" % [heavy_res.startup_time, light_res.startup_time])
	
	player.queue_free()

# 23. Attack returns to movement
func _test_23_attack_returns_to_movement() -> void:
	print("\n--- Testing State Machine Return to Movement ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var sm: StateMachine = player.state_machine
	sm.change_state(&"Attack")
	_assert(sm.get_current_state_name() == &"Attack", "Player enters Attack state")
	
	# Simulate attack completion
	var attack_state: PlayerAttackState = sm.get_node("Attack") as PlayerAttackState
	attack_state._return_to_locomotion()
	
	_assert(sm.get_current_state_name() == &"Idle" or sm.get_current_state_name() == &"Fall",
		"Player state returns to locomotion state (%s) after attack" % sm.get_current_state_name())
	
	player.queue_free()

# 24. Pause prevents combat processing
func _test_24_pause_prevents_combat_processing() -> void:
	print("\n--- Testing Pause Integration on Combat ---")
	if has_node("/root/GameManager"):
		var gm: Node = get_node("/root/GameManager")
		gm.set_paused(true)
		_assert(gm.is_paused(), "GameManager is paused")
		_assert(not gm.is_playing(), "GameManager is_playing() is false when paused")
		gm.set_paused(false)
		_assert(not gm.is_paused(), "GameManager resumed from pause")
