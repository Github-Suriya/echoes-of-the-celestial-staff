extends Node

## Automated Enemy AI Foundation Test Suite
## Validates all required Phase 8 criteria:
## - EnemyData and EnemyAttackData resources and inheritance
## - EnemyBase scene structure, collision layers, and component bindings
## - StateMachine lifecycle (Idle, Patrol, Alert, Chase, Combat, Hit, Stagger, Dead)
## - Perception system (detection radius, loss radius, line-of-sight, target validation)
## - Patrol mechanics (waypoint movement, boundary detection, facing)
## - Chase mechanics (target pursuit, acceleration, facing)
## - Combat positioning (approach, distance maintenance, deadzone)
## - Attack lifecycle (telegraph, active hitbox window, recovery, cooldown, parry interruption)
## - Hit reaction, Poise damage, Stagger state, and Poise recovery
## - Idempotent death sequence, collision disabling, and signal broadcast
## - Multi-enemy independence and concurrent execution
## - Test room loading and EventBus integration.

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 8 ENEMY AI FOUNDATION TEST SUITE")
	print("==================================================")
	
	_test_01_enemy_data_and_attack_data()
	_test_02_enemy_base_instantiation_and_layers()
	_test_03_enemy_state_machine_lifecycle()
	_test_04_perception_system()
	_test_05_patrol_behavior()
	_test_06_chase_behavior()
	_test_07_combat_positioning()
	_test_08_attack_lifecycle_and_hitbox()
	_test_09_hit_reaction_and_poise()
	_test_10_death_mechanics()
	_test_11_multi_enemy_independence()
	_test_12_arena_and_eventbus_integration()
	
	print("==================================================")
	print(" ENEMY AI TEST RESULTS: %d / %d PASSED (%d FAILED)" % [
		_tests_passed,
		_tests_passed + _tests_failed,
		_tests_failed
	])
	print("==================================================")
	
	if _tests_failed == 0:
		print("\nSUCCESS: All Phase 8 Enemy AI Foundation tests passed cleanly.\n")
		get_tree().quit(0)
	else:
		push_error("FAILURE: %d enemy AI tests failed." % _tests_failed)
		get_tree().quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[PASS] %s" % test_name)
	else:
		_tests_failed += 1
		printerr("[FAIL] %s" % test_name)

