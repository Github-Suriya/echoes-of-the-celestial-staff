extends Node

const ForbiddenForestWorld = preload("res://scripts/world/forbidden_forest_world.gd")
const SporeCasterController = preload("res://scripts/enemies/spore_caster_controller.gd")
const EnemyProjectile = preload("res://scripts/enemies/enemy_projectile.gd")
const VFXManager = preload("res://scripts/effects/vfx_manager.gd")

## Automated Chapter 1: Forbidden Forest Vertical Slice Test Suite (Phase 11)
## Comprehensive automated verification covering:
## - Category 1: World & 5 Room Resources Structure & Bounds
## - Category 2: Room Transitions, Player Preservation & Camera Bounds
## - Category 3: Checkpoint Lifecycle, State Restoration & Respawn
## - Category 4: Normal Enemy Archetypes (Scout, Thorn Beast, Spore Caster)
## - Category 5: Intermediate Boss 1: Verdant Fang
## - Category 6: Intermediate Boss 2: Bamboo Warden
## - Category 7: Intermediate Boss 3: Hollow Shrine Keeper & Shrine Gate
## - Category 8: Final Boss: Corrupted Forest Heart Phase 1 & Phase 2 Transition
## - Category 9: Player Systems Integration (Stances, Spirit, Awakening)
## - Category 10: Base VFX Instantiation, Signal Handling & Safe Cleanup
## - Category 11: End-to-End Progression, Persistence & Hitbox Signal Safety

var _tests_passed: int = 0
var _tests_failed: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 11 CHAPTER 1 FORBIDDEN FOREST TEST SUITE")
	print("==================================================")
	
	_test_01_world_and_rooms_structure()
	_test_02_room_transitions_and_camera()
	_test_03_checkpoints_and_respawn()
	_test_04_normal_enemies()
	_test_05_boss_verdant_fang()
	_test_06_boss_bamboo_warden()
	_test_07_boss_hollow_shrine_keeper_and_gate()
	_test_08_final_boss_two_phases()
	_test_09_player_integration()
	_test_10_vfx_and_atmosphere()
	_test_11_chapter_persistence_and_hitbox_safety()
	
	print("==================================================")
	print(" CHAPTER 1 TEST RESULTS: %d / %d PASSED (%d FAILED)" % [
		_tests_passed,
		_tests_passed + _tests_failed,
		_tests_failed
	])
	print("==================================================")
	
	if _tests_failed == 0:
		print("\nSUCCESS: All Phase 11 Chapter 1 Forbidden Forest tests passed cleanly.\n")
		get_tree().quit(0)
	else:
		push_error("FAILURE: %d Chapter 1 tests failed." % _tests_failed)
		get_tree().quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_tests_passed += 1
		print("[PASS] %s" % test_name)
	else:
		_tests_failed += 1
		printerr("[FAIL] %s" % test_name)

# ------------------------------------------------------------------------------
# Category 1: World & 5 Room Resources Structure & Bounds
# ------------------------------------------------------------------------------
func _test_01_world_and_rooms_structure() -> void:
	print("\n--- Category 1: World & 5 Room Resources Structure ---")
	
	var room_ids: Array[String] = [
		"room_01_forest_entrance",
		"room_02_ancient_grove",
		"room_03_bamboo_path",
		"room_04_forgotten_shrine",
		"room_05_forest_heart"
	]
	
	for rid in room_ids:
		var path: String = "res://data/world/forbidden_forest/%s.tres" % rid
		_assert(ResourceLoader.exists(path), "RoomData resource exists: %s" % rid)
		var rd: RoomData = load(path) as RoomData
		_assert(rd != null, "RoomData loads successfully: %s" % rid)
		_assert(rd.is_valid(), "RoomData is_valid() true: %s" % rid)
		_assert(rd.room_bounds.size.x >= 2400.0 and rd.room_bounds.size.y == 1080.0, "Room bounds valid: %s" % rid)
		_assert(ResourceLoader.exists(rd.scene_path), "Room scene file exists: %s" % rd.scene_path)
		
		# Test scene loads as Room2D
		var scn: PackedScene = load(rd.scene_path) as PackedScene
		_assert(scn != null, "Scene loads as PackedScene: %s" % rid)
		var inst: Room2D = scn.instantiate() as Room2D
		_assert(inst != null, "Scene instances as Room2D: %s" % rid)
		_assert(inst.room_id == StringName(rid), "Instance room_id matches: %s" % rid)
		inst.free()

