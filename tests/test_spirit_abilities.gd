extends Node

## Automated Spirit Abilities Test Suite
## Validates all required Phase 6 criteria:
## SpiritComponent, AbilityData resources, SpiritAbilityController, Cooldowns,
## Celestial Arc projectile, Heavenly Pulse AoE, Cloud Step mobility and geometry safety,
## State Machine gatekeeping, Stance invariance, and Combat spirit restoration.

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 6 SPIRIT ABILITIES TEST SUITE")
	print("==================================================")
	
	_test_01_spirit_component()
	_test_02_ability_data_resources()
	_test_03_ability_controller_lifecycle_and_cooldowns()
	_test_04_celestial_arc_projectile()
	_test_05_heavenly_pulse_area_attack()
	_test_06_cloud_step_mobility_and_collision()
	_test_07_state_gatekeeping_rules()
	_test_08_stance_integration_and_invariance()
	_test_09_combat_spirit_gain_pipeline()
	_test_10_spirit_arena_room_loading()
	
	print("==================================================")
	print(" SPIRIT ABILITIES TEST RESULTS: %d / %d PASSED (%d FAILED)" % [
		_tests_passed,
		_tests_passed + _tests_failed,
		_tests_failed
	])
	print("==================================================")
	
	if _tests_failed == 0:
		print("\nSUCCESS: All Phase 6 Spirit Abilities tests passed cleanly.\n")
		get_tree().quit(0)
	else:
		push_error("FAILURE: %d spirit ability tests failed." % _tests_failed)
		get_tree().quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[PASS] %s" % test_name)
	else:
		_tests_failed += 1
		push_error("[FAIL] %s" % test_name)

# 1. Spirit Component
func _test_01_spirit_component() -> void:
	print("\n--- Testing Spirit Component ---")
	var spirit: SpiritComponent = SpiritComponent.new()
	add_child(spirit)
	
	_assert(spirit.get_max_spirit() == 100.0, "SPIRIT-01: Maximum Spirit is 100.0")
	_assert(spirit.get_spirit() == 100.0, "SPIRIT-02: Current Spirit defaults to 100.0")
	_assert(spirit.get_spirit_ratio() == 1.0, "SPIRIT-03: Initial spirit ratio is 1.0")
	
	# Consume spirit
	var consumed: bool = spirit.consume_spirit(20.0)
	_assert(consumed, "SPIRIT-04: consume_spirit(20.0) succeeds")
	_assert(spirit.get_spirit() == 80.0, "SPIRIT-05: Current spirit is 80.0 after 20 consumed")
	
	# Rejection on insufficient spirit
	var rejected: bool = spirit.consume_spirit(90.0)
	_assert(not rejected, "SPIRIT-06: Insufficient spirit request is rejected")
	_assert(spirit.get_spirit() == 80.0, "SPIRIT-07: Spirit balance unchanged after rejection")
	
	# Restore spirit
	spirit.restore_spirit(15.0)
	_assert(spirit.get_spirit() == 95.0, "SPIRIT-08: restore_spirit(15.0) increases balance to 95.0")
	
	# Upper clamp
	spirit.restore_spirit(30.0)
	_assert(spirit.get_spirit() == 100.0, "SPIRIT-09: Spirit balance clamped at maximum (100.0)")
	
	# Lower clamp / Depletion
	var signal_received: Array[bool] = [false]
	spirit.spirit_changed.connect(func(_c: float, _m: float) -> void: signal_received[0] = true)
	spirit.consume_spirit(100.0)
	_assert(spirit.get_spirit() == 0.0, "SPIRIT-10: Spirit balance drops to 0.0 on full consumption")
	_assert(signal_received[0], "SPIRIT-11: spirit_changed signal emitted on consumption")
	
	spirit.queue_free()