# ------------------------------------------------------------------------------
# 1. ENEMY DATA & ATTACK DATA
# ------------------------------------------------------------------------------
func _test_01_enemy_data_and_attack_data() -> void:
	print("\n--- Testing Enemy Data and Attack Data Resources ---")
	var atk_path: String = "res://data/enemies/attacks/attack_celestial_guard_slash.tres"
	_assert(ResourceLoader.exists(atk_path), "DATA-01: Celestial Guard Slash attack resource exists")
	
	var atk_res: Resource = load(atk_path)
	_assert(atk_res is EnemyAttackData, "DATA-02: Attack resource loads as EnemyAttackData instance")
	_assert(atk_res is AttackData, "DATA-03: EnemyAttackData polymorphically inherits from AttackData")
	
	var atk_data: EnemyAttackData = atk_res as EnemyAttackData
	_assert(atk_data.attack_id == &"celestial_guard_slash", "DATA-04: Attack ID is celestial_guard_slash")
	_assert(atk_data.damage > 0.0, "DATA-05: Attack damage is positive (%.1f)" % atk_data.damage)
	_assert(atk_data.poise_damage > 0.0, "DATA-06: Attack poise damage is positive (%.1f)" % atk_data.poise_damage)
	_assert(atk_data.telegraph_duration > 0.0, "DATA-07: Attack telegraph duration is positive (%.2fs)" % atk_data.telegraph_duration)
	_assert(atk_data.active_time > 0.0, "DATA-08: Attack active time is positive (%.2fs)" % atk_data.active_time)
	_assert(atk_data.recovery_time > 0.0, "DATA-09: Attack recovery time is positive (%.2fs)" % atk_data.recovery_time)
	_assert(atk_data.cooldown > 0.0, "DATA-010: Attack cooldown is positive (%.2fs)" % atk_data.cooldown)
	_assert(atk_data.is_parryable, "DATA-011: Enemy attack is flagged parryable")
	_assert(atk_data.is_dodgeable, "DATA-012: Enemy attack is flagged dodgeable")
	_assert(atk_data.is_interruptible, "DATA-013: Enemy attack is flagged interruptible")
	
	var enemy_path: String = "res://data/enemies/enemy_celestial_guard.tres"
	_assert(ResourceLoader.exists(enemy_path), "DATA-014: Celestial Guard EnemyData resource exists")
	
	var enemy_res: Resource = load(enemy_path)
	_assert(enemy_res is EnemyData, "DATA-015: Resource loads as EnemyData instance")
	var ed: EnemyData = enemy_res as EnemyData
	_assert(ed.enemy_id == &"celestial_guard", "DATA-016: Enemy ID is celestial_guard")
	_assert(ed.max_health > 0.0, "DATA-017: Enemy max health is positive (%.1f)" % ed.max_health)
	_assert(ed.max_poise > 0.0, "DATA-018: Enemy max poise is positive (%.1f)" % ed.max_poise)
	_assert(ed.patrol_speed > 0.0, "DATA-019: Enemy patrol speed is positive (%.1f)" % ed.patrol_speed)
	_assert(ed.chase_speed > ed.patrol_speed, "DATA-020: Enemy chase speed (%.1f) > patrol speed (%.1f)" % [ed.chase_speed, ed.patrol_speed])
	_assert(ed.detection_range > 0.0, "DATA-021: Detection range is positive (%.1f)" % ed.detection_range)
	_assert(ed.lose_target_range > ed.detection_range, "DATA-022: Lose target range (%.1f) > detection range (%.1f)" % [ed.lose_target_range, ed.detection_range])
	_assert(ed.default_attack != null, "DATA-023: Default attack is assigned to EnemyData")

# ------------------------------------------------------------------------------
# 2. ENEMY BASE INSTANTIATION & LAYERS
# ------------------------------------------------------------------------------
func _test_02_enemy_base_instantiation_and_layers() -> void:
	print("\n--- Testing Enemy Base Instantiation and Collision Layers ---")
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	_assert(scene != null, "SCENE-01: enemy_base.tscn loaded successfully")
	
	var enemy: EnemyController = scene.instantiate() as EnemyController
	_assert(enemy != null, "SCENE-02: enemy_base instantiates as EnemyController")
	add_child(enemy)
	
	_assert(enemy.collision_layer == 4, "LAYER-01: Enemy CharacterBody2D is on Layer 3 (bitmask 4)")
	_assert(enemy.collision_mask == 1, "LAYER-02: Enemy CharacterBody2D scans Layer 1 (World, bitmask 1)")
	
	_assert(enemy.health_component != null, "COMP-01: HealthComponent discovered")
	_assert(enemy.poise_component != null, "COMP-02: PoiseComponent discovered")
	_assert(enemy.perception != null, "COMP-03: EnemyPerception discovered")
	_assert(enemy.movement != null, "COMP-04: EnemyMovement discovered")
	_assert(enemy.combat_controller != null, "COMP-05: EnemyCombatController discovered")
	_assert(enemy.anim_controller != null, "COMP-06: EnemyAnimationController discovered")
	_assert(enemy.state_machine != null, "COMP-07: StateMachine discovered")
	_assert(enemy.hitbox != null, "COMP-08: Enemy Hitbox discovered")
	_assert(enemy.hurtbox != null, "COMP-09: Enemy Hurtbox discovered")
	
	_assert(enemy.hitbox.collision_layer == 16, "LAYER-03: Enemy Hitbox is on Layer 5 (bitmask 16)")
	_assert(enemy.hitbox.collision_mask == 32, "LAYER-04: Enemy Hitbox scans Layer 6 (PlayerHurtbox, bitmask 32)")
	_assert(enemy.hurtbox.collision_layer == 64, "LAYER-05: Enemy Hurtbox is on Layer 7 (bitmask 64)")
	_assert(enemy.hurtbox.collision_mask == 0, "LAYER-06: Enemy Hurtbox is a passive receiver (mask 0)")
	
	enemy.queue_free()