# ------------------------------------------------------------------------------
# Category 2: Room Transitions, Player Preservation & Camera Bounds
# ------------------------------------------------------------------------------
func _test_02_room_transitions_and_camera() -> void:
	print("\n--- Category 2: Room Transitions & Camera Bounds ---")
	
	var world_scene: PackedScene = load("res://scenes/world/forbidden_forest/forbidden_forest_world.tscn")
	_assert(world_scene != null, "forbidden_forest_world.tscn exists and loads")
	var world: ForbiddenForestWorld = world_scene.instantiate() as ForbiddenForestWorld
	_assert(world != null, "World instantiates as ForbiddenForestWorld")
	add_child(world)
	
	# Initial room verification
	_assert(world.current_room_id == &"room_01_forest_entrance", "Initial room is room_01_forest_entrance")
	_assert(world.active_room != null, "Active room is loaded and non-null")
	_assert(world.player != null, "Player is spawned and non-null")
	
	var bounds_r1: Rect2 = world.active_room.get_camera_bounds()
	_assert(bounds_r1.size == Vector2(2400, 1080), "Room 1 camera bounds correct (2400x1080)")
	
	# Transition from Room 1 to Room 2
	var ok_t1: bool = world.request_room_transition(&"room_02_ancient_grove", &"spawn_from_entrance")
	_assert(ok_t1, "Room 1 -> Room 2 transition request succeeds")
	_assert(world.current_room_id == &"room_02_ancient_grove", "Current room is now room_02_ancient_grove")
	_assert(world.player.velocity == Vector2.ZERO, "Player velocity neutralized during transition")
	
	var bounds_r2: Rect2 = world.active_room.get_camera_bounds()
	_assert(bounds_r2.size == Vector2(2560, 1080), "Room 2 camera bounds correct (2560x1080)")
	
	# Transition from Room 2 to Room 3
	var ok_t2: bool = world.request_room_transition(&"room_03_bamboo_path", &"spawn_from_grove")
	_assert(ok_t2, "Room 2 -> Room 3 transition request succeeds")
	_assert(world.current_room_id == &"room_03_bamboo_path", "Current room is room_03_bamboo_path")
	
	var bounds_r3: Rect2 = world.active_room.get_camera_bounds()
	_assert(bounds_r3.size == Vector2(2880, 1080), "Room 3 camera bounds correct (2880x1080)")
	
	# Transition to Room 4
	var ok_t3: bool = world.request_room_transition(&"room_04_forgotten_shrine", &"spawn_from_bamboo")
	_assert(ok_t3, "Room 3 -> Room 4 transition request succeeds")
	_assert(world.current_room_id == &"room_04_forgotten_shrine", "Current room is room_04_forgotten_shrine")
	
	# Transition to Room 5
	var ok_t4: bool = world.request_room_transition(&"room_05_forest_heart", &"spawn_from_shrine")
	_assert(ok_t4, "Room 4 -> Room 5 transition request succeeds")
	_assert(world.current_room_id == &"room_05_forest_heart", "Current room is room_05_forest_heart")
	
	world.queue_free()