# 2. Ability Data Resources
func _test_02_ability_data_resources() -> void:
	print("\n--- Testing Ability Data Resources ---")
	var arc_res: SpiritAbilityData = load("res://data/abilities/ability_celestial_arc.tres") as SpiritAbilityData
	_assert(arc_res != null, "DATA-01: Celestial Arc resource loads cleanly")
	if arc_res != null:
		_assert(arc_res.spirit_cost == 20.0, "DATA-02: Celestial Arc spirit cost is 20.0")
		_assert(arc_res.cooldown == 2.0, "DATA-03: Celestial Arc cooldown is 2.0s")
		_assert(arc_res.damage == 18.0, "DATA-04: Celestial Arc damage is 18.0")
		_assert(arc_res.ability_type == SpiritAbilityData.AbilityType.PROJECTILE, "DATA-05: Celestial Arc is PROJECTILE type")
	
	var pulse_res: SpiritAbilityData = load("res://data/abilities/ability_heavenly_pulse.tres") as SpiritAbilityData
	_assert(pulse_res != null, "DATA-06: Heavenly Pulse resource loads cleanly")
	if pulse_res != null:
		_assert(pulse_res.spirit_cost == 30.0, "DATA-07: Heavenly Pulse spirit cost is 30.0")
		_assert(pulse_res.cooldown == 4.0, "DATA-08: Heavenly Pulse cooldown is 4.0s")
		_assert(pulse_res.damage == 24.0, "DATA-09: Heavenly Pulse damage is 24.0")
		_assert(pulse_res.poise_damage == 35.0, "DATA-10: Heavenly Pulse poise damage is 35.0")
		_assert(pulse_res.ability_type == SpiritAbilityData.AbilityType.AREA, "DATA-11: Heavenly Pulse is AREA type")
	
	var step_res: SpiritAbilityData = load("res://data/abilities/ability_cloud_step.tres") as SpiritAbilityData
	_assert(step_res != null, "DATA-12: Cloud Step resource loads cleanly")
	if step_res != null:
		_assert(step_res.spirit_cost == 25.0, "DATA-13: Cloud Step spirit cost is 25.0")
		_assert(step_res.cooldown == 5.0, "DATA-14: Cloud Step cooldown is 5.0s")
		_assert(step_res.ability_type == SpiritAbilityData.AbilityType.MOBILITY, "DATA-15: Cloud Step is MOBILITY type")