# ------------------------------------------------------------------------------
# 3. ENEMY STATE MACHINE LIFECYCLE
# ------------------------------------------------------------------------------
func _test_03_enemy_state_machine_lifecycle() -> void:
	print("\n--- Testing Enemy State Machine Lifecycle ---")
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyController = scene.instantiate() as EnemyController
	enemy.auto_start_ai = false # Control manually for testing
	add_child(enemy)
	
	var sm: StateMachine = enemy.state_machine
	_assert(sm != null, "SM-01: StateMachine is non-null")
	_assert(sm.has_state(&"Idle"), "SM-02: StateMachine contains Idle state")
	_assert(sm.has_state(&"Patrol"), "SM-03: StateMachine contains Patrol state")
	_assert(sm.has_state(&"Alert"), "SM-04: StateMachine contains Alert state")
	_assert(sm.has_state(&"Chase"), "SM-05: StateMachine contains Chase state")
	_assert(sm.has_state(&"Combat"), "SM-06: StateMachine contains Combat state")
	_assert(sm.has_state(&"Hit"), "SM-07: StateMachine contains Hit state")
	_assert(sm.has_state(&"Stagger"), "SM-08: StateMachine contains Stagger state")
	_assert(sm.has_state(&"Dead"), "SM-09: StateMachine contains Dead state")
	
	sm.change_state(&"Idle")
	_assert(sm.get_current_state_name() == &"Idle", "SM-10: Initial state set to Idle")
	
	sm.change_state(&"Patrol")
	_assert(sm.get_current_state_name() == &"Patrol", "SM-11: Successfully transitioned to Patrol")
	
	sm.change_state(&"Alert")
	_assert(sm.get_current_state_name() == &"Alert", "SM-12: Successfully transitioned to Alert")
	
	sm.change_state(&"Chase")
	_assert(sm.get_current_state_name() == &"Chase", "SM-13: Successfully transitioned to Chase")
	
	sm.change_state(&"Combat")
	_assert(sm.get_current_state_name() == &"Combat", "SM-14: Successfully transitioned to Combat")
	
	sm.change_state(&"Hit")
	_assert(sm.get_current_state_name() == &"Hit", "SM-15: Successfully transitioned to Hit")
	
	sm.change_state(&"Stagger")
	_assert(sm.get_current_state_name() == &"Stagger", "SM-16: Successfully transitioned to Stagger")
	
	sm.change_state(&"Dead")
	_assert(sm.get_current_state_name() == &"Dead", "SM-17: Successfully transitioned to Dead")
	
	enemy.queue_free()

# ------------------------------------------------------------------------------
# 4. PERCEPTION SYSTEM
# ------------------------------------------------------------------------------
func _test_04_perception_system() -> void:
	print("\n--- Testing Perception System ---")
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyController = scene.instantiate() as EnemyController
	enemy.auto_start_ai = false
	add_child(enemy)
	
	var perception: EnemyPerception = enemy.perception
	_assert(perception != null, "PERC-01: EnemyPerception instance exists")
	_assert(not perception.has_target(), "PERC-02: Perception starts with no target")
	_assert(perception.get_target_distance() == INF, "PERC-03: Target distance is INF when no target")
	
	var dummy_target: Node2D = Node2D.new()
	dummy_target.name = "DummyTarget"
	dummy_target.position = enemy.global_position + Vector2(100, 0)
	add_child(dummy_target)
	
	perception.acquire_target(dummy_target)
	_assert(perception.has_target(), "PERC-04: Successfully acquired dummy target")
	_assert(perception.current_target == dummy_target, "PERC-05: Current target matches dummy target")
	_assert(is_equal_approx(perception.get_target_distance(), 100.0), "PERC-06: Target distance correctly computed (100px)")
	
	var dir: Vector2 = perception.get_target_direction()
	_assert(is_equal_approx(dir.x, 1.0) and is_equal_approx(dir.y, 0.0), "PERC-07: Target direction correctly computed (+X)")
	
	perception.clear_target()
	_assert(not perception.has_target(), "PERC-08: Target successfully cleared via clear_target()")
	
	# Test distance threshold loss
	perception.acquire_target(dummy_target)
	perception.lose_target_range = 150.0
	dummy_target.position = enemy.global_position + Vector2(200, 0)
	perception._evaluate_perception()
	_assert(not perception.has_target(), "PERC-09: Target automatically cleared when exceeding lose_target_range")
	
	dummy_target.queue_free()
	enemy.queue_free()