# ------------------------------------------------------------------------------
# Category 3: Checkpoint Lifecycle, State Restoration & Respawn
# ------------------------------------------------------------------------------
func _test_03_checkpoints_and_respawn() -> void:
	print("\n--- Category 3: Checkpoints & Respawn ---")
	
	var world_scene: PackedScene = load("res://scenes/world/forbidden_forest/forbidden_forest_world.tscn")
	var world: ForbiddenForestWorld = world_scene.instantiate() as ForbiddenForestWorld
	add_child(world)
	
	# Find Checkpoint in Room 1
	var cp_entrance: Checkpoint = world.active_room.find_child("cp_entrance", true, false) as Checkpoint
	_assert(cp_entrance != null, "cp_entrance node present in Room 1")
	
	# Damage player
	var p_health: HealthComponent = world.player.get_node("Components/HealthComponent") as HealthComponent
	p_health.take_damage(40.0)
	_assert(p_health.current_health == 60.0, "Player health reduced to 60")
	
	# Activate checkpoint
	cp_entrance.activate(world.player)
	_assert(cp_entrance.is_active, "Checkpoint is_active true")
	_assert(p_health.current_health == 100.0, "Checkpoint restored player health to 100")
	_assert(world.world_state.has_flag(&"checkpoint_active_cp_entrance"), "WorldState records checkpoint flag")
	_assert(world.active_checkpoint_room_id == &"room_01_forest_entrance", "WorldController active checkpoint room set")
	
	# Travel to Room 2 and activate Room 2 checkpoint
	world.request_room_transition(&"room_02_ancient_grove", &"spawn_from_entrance")
	var cp_grove: Checkpoint = world.active_room.find_child("cp_grove", true, false) as Checkpoint
	_assert(cp_grove != null, "cp_grove node present in Room 2")
	cp_grove.activate(world.player)
	_assert(world.active_checkpoint_room_id == &"room_02_ancient_grove", "Active checkpoint updated to Room 2")
	
	# Test Respawn
	p_health.take_damage(50.0)
	world.respawn_player_at_checkpoint()
	_assert(world.current_room_id == &"room_02_ancient_grove", "Respawn loads checkpoint room (Room 2)")
	_assert(p_health.current_health == 100.0, "Respawn restores full health")
	
	world.queue_free()

# ------------------------------------------------------------------------------
# Category 4: Normal Enemy Archetypes
# ------------------------------------------------------------------------------
func _test_04_normal_enemies() -> void:
	print("\n--- Category 4: Normal Enemy Archetypes ---")
	
	# 1. Forest Scout
	var scout_scene: PackedScene = load("res://scenes/enemies/forest_scout.tscn")
	_assert(scout_scene != null, "forest_scout.tscn exists and loads")
	var scout: EnemyController = scout_scene.instantiate() as EnemyController
	add_child(scout)
	_assert(scout.enemy_data != null, "Forest Scout has enemy_data")
	_assert(scout.enemy_data.enemy_id == &"forest_scout", "Enemy ID is forest_scout")
	_assert(scout.enemy_data.max_health == 50.0, "Forest Scout HP is 50.0")
	_assert(scout.enemy_data.max_poise == 20.0, "Forest Scout Poise is 20.0")
	_assert(scout.enemy_data.chase_speed == 135.0, "Forest Scout chase speed is 135.0")
	_assert(scout.combat_controller.can_attack(), "Forest Scout can attack initially")
	
	# Test Scout damage and death
	scout.health_component.take_damage(50.0)
	_assert(scout.is_dead, "Forest Scout dies upon taking 50 damage")
	_assert(scout.hitbox.is_active == false, "Scout hitbox inactive on death")
	scout.queue_free()
	
	# 2. Thorn Beast
	var thorn_scene: PackedScene = load("res://scenes/enemies/thorn_beast.tscn")
	_assert(thorn_scene != null, "thorn_beast.tscn exists and loads")
	var thorn: EnemyController = thorn_scene.instantiate() as EnemyController
	add_child(thorn)
	_assert(thorn.enemy_data.enemy_id == &"thorn_beast", "Enemy ID is thorn_beast")
	_assert(thorn.enemy_data.max_health == 100.0, "Thorn Beast HP is 100.0")
	_assert(thorn.enemy_data.max_poise == 45.0, "Thorn Beast Poise is 45.0 (High Poise)")
	
	# Test Thorn Beast poise damage
	thorn.poise_component.take_poise_damage(20.0)
	_assert(not thorn.poise_component.is_staggered, "Thorn Beast resists 20 poise damage without stagger")
	thorn.poise_component.take_poise_damage(25.0)
	_assert(thorn.poise_component.is_staggered, "Thorn Beast staggers at 45 total poise damage")
	thorn.queue_free()
	
	# 3. Spore Caster & Projectile
	var spore_scene: PackedScene = load("res://scenes/enemies/spore_caster.tscn")
	_assert(spore_scene != null, "spore_caster.tscn exists and loads")
	var spore: SporeCasterController = spore_scene.instantiate() as SporeCasterController
	add_child(spore)
	_assert(spore != null, "Spore Caster instantiates as SporeCasterController")
	_assert(spore.enemy_data.enemy_id == &"spore_caster", "Enemy ID is spore_caster")
	_assert(spore.enemy_data.attack_range == 190.0, "Spore Caster has ranged attack range (190)")
	
	# Test projectile instantiation
	var proj_scene: PackedScene = load("res://scenes/effects/enemy_projectile.tscn")
	_assert(proj_scene != null, "enemy_projectile.tscn exists and loads")
	var proj: EnemyProjectile = proj_scene.instantiate() as EnemyProjectile
	add_child(proj)
	_assert(proj.collision_layer == 16, "Enemy projectile is on Layer 5 (EnemyHitbox, bitmask 16)")
	_assert(proj.collision_mask == 33, "Enemy projectile scans Layer 6 (PlayerHurtbox, 32) and Layer 1 (1)")
	
	var dinfo: DamageInfo = DamageInfo.new()
	dinfo.damage = 15.0
	proj.launch(dinfo, Vector2(100, 100), 1, spore)
	_assert(proj.velocity_direction == Vector2.RIGHT, "Projectile launched rightward")
	proj.expire()
	spore.queue_free()