# 3. Ability Controller Lifecycle & Cooldowns
func _test_03_ability_controller_lifecycle_and_cooldowns() -> void:
	print("\n--- Testing Ability Controller Lifecycle & Cooldowns ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var ability_ctrl: SpiritAbilityController = player.spirit_ability_controller
	var spirit_comp: SpiritComponent = player.spirit_component
	
	_assert(ability_ctrl != null, "CTRL-01: Player has SpiritAbilityController component")
	_assert(spirit_comp != null, "CTRL-02: Player has SpiritComponent attached")
	_assert(ability_ctrl.ability_slots.size() >= 3, "CTRL-03: Controller has 3 default ability slots configured")
	
	# Trigger slot 0 (Celestial Arc, cost 20)
	var started: bool = ability_ctrl.trigger_ability_slot(0)
	_assert(started, "CTRL-04: trigger_ability_slot(0) succeeds")
	_assert(spirit_comp.get_spirit() == 80.0, "CTRL-05: Spirit consumed exactly once (100 -> 80)")
	_assert(ability_ctrl.is_casting, "CTRL-06: is_casting is true")
	_assert(ability_ctrl.current_phase == SpiritAbilityController.AbilityPhase.STARTUP, "CTRL-07: Phase starts in STARTUP")
	_assert(not ability_ctrl.is_ability_ready(&"celestial_arc"), "CTRL-08: Celestial Arc is on cooldown")
	
	# Attempt duplicate cast while casting (busy)
	var duplicate_attempt: bool = ability_ctrl.trigger_ability_slot(0)
	_assert(not duplicate_attempt, "CTRL-09: Duplicate cast attempt while busy is rejected")
	
	# Advance through ACTIVE and RECOVERY to finish
	ability_ctrl.process_ability(0.10) # to active
	_assert(ability_ctrl.current_phase == SpiritAbilityController.AbilityPhase.ACTIVE, "CTRL-10: Advances to ACTIVE phase")
	ability_ctrl.process_ability(0.10) # to recovery
	_assert(ability_ctrl.current_phase == SpiritAbilityController.AbilityPhase.RECOVERY, "CTRL-11: Advances to RECOVERY phase")
	ability_ctrl.process_ability(0.20) # to finish
	_assert(not ability_ctrl.is_casting, "CTRL-12: Casting finishes cleanly")
	_assert(ability_ctrl.current_phase == SpiritAbilityController.AbilityPhase.READY, "CTRL-13: Controller returns to READY phase")
	
	# Check Cooldown countdown
	_assert(ability_ctrl.get_cooldown_remaining(&"celestial_arc") > 1.0, "CTRL-14: Cooldown remaining > 1.0s")
	ability_ctrl._process(2.0)
	_assert(ability_ctrl.is_ability_ready(&"celestial_arc"), "CTRL-15: Cooldown expires cleanly after duration")
	
	player.queue_free()

# 4. Celestial Arc Projectile
func _test_04_celestial_arc_projectile() -> void:
	print("\n--- Testing Celestial Arc Projectile ---")
	var proj_scene: PackedScene = load("res://scenes/effects/spirit_projectile.tscn")
	_assert(proj_scene != null, "ARC-01: spirit_projectile.tscn loads successfully")
	
	var proj: SpiritProjectile = proj_scene.instantiate() as SpiritProjectile
	add_child(proj)
	
	var arc_res: SpiritAbilityData = load("res://data/abilities/ability_celestial_arc.tres") as SpiritAbilityData
	proj.launch(arc_res, Vector2(100, 100), 1, null)
	
	_assert(proj.direction == 1, "ARC-02: Projectile direction set to +1 (Right)")
	_assert(proj.scale.x == 1.0, "ARC-03: Visual scale matches right facing (+1)")
	
	# Movement progression
	var initial_x: float = proj.global_position.x
	proj._physics_process(0.1)
	_assert(proj.global_position.x > initial_x, "ARC-04: Projectile moves horizontally along facing vector")
	
	# Facing Left test
	var proj_left: SpiritProjectile = proj_scene.instantiate() as SpiritProjectile
	add_child(proj_left)
	proj_left.launch(arc_res, Vector2(100, 100), -1, null)
	_assert(proj_left.direction == -1, "ARC-05: Projectile direction set to -1 (Left)")
	_assert(proj_left.scale.x == -1.0, "ARC-06: Visual scale matches left facing (-1)")
	
	# Hit detection on Hurtbox
	var dummy_scene: PackedScene = load("res://scenes/enemies/combat_test_dummy.tscn")
	var dummy: CombatTestDummy = dummy_scene.instantiate() as CombatTestDummy
	dummy.position = Vector2(150, 100)
	add_child(dummy)
	
	var initial_dummy_hp: float = dummy.health_component.current_health
	var initial_dummy_poise: float = dummy.poise_component.current_poise
	
	# Simulate collision
	proj._on_area_entered(dummy.hurtbox)
	_assert(dummy.health_component.current_health == initial_dummy_hp - arc_res.damage, "ARC-07: Projectile deals 18.0 damage to target")
	_assert(dummy.poise_component.current_poise == initial_dummy_poise - arc_res.poise_damage, "ARC-08: Projectile deals 15.0 poise damage to target")
	
	# Verify single hit rule (duplicate entry ignored)
	proj._on_area_entered(dummy.hurtbox)
	_assert(dummy.health_component.current_health == initial_dummy_hp - arc_res.damage, "ARC-09: Target cannot receive duplicate hit from same projectile")
	
	proj.queue_free()
	proj_left.queue_free()
	dummy.queue_free()

# 5. Heavenly Pulse Area Attack
func _test_05_heavenly_pulse_area_attack() -> void:
	print("\n--- Testing Heavenly Pulse Area Attack ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	player.position = Vector2(200, 200)
	add_child(player)
	
	var dummy_scene: PackedScene = load("res://scenes/enemies/combat_test_dummy.tscn")
	
	# Dummy 1: Nearby at (230, 200) -> distance 30px <= 64px radius
	var dummy_near1: CombatTestDummy = dummy_scene.instantiate() as CombatTestDummy
	dummy_near1.position = Vector2(230, 200)
	add_child(dummy_near1)
	dummy_near1.poise_component.max_poise = 50.0
	dummy_near1.poise_component.current_poise = 50.0
	
	# Dummy 2: Nearby at (170, 200) -> distance 30px <= 64px radius
	var dummy_near2: CombatTestDummy = dummy_scene.instantiate() as CombatTestDummy
	dummy_near2.position = Vector2(170, 200)
	add_child(dummy_near2)
	
	# Dummy 3: Distant at (350, 200) -> distance 150px > 64px radius
	var dummy_far: CombatTestDummy = dummy_scene.instantiate() as CombatTestDummy
	dummy_far.position = Vector2(350, 200)
	add_child(dummy_far)
	
	var pulse_res: SpiritAbilityData = load("res://data/abilities/ability_heavenly_pulse.tres") as SpiritAbilityData
	var ability_ctrl: SpiritAbilityController = player.spirit_ability_controller
	
	# Trigger Heavenly Pulse (slot 1)
	var started: bool = ability_ctrl.trigger_ability_slot(1)
	_assert(started, "PULSE-01: Heavenly Pulse activates successfully")
	
	# Advance to ACTIVE to trigger shockwave
	ability_ctrl.process_ability(pulse_res.startup_time + 0.01)
	_assert(ability_ctrl.current_phase == SpiritAbilityController.AbilityPhase.ACTIVE, "PULSE-02: Enters ACTIVE phase")
	
	# Verify near targets took damage, distant target unaffected
	_assert(dummy_near1.health_component.current_health == 100.0 - pulse_res.damage, "PULSE-03: Near target 1 damaged (100 -> 76)")
	_assert(dummy_near2.health_component.current_health == 100.0 - pulse_res.damage, "PULSE-04: Near target 2 damaged (100 -> 76)")
	_assert(dummy_far.health_component.current_health == 100.0, "PULSE-05: Distant target untouched by area shockwave")
	_assert(dummy_near1.poise_component.current_poise == 50.0 - pulse_res.poise_damage, "PULSE-06: Heavy poise damage applied (50 -> 15)")
	
	# Verify single-hit rule
	ability_ctrl.process_ability(0.02)
	_assert(dummy_near1.health_component.current_health == 100.0 - pulse_res.damage, "PULSE-07: Near target not damaged repeatedly during active window")
	
	player.queue_free()
	dummy_near1.queue_free()
	dummy_near2.queue_free()
	dummy_far.queue_free()

# 6. Cloud Step Mobility & Collision
func _test_06_cloud_step_mobility_and_collision() -> void:
	print("\n--- Testing Cloud Step Mobility & Collision ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	player.position = Vector2(100, 200)
	add_child(player)
	
	var ability_ctrl: SpiritAbilityController = player.spirit_ability_controller
	var step_res: SpiritAbilityData = load("res://data/abilities/ability_cloud_step.tres") as SpiritAbilityData
	
	# Trigger Cloud Step (slot 2)
	var started: bool = ability_ctrl.trigger_ability_slot(2)
	_assert(started, "STEP-01: Cloud Step triggers successfully")
	_assert(ability_ctrl.current_ability == step_res, "STEP-02: Current ability is Cloud Step")
	
	# Advance into ACTIVE phase
	ability_ctrl.process_ability(step_res.startup_time + 0.01)
	_assert(ability_ctrl.current_phase == SpiritAbilityController.AbilityPhase.ACTIVE, "STEP-03: Enters ACTIVE phase")
	_assert(player.velocity.x == 550.0, "STEP-04: Burst velocity of 550.0 px/s applied")
	
	# Cloud Step does NOT grant automatic I-frames or perfect dodge
	var defense: DefenseController = player.defense_controller
	_assert(not defense.is_dodging, "STEP-05: Cloud Step does not activate normal dodge")
	_assert(not defense.is_invulnerable_to_damage, "STEP-06: Cloud Step does not grant automatic I-frames")
	
	# Verify wall collision preservation (CharacterBody2D collision remains active)
	_assert(player.collision_mask == 1, "STEP-07: World collision mask is preserved")
	
	player.queue_free()

# 7. State Gatekeeping Rules
func _test_07_state_gatekeeping_rules() -> void:
	print("\n--- Testing State Gatekeeping Rules ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var combat: CombatController = player.combat_controller
	var defense: DefenseController = player.defense_controller
	var ability_ctrl: SpiritAbilityController = player.spirit_ability_controller
	var arc_res: SpiritAbilityData = load("res://data/abilities/ability_celestial_arc.tres") as SpiritAbilityData
	
	# 1. Blocked during attack STARTUP
	combat.start_light_attack()
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.STARTUP, "SAFE-01: In attack STARTUP phase")
	_assert(not ability_ctrl.can_cast_ability(arc_res), "SAFE-02: Ability cast is BLOCKED during attack STARTUP")
	
	# 2. Blocked during attack ACTIVE
	combat.process_combat(0.08)
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.ACTIVE, "SAFE-03: In attack ACTIVE phase")
	_assert(not ability_ctrl.can_cast_ability(arc_res), "SAFE-04: Ability cast is BLOCKED during attack ACTIVE")
	
	# 3. Allowed during attack RECOVERY
	combat.process_combat(0.08)
	_assert(combat.get_attack_phase() == CombatController.AttackPhase.RECOVERY, "SAFE-05: In attack RECOVERY phase")
	_assert(ability_ctrl.can_cast_ability(arc_res), "SAFE-06: Ability cast is ALLOWED during attack RECOVERY")
	combat.finish_combat()
	
	# 4. Blocked during dodge I-frames
	defense.start_dodge(0.0, 1)
	defense.process_dodge(0.06)
	_assert(defense.is_invulnerable_to_damage, "SAFE-07: In dodge I-frame window")
	_assert(not ability_ctrl.can_cast_ability(arc_res), "SAFE-08: Ability cast is BLOCKED during dodge I-frames")
	defense.finish_dodge()
	
	# 5. Blocked during active parry window
	defense.start_parry()
	defense.process_parry(0.06)
	_assert(defense.is_in_parry_window(), "SAFE-09: In active parry window")
	_assert(not ability_ctrl.can_cast_ability(arc_res), "SAFE-10: Ability cast is BLOCKED during active parry window")
	defense.finish_parry()
	
	# 6. Neutral cast works
	_assert(ability_ctrl.can_cast_ability(arc_res), "SAFE-11: Neutral ability cast is ALLOWED")
	
	player.queue_free()

# 8. Stance Integration & Invariance
func _test_08_stance_integration_and_invariance() -> void:
	print("\n--- Testing Stance Integration & Invariance ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var stance_ctrl: StanceController = player.stance_controller
	var ability_ctrl: SpiritAbilityController = player.spirit_ability_controller
	var arc_res: SpiritAbilityData = load("res://data/abilities/ability_celestial_arc.tres") as SpiritAbilityData
	
	# Swift stance
	stance_ctrl.set_stance(StanceData.StanceType.SWIFT)
	_assert(ability_ctrl.can_cast_ability(arc_res), "STANCE-01: Swift stance can cast abilities")
	_assert(arc_res.damage == 18.0, "STANCE-02: Base ability damage stable in Swift (18.0)")
	_assert(arc_res.spirit_cost == 20.0, "STANCE-03: Base spirit cost stable in Swift (20.0)")
	
	# Mountain stance
	stance_ctrl.set_stance(StanceData.StanceType.MOUNTAIN)
	_assert(ability_ctrl.can_cast_ability(arc_res), "STANCE-04: Mountain stance can cast abilities")
	_assert(arc_res.damage == 18.0, "STANCE-05: Base ability damage stable in Mountain (18.0)")
	_assert(arc_res.spirit_cost == 20.0, "STANCE-06: Base spirit cost stable in Mountain (20.0)")
	
	# Storm stance
	stance_ctrl.set_stance(StanceData.StanceType.STORM)
	_assert(ability_ctrl.can_cast_ability(arc_res), "STANCE-07: Storm stance can cast abilities")
	_assert(arc_res.damage == 18.0, "STANCE-08: Base ability damage stable in Storm (18.0)")
	_assert(arc_res.spirit_cost == 20.0, "STANCE-09: Base spirit cost stable in Storm (20.0)")
	
	player.queue_free()

# 9. Combat Spirit Gain Pipeline
func _test_09_combat_spirit_gain_pipeline() -> void:
	print("\n--- Testing Combat Spirit Gain Pipeline ---")
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var spirit_comp: SpiritComponent = player.spirit_component
	var combat: CombatController = player.combat_controller
	
	# Drop spirit to 50
	spirit_comp.set_spirit(50.0)
	_assert(spirit_comp.get_spirit() == 50.0, "GAIN-01: Spirit initialized to 50.0")
	
	# Simulate light hit reward (+4.0)
	var dummy_scene: PackedScene = load("res://scenes/enemies/combat_test_dummy.tscn")
	var dummy: CombatTestDummy = dummy_scene.instantiate() as CombatTestDummy
	add_child(dummy)
	
	var dmg_info: DamageInfo = DamageInfo.new()
	dmg_info.damage = 10.0
	dmg_info.is_charge_attack = false
	
	combat.hitbox.hit_connected.emit(dummy.hurtbox, dmg_info)
	_assert(spirit_comp.get_spirit() == 54.0, "GAIN-02: Light combat hit restores 4.0 Spirit (50 -> 54)")
	
	# Simulate heavy hit reward (+8.0)
	dmg_info.is_charge_attack = true
	combat.hitbox.hit_connected.emit(dummy.hurtbox, dmg_info)
	_assert(spirit_comp.get_spirit() == 62.0, "GAIN-03: Heavy combat hit restores 8.0 Spirit (54 -> 62)")
	
	# Simulate perfect parry reward (+10.0)
	var defense: DefenseController = player.defense_controller
	defense.perfect_parry.emit(dummy)
	_assert(spirit_comp.get_spirit() == 72.0, "GAIN-04: Perfect parry restores 10.0 Spirit (62 -> 72)")
	
	player.queue_free()
	dummy.queue_free()

# 10. Spirit Arena Room Loading
func _test_10_spirit_arena_room_loading() -> void:
	print("\n--- Testing Spirit Arena Room Loading ---")
	var room_scene: PackedScene = load("res://scenes/world/test_spirit_room.tscn")
	_assert(room_scene != null, "ROOM-01: test_spirit_room.tscn loads successfully")
	
	var room: TestSpiritRoom = room_scene.instantiate() as TestSpiritRoom
	add_child(room)
	
	_assert(room.player != null, "ROOM-02: Room contains PlayerController instance")
	_assert(room.dummy1 != null, "ROOM-03: Room contains CombatTestDummy1")
	_assert(room.dummy2 != null, "ROOM-04: Room contains CombatTestDummy2")
	_assert(room.dummy3 != null, "ROOM-05: Room contains CombatTestDummy3 (behind obstacle wall)")
	_assert(room.attacker != null, "ROOM-06: Room contains CombatTrainingAttacker")
	_assert(room.spirit_hud != null, "ROOM-07: Room contains SpiritHUD")
	
	room.queue_free()