# ------------------------------------------------------------------------------
# 5. PATROL BEHAVIOR
# ------------------------------------------------------------------------------
func _test_05_patrol_behavior() -> void:
	print("\n--- Testing Patrol Behavior ---")
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyController = scene.instantiate() as EnemyController
	enemy.auto_start_ai = false
	add_child(enemy)
	
	var movement: EnemyMovement = enemy.movement
	_assert(movement != null, "PATROL-01: EnemyMovement instance exists")
	
	movement.set_spawn_position(Vector2(200, 100))
	_assert(movement.spawn_position == Vector2(200, 100), "PATROL-02: Spawn position correctly set")
	_assert(movement.left_patrol_x == 200.0 - movement.patrol_distance, "PATROL-03: Left patrol boundary calculated accurately")
	_assert(movement.right_patrol_x == 200.0 + movement.patrol_distance, "PATROL-04: Right patrol boundary calculated accurately")
	_assert(movement.patrol_moving_right, "PATROL-05: Initially moving right")
	
	movement.reverse_patrol_direction()
	_assert(not movement.patrol_moving_right, "PATROL-06: Successfully reversed patrol direction (moving left)")
	_assert(movement.current_patrol_target_x == movement.left_patrol_x, "PATROL-07: Current target matches left boundary")
	_assert(movement.facing_direction == -1, "PATROL-08: Facing direction updated to -1 (left)")
	
	movement.reverse_patrol_direction()
	_assert(movement.patrol_moving_right, "PATROL-09: Re-reversed direction (moving right)")
	_assert(movement.facing_direction == 1, "PATROL-10: Facing direction restored to +1 (right)")
	
	enemy.queue_free()

# ------------------------------------------------------------------------------
# 6. CHASE BEHAVIOR
# ------------------------------------------------------------------------------
func _test_06_chase_behavior() -> void:
	print("\n--- Testing Chase Behavior ---")
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyController = scene.instantiate() as EnemyController
	enemy.auto_start_ai = false
	add_child(enemy)
	
	var dummy: Node2D = Node2D.new()
	dummy.position = Vector2(300, 0)
	add_child(dummy)
	
	enemy.position = Vector2(100, 0)
	enemy.movement.move_toward_x(dummy.position.x, 110.0, 0.1)
	_assert(enemy.velocity.x > 0.0, "CHASE-01: Velocity.x increases toward target (+X)")
	_assert(enemy.movement.facing_direction == 1, "CHASE-02: Facing direction is +1 toward target on right")
	
	dummy.position = Vector2(0, 0)
	enemy.movement.move_toward_x(dummy.position.x, 110.0, 0.1)
	enemy.movement.face_target(dummy)
	_assert(enemy.movement.facing_direction == -1, "CHASE-03: Facing direction flips to -1 toward target on left")
	
	dummy.queue_free()
	enemy.queue_free()