# ------------------------------------------------------------------------------
# Category 5: Intermediate Boss 1: Verdant Fang
# ------------------------------------------------------------------------------
func _test_05_boss_verdant_fang() -> void:
	print("\n--- Category 5: Boss 1: Verdant Fang ---")
	
	var vfang_scene: PackedScene = load("res://scenes/bosses/verdant_fang.tscn")
	_assert(vfang_scene != null, "verdant_fang.tscn exists and loads")
	var boss: BossController = vfang_scene.instantiate() as BossController
	add_child(boss)
	
	_assert(boss.boss_data != null, "Verdant Fang has boss_data")
	_assert(boss.boss_data.boss_id == &"verdant_fang", "Boss ID is verdant_fang")
	_assert(boss.boss_data.max_health == 220.0, "Verdant Fang max health is 220.0")
	_assert(boss.boss_data.max_poise == 45.0, "Verdant Fang max poise is 45.0")
	_assert(boss.boss_data.chase_speed == 120.0, "Fast chase speed (120.0)")
	_assert(boss.phase_controller.get_current_phase_number() == 1, "Starts in Phase 1")
	
	# Attack selection
	var atk: BossAttackData = boss.combat_controller.select_attack() as BossAttackData
	_assert(atk != null, "Verdant Fang selects attack from data")
	_assert(boss.combat_controller.trigger_attack(atk), "Verdant Fang triggers attack")
	_assert(boss.combat_controller.is_attacking(), "Combat controller is_attacking true")
	
	# Damage & Stagger
	boss.health_component.take_damage(50.0)
	_assert(boss.health_component.current_health == 170.0, "Verdant Fang took 50 damage")
	boss.poise_component.take_poise_damage(45.0)
	_assert(boss.poise_component.is_staggered, "Verdant Fang staggers on poise break")
	
	# Defeat
	boss.health_component.take_damage(170.0)
	_assert(boss.is_defeated, "Verdant Fang is defeated at 0 HP")
	
	boss.queue_free()

