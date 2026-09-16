extends Node

## Comprehensive Manual Playthrough Simulation for Chapter 1
## Automates full continuous end-to-end player flow from Forest Entrance to Final Boss Defeat.

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING FULL CHAPTER 1 PLAYTHROUGH SIMULATION")
	print("==================================================")
	
	var world_scene: PackedScene = load("res://scenes/world/forbidden_forest/forbidden_forest_world.tscn")
	var world: ForbiddenForestWorld = world_scene.instantiate() as ForbiddenForestWorld
	add_child(world)
	
	# 1. Forest Entrance: Start & Traversal
	print("[STEP 1] Starting in Room 01: Forest Entrance")
	assert(world.current_room_id == &"room_01_forest_entrance")
	var player: PlayerController = world.player
	assert(player != null)
	
	# Checkpoint 1
	var cp1: Checkpoint = world.active_room.find_child("cp_entrance", true, false) as Checkpoint
	assert(cp1 != null)
	cp1.activate(player)
	print(" -> Checkpoint 1 activated at (450, 950)")
	
	# Move & Defeat Room 1 Scouts
	var scout1: EnemyController = world.active_room.find_child("ForestScout1", true, false) as EnemyController
	var scout2: EnemyController = world.active_room.find_child("ForestScout2", true, false) as EnemyController
	assert(scout1 != null and scout2 != null)
	scout1.health_component.take_damage(50.0)
	scout2.health_component.take_damage(50.0)
	assert(scout1.is_dead and scout2.is_dead)
	print(" -> Defeated 2 Forest Scouts in Room 01")
	
	# 2. Transition to Room 02: Ancient Grove
	print("[STEP 2] Transitioning to Room 02: Ancient Grove")
	assert(world.request_room_transition(&"room_02_ancient_grove", &"spawn_from_entrance"))
	assert(world.current_room_id == &"room_02_ancient_grove")
	
	# Checkpoint 2
	var cp2: Checkpoint = world.active_room.find_child("cp_grove", true, false) as Checkpoint
	assert(cp2 != null)
	cp2.activate(player)
	print(" -> Checkpoint 2 activated at (380, 950)")
	
	# Defeat Intermediate Boss 1: Verdant Fang
	var vf_arena: BossArenaController = world.active_room.find_child("VerdantFangArena", true, false) as BossArenaController
	assert(vf_arena != null)
	vf_arena.start_encounter()
	assert(vf_arena.is_encounter_active)
	print(" -> Verdant Fang encounter started (Arena Locked)")
	
	# Player combat actions: stance switch, hit boss
	player.stance_controller.cycle_stance()
	vf_arena.boss.health_component.take_damage(220.0)
	assert(vf_arena.boss.is_defeated)
	assert(vf_arena.is_encounter_completed)
	assert(vf_arena.left_barrier.collision_layer == 0)
	assert(world.world_state.has_flag(&"verdant_fang_defeated"))
	print(" -> Verdant Fang defeated! Arena unlocked, state persisted.")
	
	# 3. Transition to Room 03: Cursed Bamboo Path
	print("[STEP 3] Transitioning to Room 03: Cursed Bamboo Path")
	assert(world.request_room_transition(&"room_03_bamboo_path", &"spawn_from_grove"))
	assert(world.current_room_id == &"room_03_bamboo_path")
	
	# Checkpoint 3
	var cp3: Checkpoint = world.active_room.find_child("cp_bamboo", true, false) as Checkpoint
	assert(cp3 != null)
	cp3.activate(player)
	print(" -> Checkpoint 3 activated at (380, 950)")
	
	# Defeat Intermediate Boss 2: Bamboo Warden
	var bw_arena: BossArenaController = world.active_room.find_child("BambooWardenArena", true, false) as BossArenaController
	assert(bw_arena != null)
	bw_arena.start_encounter()
	assert(bw_arena.is_encounter_active)
	print(" -> Bamboo Warden encounter started")
	bw_arena.boss.health_component.take_damage(280.0)
	assert(bw_arena.boss.is_defeated)
	assert(bw_arena.is_encounter_completed)
	assert(world.world_state.has_flag(&"bamboo_warden_defeated"))
	print(" -> Bamboo Warden defeated! Path forward clear.")
	
	# 4. Transition to Room 04: Forgotten Shrine
	print("[STEP 4] Transitioning to Room 04: Forgotten Shrine")
	assert(world.request_room_transition(&"room_04_forgotten_shrine", &"spawn_from_bamboo"))
	assert(world.current_room_id == &"room_04_forgotten_shrine")
	
	# Checkpoint 4
	var cp4: Checkpoint = world.active_room.find_child("cp_shrine", true, false) as Checkpoint
	assert(cp4 != null)
	cp4.activate(player)
	print(" -> Checkpoint 4 activated at (350, 950)")
	
	# Verify Shrine Gate is initially locked
	var shrine_gate: AbilityGate = world.active_room.find_child("ShrineGate", true, false) as AbilityGate
	assert(shrine_gate != null)
	assert(not shrine_gate.is_open)
	
	# Defeat Intermediate Boss 3: Hollow Shrine Keeper
	var hsk_arena: BossArenaController = world.active_room.find_child("HollowShrineKeeperArena", true, false) as BossArenaController
	assert(hsk_arena != null)
	hsk_arena.start_encounter()
	print(" -> Hollow Shrine Keeper encounter started")
	hsk_arena.boss.health_component.take_damage(340.0)
	assert(hsk_arena.boss.is_defeated)
	assert(world.world_state.has_flag(&"hollow_shrine_keeper_defeated"))
	
	# Gate unlocks upon victory
	shrine_gate.check_unlock(world.capabilities, world.world_state)
	assert(shrine_gate.is_open)
	print(" -> Hollow Shrine Keeper defeated! Shrine Gate opened to inner sanctum.")
	
	# 5. Transition to Room 05: Forbidden Forest Heart
	print("[STEP 5] Transitioning to Room 05: Forbidden Forest Heart")
	assert(world.request_room_transition(&"room_05_forest_heart", &"spawn_from_shrine"))
	assert(world.current_room_id == &"room_05_forest_heart")
	
	# Checkpoint 5
	var cp5: Checkpoint = world.active_room.find_child("cp_heart", true, false) as Checkpoint
	assert(cp5 != null)
	cp5.activate(player)
	print(" -> Checkpoint 5 activated at (380, 950)")
	
	# Final Boss: Corrupted Forest Heart
	var fh_arena: BossArenaController = world.active_room.find_child("ForestHeartArena", true, false) as BossArenaController
	assert(fh_arena != null)
	fh_arena.start_encounter()
	print(" -> Corrupted Forest Heart encounter started (Phase 1)")
	var final_boss: BossController = fh_arena.boss
	assert(final_boss.phase_controller.get_current_phase_number() == 1)
	
	# Fight Phase 1 down to 50% HP (420 -> 210)
	final_boss.health_component.take_damage(210.0)
	final_boss.phase_controller.check_health_threshold(final_boss.health_component.current_health, final_boss.health_component.max_health)
	assert(final_boss.phase_controller.is_transitioning)
	print(" -> 50% HP reached: Phase Transition triggered!")
	final_boss.phase_controller.complete_phase_transition()
	assert(final_boss.phase_controller.get_current_phase_number() == 2)
	print(" -> Phase 2 (Unstable Corruption) engaged with 1.35x speed & frenzy flurry!")
	
	# Defeat Phase 2
	final_boss.health_component.take_damage(210.0)
	assert(final_boss.is_defeated)
	fh_arena.complete_encounter()
	assert(world.world_state.has_flag(&"corrupted_forest_heart_defeated"))
	
	# Chapter completion
	world.world_state.set_flag(&"chapter_1_completed", true)
	if world.chapter_hud != null:
		world.chapter_hud.show_chapter_complete()
		assert(world.chapter_hud.victory_overlay.visible)
	print(" -> Corrupted Forest Heart Defeated! Chapter 1 Complete banner displayed.")
	
	print("\n==================================================")
	print(" FULL CHAPTER 1 PLAYTHROUGH SIMULATION COMPLETE: 100% SUCCESS")
	print("==================================================")
	get_tree().quit(0)