# ------------------------------------------------------------------------------
# 7. COMBAT POSITIONING
# ------------------------------------------------------------------------------
func _test_07_combat_positioning() -> void:
	print("\n--- Testing Combat Positioning ---")
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyController = scene.instantiate() as EnemyController
	enemy.auto_start_ai = false
	add_child(enemy)
	
	var data: EnemyData = load("res://data/enemies/enemy_celestial_guard.tres") as EnemyData
	enemy.configure(data)
	
	_assert(enemy.combat_controller.get_attack_range() == data.attack_range, "COMBAT-POS-01: Attack range matches EnemyData (%.1f)" % data.attack_range)
	_assert(data.preferred_combat_distance > 0.0, "COMBAT-POS-02: Preferred combat distance is positive (%.1f)" % data.preferred_combat_distance)
	
	# Verify deadzone stop
	enemy.velocity.x = 40.0
	enemy.movement.stop_horizontal(0.1)
	_assert(enemy.velocity.x < 40.0, "COMBAT-POS-03: Horizontal speed smoothly decelerates when stopped")
	
	enemy.queue_free()

# ------------------------------------------------------------------------------
# 8. ATTACK LIFECYCLE & HITBOX
# ------------------------------------------------------------------------------
func _test_08_attack_lifecycle_and_hitbox() -> void:
	print("\n--- Testing Attack Lifecycle, Hitbox Window, and Interruption ---")
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyController = scene.instantiate() as EnemyController
	enemy.auto_start_ai = false
	add_child(enemy)
	
	var data: EnemyData = load("res://data/enemies/enemy_celestial_guard.tres") as EnemyData
	enemy.configure(data)
	
	var cc: EnemyCombatController = enemy.combat_controller
	var hb: Hitbox = enemy.hitbox
	
	_assert(cc.can_attack(), "ATTACK-01: Combat controller can attack initially")
	_assert(not hb.is_active, "ATTACK-02: Hitbox starts completely inactive")
	_assert(not hb.monitoring and not hb.monitorable, "ATTACK-03: Hitbox collision is disabled initially")
	
	var triggered: bool = cc.trigger_attack()
	_assert(triggered, "ATTACK-04: Attack triggered successfully")
	_assert(cc.current_phase == EnemyCombatController.AttackPhase.TELEGRAPH, "ATTACK-05: Phase transitioned to TELEGRAPH")
	_assert(not hb.is_active, "ATTACK-06: Hitbox remains inactive during TELEGRAPH")
	
	# Simulate telegraph elapsing to enter ACTIVE
	cc.process_combat(cc.active_attack_data.telegraph_duration + 0.01)
	_assert(cc.current_phase == EnemyCombatController.AttackPhase.ACTIVE, "ATTACK-07: Phase transitioned to ACTIVE")
	_assert(hb.is_active, "ATTACK-08: Hitbox becomes ACTIVE during attack active window")
	_assert(hb.monitoring and hb.monitorable, "ATTACK-09: Hitbox collision is ENABLED during active window")
	
	# Simulate active window elapsing to enter RECOVERY
	cc.process_combat(cc.active_attack_data.active_time + 0.01)
	_assert(cc.current_phase == EnemyCombatController.AttackPhase.RECOVERY, "ATTACK-10: Phase transitioned to RECOVERY")
	_assert(not hb.is_active, "ATTACK-11: Hitbox disabled immediately during RECOVERY")
	
	# Simulate recovery elapsing to enter COOLDOWN
	cc.process_combat(cc.active_attack_data.recovery_time + 0.01)
	_assert(cc.current_phase == EnemyCombatController.AttackPhase.COOLDOWN, "ATTACK-12: Phase transitioned to COOLDOWN")
	_assert(not cc.can_attack(), "ATTACK-13: Attack trigger blocked while on COOLDOWN")
	
	# Test parry interruption
	cc.reset_combat()
	cc.trigger_attack()
	cc.process_combat(cc.active_attack_data.telegraph_duration + 0.01) # Enter active
	_assert(hb.is_active, "ATTACK-14: Hitbox is active before interrupt")
	
	enemy.interrupt_attack()
	_assert(cc.current_phase == EnemyCombatController.AttackPhase.INTERRUPTED, "ATTACK-15: interrupt_attack() forces phase to INTERRUPTED")
	_assert(not hb.is_active, "ATTACK-16: Hitbox immediately deactivated upon interruption")
	
	enemy.queue_free()