# ------------------------------------------------------------------------------
# Category 6: Intermediate Boss 2: Bamboo Warden
# ------------------------------------------------------------------------------
func _test_06_boss_bamboo_warden() -> void:
	print("\n--- Category 6: Boss 2: Bamboo Warden ---")
	
	var bwarden_scene: PackedScene = load("res://scenes/bosses/bamboo_warden.tscn")
	_assert(bwarden_scene != null, "bamboo_warden.tscn exists and loads")
	var boss: BossController = bwarden_scene.instantiate() as BossController
	add_child(boss)
	
	_assert(boss.boss_data != null, "Bamboo Warden has boss_data")
	_assert(boss.boss_data.boss_id == &"bamboo_warden", "Boss ID is bamboo_warden")
	_assert(boss.boss_data.max_health == 280.0, "Bamboo Warden max health is 280.0")
	_assert(boss.boss_data.max_poise == 55.0, "Bamboo Warden max poise is 55.0")
	
	# Attack set verification
	var pdata: BossPhaseData = boss.boss_data.phases[0]
	_assert(pdata.attacks.size() >= 3, "Bamboo Warden has 3+ attacks (Combo, Sweep, Thrust)")
	
	boss.health_component.take_damage(280.0)
	_assert(boss.is_defeated, "Bamboo Warden is_defeated true on 0 HP")
	
	boss.queue_free()

# ------------------------------------------------------------------------------
# Category 7: Intermediate Boss 3: Hollow Shrine Keeper & Gate
# ------------------------------------------------------------------------------
func _test_07_boss_hollow_shrine_keeper_and_gate() -> void:
	print("\n--- Category 7: Boss 3: Hollow Shrine Keeper & Shrine Gate ---")
	
	var hshrine_scene: PackedScene = load("res://scenes/bosses/hollow_shrine_keeper.tscn")
	_assert(hshrine_scene != null, "hollow_shrine_keeper.tscn exists and loads")
	var boss: BossController = hshrine_scene.instantiate() as BossController
	add_child(boss)
	
	_assert(boss.boss_data != null, "Hollow Shrine Keeper has boss_data")
	_assert(boss.boss_data.boss_id == &"hollow_shrine_keeper", "Boss ID is hollow_shrine_keeper")
	_assert(boss.boss_data.max_health == 340.0, "Hollow Shrine Keeper max health is 340.0")
	_assert(boss.boss_data.max_poise == 70.0, "High poise (70.0)")
	
	boss.health_component.take_damage(340.0)
	_assert(boss.is_defeated, "Hollow Shrine Keeper defeated")
	boss.queue_free()
	
	# Verify Shrine Gate unlocks with flag
	var gate: AbilityGate = AbilityGate.new()
	gate.gate_id = &"shrine_gate"
	gate.required_flag = &"hollow_shrine_keeper_defeated"
	var col: CollisionShape2D = CollisionShape2D.new()
	col.name = "CollisionShape2D"
	gate.add_child(col)
	var vis: ColorRect = ColorRect.new()
	vis.name = "VisualBarrier"
	gate.add_child(vis)
	add_child(gate)
	
	var state: WorldState = WorldState.new()
	_assert(not gate.check_unlock(null, state), "Shrine gate locked without defeat flag")
	
	state.set_flag(&"hollow_shrine_keeper_defeated", true)
	_assert(gate.check_unlock(null, state), "Shrine gate unlocks when hollow_shrine_keeper_defeated is set")
	_assert(gate.is_open, "Shrine gate is_open is true")
	
	gate.queue_free()

# ------------------------------------------------------------------------------
# Category 8: Final Boss: Corrupted Forest Heart Two-Phase Transition
# ------------------------------------------------------------------------------
func _test_08_final_boss_two_phases() -> void:
	print("\n--- Category 8: Final Boss: Corrupted Forest Heart Two Phases ---")
	
	var fheart_scene: PackedScene = load("res://scenes/bosses/corrupted_forest_heart.tscn")
	_assert(fheart_scene != null, "corrupted_forest_heart.tscn exists and loads")
	var boss: BossController = fheart_scene.instantiate() as BossController
	add_child(boss)
	
	_assert(boss.boss_data != null, "Corrupted Forest Heart has boss_data")
	_assert(boss.boss_data.boss_id == &"corrupted_forest_heart", "Boss ID is corrupted_forest_heart")
	_assert(boss.boss_data.max_health == 420.0, "Final boss max health is 420.0")
	_assert(boss.boss_data.phases.size() == 2, "Final boss has exactly 2 phases")
	
	# Starts in Phase 1
	_assert(boss.phase_controller.get_current_phase_number() == 1, "Starts in Phase 1")
	var p1: BossPhaseData = boss.phase_controller.get_current_phase_data()
	_assert(p1.phase_name == "Ancient Guardian", "Phase 1 is Ancient Guardian")
	
	# Damage down to 60% HP (252 HP) -> No Phase 2
	boss.health_component.take_damage(168.0)
	boss.phase_controller.check_health_threshold(boss.health_component.current_health, boss.health_component.max_health)
	_assert(boss.phase_controller.get_current_phase_number() == 1, "Still Phase 1 above 50% HP")
	
	# Damage down to 50% HP (210 HP) -> Triggers Phase 2!
	boss.health_component.take_damage(42.0)
	boss.phase_controller.check_health_threshold(boss.health_component.current_health, boss.health_component.max_health)
	_assert(boss.phase_controller.is_transitioning, "Phase transition triggered at 50% HP")
	_assert(boss.phase_controller.get_current_phase_number() == 2, "Transitioned to Phase 2")
	
	boss.phase_controller.complete_phase_transition()
	_assert(not boss.phase_controller.is_transitioning, "Phase transition completed")
	var p2: BossPhaseData = boss.phase_controller.get_current_phase_data()
	_assert(p2.phase_name == "Unstable Corruption", "Phase 2 is Unstable Corruption")
	_assert(p2.movement_speed_multiplier > 1.0, "Phase 2 has increased movement speed (1.35x)")
	_assert(p2.attack_speed_multiplier > 1.0, "Phase 2 has increased attack speed (1.25x)")
	
	# Final Defeat
	boss.health_component.take_damage(210.0)
	_assert(boss.is_defeated, "Corrupted Forest Heart defeated at 0 HP")
	_assert(boss.state_machine.current_state.name == "Defeated", "Final boss in Defeated state")
	
	boss.queue_free()

# ------------------------------------------------------------------------------
# Category 9: Player Systems Integration in Chapter 1
# ------------------------------------------------------------------------------
func _test_09_player_integration() -> void:
	print("\n--- Category 9: Player Systems Integration ---")
	
	var world_scene: PackedScene = load("res://scenes/world/forbidden_forest/forbidden_forest_world.tscn")
	var world: ForbiddenForestWorld = world_scene.instantiate() as ForbiddenForestWorld
	add_child(world)
	
	var p: PlayerController = world.player
	_assert(p != null, "Player is present in world")
	_assert(p.stance_controller != null, "Player has StanceController")
	_assert(p.spirit_component != null, "Player has SpiritComponent")
	_assert(p.defense_controller != null, "Player has DefenseController")
	
	# Test stance cycling
	var st1: int = p.stance_controller.get_current_stance()
	p.stance_controller.cycle_stance()
	var st2: int = p.stance_controller.get_current_stance()
	_assert(st1 != st2, "Player successfully switched stance")
	
	# Test Spirit ability usage
	var sac: SpiritAbilityController = p.get_node("Components/SpiritAbilityController") as SpiritAbilityController
	_assert(sac.ability_slots.size() >= 3, "Player has 3 equipped Spirit Abilities")
	_assert(sac.can_cast_ability(sac.ability_slots[0]), "Celestial Arc can be cast with full spirit")
	
	# Test Awakening
	var tc: TransformationController = p.get_node("Components/TransformationController") as TransformationController
	_assert(tc != null, "Player has TransformationController")
	_assert(not tc.is_active(), "Transformation initially inactive")
	_assert(tc.can_activate(), "Wukong Form transformation can_activate() is true with full spirit")
	
	world.queue_free()