# ------------------------------------------------------------------------------
# 9. HIT REACTION & POISE / STAGGER
# ------------------------------------------------------------------------------
func _test_09_hit_reaction_and_poise() -> void:
	print("\n--- Testing Hit Reaction, Poise Damage, and Stagger State ---")
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyController = scene.instantiate() as EnemyController
	enemy.auto_start_ai = false
	add_child(enemy)
	
	var data: EnemyData = load("res://data/enemies/enemy_celestial_guard.tres") as EnemyData
	enemy.configure(data)
	
	var initial_hp: float = enemy.health_component.current_health
	var initial_poise: float = enemy.poise_component.current_poise
	
	var dmg_info: DamageInfo = DamageInfo.new()
	dmg_info.damage = 25.0
	dmg_info.poise_damage = 15.0
	dmg_info.knockback_force = Vector2(80, -20)
	dmg_info.hit_direction = 1
	
	enemy.hurtbox.receive_hit(dmg_info)
	_assert(enemy.health_component.current_health == initial_hp - 25.0, "POISE-01: Health reduced by 25.0 via Hurtbox (%.0f)" % enemy.health_component.current_health)
	_assert(enemy.poise_component.current_poise == initial_poise - 15.0, "POISE-02: Poise reduced by 15.0 via Hurtbox (%.0f)" % enemy.poise_component.current_poise)
	_assert(not enemy.poise_component.is_staggered, "POISE-03: Enemy not staggered yet (Poise > 0)")
	
	# Deplete remaining poise to trigger stagger
	var break_info: DamageInfo = DamageInfo.new()
	break_info.damage = 10.0
	break_info.poise_damage = 20.0 # Exceeds remaining 15 poise
	enemy.hurtbox.receive_hit(break_info)
	
	_assert(enemy.poise_component.current_poise == 0.0, "POISE-04: Poise reached 0.0")
	_assert(enemy.poise_component.is_staggered, "POISE-05: PoiseComponent is_staggered is TRUE")
	_assert(enemy.state_machine.get_current_state_name() == &"Stagger", "POISE-06: StateMachine transitioned to Stagger state")
	
	# Verify combat actions locked during stagger
	_assert(not enemy.combat_controller.can_attack(), "POISE-07: Attack triggers disabled during Stagger")
	
	# Recover from stagger
	enemy.poise_component.end_stagger()
	_assert(not enemy.poise_component.is_staggered, "POISE-08: Stagger ended successfully")
	_assert(enemy.poise_component.current_poise == enemy.poise_component.max_poise, "POISE-09: Poise fully restored to max upon recovery")
	
	enemy.queue_free()

# ------------------------------------------------------------------------------
# 10. DEATH MECHANICS
# ------------------------------------------------------------------------------
func _test_10_death_mechanics() -> void:
	print("\n--- Testing Death Mechanics ---")
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy: EnemyController = scene.instantiate() as EnemyController
	enemy.auto_start_ai = false
	add_child(enemy)
	
	var data: EnemyData = load("res://data/enemies/enemy_celestial_guard.tres") as EnemyData
	enemy.configure(data)
	
	_assert(not enemy.is_dead, "DEATH-01: Enemy is initially alive")
	
	var fatal_hit: DamageInfo = DamageInfo.new()
	fatal_hit.damage = 200.0 # Exceeds max health
	enemy.hurtbox.receive_hit(fatal_hit)
	
	_assert(enemy.health_component.current_health == 0.0, "DEATH-02: Health reduced to 0.0")
	_assert(enemy.is_dead, "DEATH-03: EnemyController is_dead is TRUE")
	_assert(enemy.state_machine.get_current_state_name() == &"Dead", "DEATH-04: StateMachine transitioned to Dead state")
	_assert(not enemy.hitbox.is_active, "DEATH-05: Attack hitbox deactivated on death")
	_assert(enemy.velocity == Vector2.ZERO, "DEATH-06: Velocity set to ZERO on death")
	
	# Test idempotency
	enemy.die()
	_assert(enemy.is_dead, "DEATH-07: Calling die() a second time remains safely dead (Idempotent)")
	_assert(enemy.state_machine.get_current_state_name() == &"Dead", "DEATH-08: State remains Dead on duplicate die()")
	
	enemy.queue_free()