# ------------------------------------------------------------------------------
# Category 10: Base VFX & Environmental Atmosphere
# ------------------------------------------------------------------------------
func _test_10_vfx_and_atmosphere() -> void:
	print("\n--- Category 10: Base VFX & Atmosphere ---")
	
	var vfx_scenes: Array[String] = [
		"res://scenes/effects/vfx_hit_spark.tscn",
		"res://scenes/effects/vfx_heavy_impact.tscn",
		"res://scenes/effects/vfx_parry_spark.tscn",
		"res://scenes/effects/vfx_dodge_burst.tscn",
		"res://scenes/effects/vfx_death_burst.tscn",
		"res://scenes/effects/vfx_forest_mist.tscn",
		"res://scenes/effects/vfx_forest_particles.tscn"
	]
	
	for vpath in vfx_scenes:
		_assert(ResourceLoader.exists(vpath), "VFX scene exists: %s" % vpath)
		var scn: PackedScene = load(vpath) as PackedScene
		_assert(scn != null, "VFX scene loads as PackedScene: %s" % vpath)
		var inst: Node2D = scn.instantiate() as Node2D
		_assert(inst != null, "VFX scene instantiates as Node2D: %s" % vpath)
		add_child(inst)
		inst.queue_free()
	
	# Test VFXManager responds to EventBus
	var vfx_mgr: VFXManager = VFXManager.new()
	add_child(vfx_mgr)
	var spawned: Node2D = vfx_mgr.spawn_effect(vfx_mgr.hit_spark_scene, Vector2(100, 100))
	_assert(spawned != null, "VFXManager spawns hit spark successfully")
	vfx_mgr.queue_free()

# ------------------------------------------------------------------------------
# Category 11: End-to-End Persistence & Hitbox Safety
# ------------------------------------------------------------------------------
func _test_11_chapter_persistence_and_hitbox_safety() -> void:
	print("\n--- Category 11: End-to-End Persistence & Hitbox Safety ---")
	
	var world_scene: PackedScene = load("res://scenes/world/forbidden_forest/forbidden_forest_world.tscn")
	var world: ForbiddenForestWorld = world_scene.instantiate() as ForbiddenForestWorld
	add_child(world)
	
	# 1. Simulate defeating Verdant Fang in Room 2
	world.request_room_transition(&"room_02_ancient_grove", &"spawn_from_entrance")
	var vf_arena: BossArenaController = world.active_room.find_child("VerdantFangArena", true, false) as BossArenaController
	_assert(vf_arena != null, "VerdantFangArena found in Room 2")
	vf_arena.complete_encounter()
	_assert(world.world_state.has_flag(&"verdant_fang_defeated"), "verdant_fang_defeated flag set in WorldState")
	
	# 2. Leave Room 2, re-enter Room 2 -> verify boss does not respawn and barriers lowered
	world.request_room_transition(&"room_01_forest_entrance", &"spawn_from_grove")
	world.request_room_transition(&"room_02_ancient_grove", &"spawn_from_entrance")
	var vf_arena_re: BossArenaController = world.active_room.find_child("VerdantFangArena", true, false) as BossArenaController
	_assert(vf_arena_re.is_encounter_completed, "Verdant Fang remains completed upon re-entry")
	_assert(vf_arena_re.left_barrier.collision_layer == 0, "Barriers remain lowered upon re-entry")
	_assert(vf_arena_re.boss.visible == false, "Defeated boss is invisible and disabled")
	
	# 3. Simulate Final Boss Defeat & Chapter Completion
	world.request_room_transition(&"room_05_forest_heart", &"spawn_from_shrine")
	var fh_arena: BossArenaController = world.active_room.find_child("ForestHeartArena", true, false) as BossArenaController
	_assert(fh_arena != null, "ForestHeartArena found in Room 5")
	
	# Hitbox callback safety check during defeat
	fh_arena.boss.hitbox.activate(fh_arena.boss.boss_data.phases[0].attacks[0], fh_arena.boss)
	_assert(fh_arena.boss.hitbox.is_active, "Boss hitbox is active")
	fh_arena.complete_encounter()
	_assert(fh_arena.boss.hitbox.is_active == false, "Boss hitbox safely deactivated upon encounter completion")
	
	# Check chapter completion persistence
	if has_node("/root/EventBus"):
		var bus: Node = get_node("/root/EventBus")
		if bus != null and bus.has_signal("boss_defeated"):
			bus.boss_defeated.emit("Corrupted Forest Heart")
	_assert(world.world_state.has_flag(&"chapter_1_completed"), "chapter_1_completed flag set in WorldState")
	
	world.queue_free()