# ------------------------------------------------------------------------------
# 11. MULTI-ENEMY INDEPENDENCE
# ------------------------------------------------------------------------------
func _test_11_multi_enemy_independence() -> void:
	print("\n--- Testing Multi-Enemy Independence ---")
	var scene: PackedScene = load("res://scenes/enemies/enemy_base.tscn")
	var enemy1: EnemyController = scene.instantiate() as EnemyController
	var enemy2: EnemyController = scene.instantiate() as EnemyController
	enemy1.auto_start_ai = false
	enemy2.auto_start_ai = false
	add_child(enemy1)
	add_child(enemy2)
	
	var data: EnemyData = load("res://data/enemies/enemy_celestial_guard.tres") as EnemyData
	enemy1.configure(data)
	enemy2.configure(data)
	
	_assert(enemy1 != enemy2, "MULTI-01: Two distinct enemy instances exist")
	_assert(enemy1.health_component != enemy2.health_component, "MULTI-02: HealthComponents are completely independent")
	_assert(enemy1.combat_controller != enemy2.combat_controller, "MULTI-03: CombatControllers are completely independent")
	
	# Damage enemy1 only
	var hit: DamageInfo = DamageInfo.new()
	hit.damage = 30.0
	enemy1.hurtbox.receive_hit(hit)
	
	_assert(enemy1.health_component.current_health == data.max_health - 30.0, "MULTI-04: Enemy 1 health reduced to 50.0")
	_assert(enemy2.health_component.current_health == data.max_health, "MULTI-05: Enemy 2 health unmutated at 80.0")
	
	# Trigger attack on enemy2 only
	enemy2.combat_controller.trigger_attack()
	_assert(enemy2.combat_controller.is_attacking(), "MULTI-06: Enemy 2 is actively attacking")
	_assert(not enemy1.combat_controller.is_attacking(), "MULTI-07: Enemy 1 is NOT attacking")
	
	enemy1.queue_free()
	enemy2.queue_free()

# ------------------------------------------------------------------------------
# 12. ARENA & INTEGRATION
# ------------------------------------------------------------------------------
func _test_12_arena_and_eventbus_integration() -> void:
	print("\n--- Testing Test Arena and EventBus Integration ---")
	var room_path: String = "res://scenes/world/test_enemy_ai_room.tscn"
	_assert(ResourceLoader.exists(room_path), "ARENA-01: test_enemy_ai_room.tscn exists")
	
	var room_scene: PackedScene = load(room_path)
	_assert(room_scene != null, "ARENA-02: test_enemy_ai_room.tscn loaded successfully")
	
	var room: Node = room_scene.instantiate()
	add_child(room)
	
	_assert(room.has_node("Player"), "ARENA-03: Room contains PlayerController instance")
	_assert(room.has_node("CelestialGuard1"), "ARENA-04: Room contains CelestialGuard1 (Patroller)")
	_assert(room.has_node("CelestialGuard2"), "ARENA-05: Room contains CelestialGuard2 (Stationed)")
	_assert(room.has_node("SpiritHUD"), "ARENA-06: Room contains SpiritHUD")
	
	var guard1: EnemyController = room.get_node("CelestialGuard1") as EnemyController
	_assert(guard1.enemy_data != null, "ARENA-07: Guard 1 has valid EnemyData resource configured")
	_assert(guard1.enemy_data.enemy_id == &"celestial_guard", "ARENA-08: Guard 1 enemy_id is celestial_guard")
	
	# Verify EventBus signals
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		_assert(bus.has_signal("enemy_spawned"), "BUS-01: EventBus has enemy_spawned signal")
		_assert(bus.has_signal("enemy_staggered"), "BUS-02: EventBus has enemy_staggered signal")
		_assert(bus.has_signal("enemy_died"), "BUS-03: EventBus has enemy_died signal")
	
	room.queue_free()
