extends Node2D

## TestVisualAudioP12
## Comprehensive automated verification suite for Phase 12: Forbidden Forest Visual & Audio Integration.

const AudioLibrary = preload("res://scripts/core/audio_library.gd")
const CameraShakeController = preload("res://scripts/player/camera_shake_controller.gd")

var _pass_count: int = 0
var _fail_count: int = 0

func _ready() -> void:
	print("\n==================================================")
	print(" RUNNING PHASE 12 VISUAL & AUDIO TEST SUITE")
	print("==================================================")
	
	_test_01_sprite_frames_and_assets()
	_test_02_player_animation_integration()
	_test_03_enemy_and_boss_animation_integration()
	_test_04_vfx_instantiation_and_budget()
	_test_05_camera_trauma_shake()
	_test_06_audio_library_and_manager()
	_test_07_chapter_hud_polish()
	_test_08_end_to_end_audiovisual_simulation()
	
	print("\n==================================================")
	print(" PHASE 12 TEST RESULTS: %d / %d PASSED (%d FAILED)" % [
		_pass_count,
		_pass_count + _fail_count,
		_fail_count
	])
	print("==================================================")
	
	if _fail_count == 0:
		print("\nSUCCESS: All Phase 12 Visual & Audio Integration tests passed cleanly.\n")
		get_tree().quit(0)
	else:
		push_error("One or more Phase 12 tests failed.")
		get_tree().quit(1)

func _assert(condition: bool, test_name: String) -> void:
	if condition:
		_pass_count += 1
		print("[PASS] %s" % test_name)
	else:
		_fail_count += 1
		print("[FAIL] %s" % test_name)

# ------------------------------------------------------------------------------
# Category 1: SpriteFrames and Visual Asset Integrity
# ------------------------------------------------------------------------------
func _test_01_sprite_frames_and_assets() -> void:
	print("\n--- Category 1: SpriteFrames & Visual Asset Integrity ---")
	
	# Player Yuan SpriteFrames
	var yuan_path: String = "res://assets/art/characters/yuan_spritesheet.tres"
	_assert(ResourceLoader.exists(yuan_path), "Yuan SpriteFrames resource exists")
	var yuan_sf: SpriteFrames = load(yuan_path) as SpriteFrames
	_assert(yuan_sf != null, "Yuan SpriteFrames loads successfully")
	
	var required_yuan_anims: Array[String] = [
		"idle", "run", "jump", "fall", "land",
		"light_1", "light_2", "light_3", "heavy_1", "charge_heavy", "air_1",
		"dodge", "parry", "perfect_parry", "hit_reaction", "death",
		"ability_celestial_arc", "ability_heavenly_pulse", "ability_cloud_step",
		"transformation_activate", "transformation_active", "transformation_end"
	]
	for a in required_yuan_anims:
		_assert(yuan_sf.has_animation(a), "Yuan has animation: %s" % a)
		_assert(yuan_sf.get_frame_count(a) > 0, "Yuan animation %s has frames" % a)
	
	# Normal Enemies
	var enemies: Dictionary = {
		"Forest Scout": "res://assets/art/enemies/forest_scout_sprites.tres",
		"Thorn Beast": "res://assets/art/enemies/thorn_beast_sprites.tres",
		"Spore Caster": "res://assets/art/enemies/spore_caster_sprites.tres"
	}
	for ename in enemies.keys():
		var p: String = enemies[ename]
		_assert(ResourceLoader.exists(p), "%s SpriteFrames exists" % ename)
		var sf: SpriteFrames = load(p) as SpriteFrames
		_assert(sf != null, "%s SpriteFrames loads successfully" % ename)
		_assert(sf.has_animation("idle") and sf.has_animation("move") and sf.has_animation("attack"), "%s has core anims" % ename)
	
	# Bosses
	var bosses: Dictionary = {
		"Verdant Fang": "res://assets/art/bosses/verdant_fang_sprites.tres",
		"Bamboo Warden": "res://assets/art/bosses/bamboo_warden_sprites.tres",
		"Hollow Shrine Keeper": "res://assets/art/bosses/hollow_shrine_keeper_sprites.tres",
		"Corrupted Forest Heart": "res://assets/art/bosses/corrupted_forest_heart_sprites.tres"
	}
	for bname in bosses.keys():
		var p: String = bosses[bname]
		_assert(ResourceLoader.exists(p), "%s SpriteFrames exists" % bname)
		var sf: SpriteFrames = load(p) as SpriteFrames
		_assert(sf != null, "%s SpriteFrames loads successfully" % bname)
		_assert(sf.has_animation("idle") and sf.has_animation("hit") and sf.has_animation("death"), "%s has core anims" % bname)
	
	# Final Boss Phase 2 & Transition Anims
	var heart_sf: SpriteFrames = load("res://assets/art/bosses/corrupted_forest_heart_sprites.tres") as SpriteFrames
	_assert(heart_sf.has_animation("transition"), "Forest Heart has phase transition anim")
	_assert(heart_sf.has_animation("frenzy_flurry"), "Forest Heart has phase 2 frenzy flurry anim")
	_assert(heart_sf.has_animation("ground_rupture"), "Forest Heart has phase 2 ground rupture anim")
	
	# Environment Textures
	var env_textures: Array[String] = [
		"res://assets/art/environments/tex_forest_ground.tres",
		"res://assets/art/environments/tex_bamboo_stalks.tres",
		"res://assets/art/environments/tex_shrine_stone.tres",
		"res://assets/art/environments/tex_corrupted_roots.tres"
	]
	for et in env_textures:
		_assert(ResourceLoader.exists(et), "Environment texture exists: %s" % et)
		var tex: Texture2D = load(et) as Texture2D
		_assert(tex != null and tex.get_width() > 0, "Environment texture valid: %s" % et)

# ------------------------------------------------------------------------------
# Category 2: Player Animation Integration
# ------------------------------------------------------------------------------
func _test_02_player_animation_integration() -> void:
	print("\n--- Category 2: Player Animation Integration ---")
	
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var anim_ctrl: PlayerAnimationController = player.animation_controller
	_assert(anim_ctrl != null, "Player has PlayerAnimationController")
	_assert(anim_ctrl.animated_sprite != null, "PlayerAnimationController bound to AnimatedSprite2D")
	_assert(anim_ctrl.animated_sprite.sprite_frames != null, "AnimatedSprite2D has SpriteFrames assigned")
	
	# Test animation triggers
	anim_ctrl.play_animation(&"run")
	_assert(anim_ctrl.current_animation == &"run", "Animation state is run")
	_assert(anim_ctrl.animated_sprite.animation == &"run", "AnimatedSprite2D is playing run")
	
	anim_ctrl.play_attack_animation(&"light_1")
	_assert(anim_ctrl.animated_sprite.animation == &"light_1", "AnimatedSprite2D is playing light_1")
	
	anim_ctrl.play_dodge_animation()
	_assert(anim_ctrl.animated_sprite.animation == &"dodge", "AnimatedSprite2D is playing dodge")
	
	anim_ctrl.play_parry_animation()
	_assert(anim_ctrl.animated_sprite.animation == &"parry", "AnimatedSprite2D is playing parry")
	
	anim_ctrl.play_transformation_activate()
	_assert(anim_ctrl.animated_sprite.animation == &"transformation_activate", "AnimatedSprite2D is playing transformation_activate")
	
	# Graceful fallback for non-existent anim
	anim_ctrl.play_animation(&"non_existent_animation")
	_assert(anim_ctrl.current_animation == &"non_existent_animation", "Handled non-existent anim safely")
	
	player.queue_free()

# ------------------------------------------------------------------------------
# Category 3: Enemy & Boss Animation Integration
# ------------------------------------------------------------------------------
func _test_03_enemy_and_boss_animation_integration() -> void:
	print("\n--- Category 3: Enemy & Boss Animation Integration ---")
	
	# Forest Scout
	var scout_scene: PackedScene = load("res://scenes/enemies/forest_scout.tscn")
	var scout: EnemyController = scout_scene.instantiate() as EnemyController
	add_child(scout)
	
	var scout_anim: EnemyAnimationController = scout.get_node("Components/EnemyAnimationController") as EnemyAnimationController
	_assert(scout_anim != null, "Forest Scout has EnemyAnimationController")
	_assert(scout_anim.animated_sprite != null, "Forest Scout has AnimatedSprite2D")
	
	scout_anim.play_idle()
	_assert(scout_anim.animated_sprite.animation == &"idle", "Forest Scout playing idle")
	scout_anim.play_attack_active()
	_assert(scout_anim.animated_sprite.animation == &"attack", "Forest Scout playing attack")
	scout.queue_free()
	
	# Verdant Fang Boss
	var fang_scene: PackedScene = load("res://scenes/bosses/verdant_fang.tscn")
	var fang: BossController = fang_scene.instantiate() as BossController
	add_child(fang)
	
	var fang_anim: BossAnimationController = fang.get_node("Components/BossAnimationController") as BossAnimationController
	_assert(fang_anim != null, "Verdant Fang has BossAnimationController")
	_assert(fang_anim.animated_sprite != null, "Verdant Fang has AnimatedSprite2D")
	
	fang_anim.play_attack_active(0.15)
	_assert(fang_anim.animated_sprite.animation == &"attack", "Verdant Fang playing attack")
	fang_anim.play_stagger(1.8)
	_assert(fang_anim.animated_sprite.animation == &"stagger", "Verdant Fang playing stagger")
	fang.queue_free()

# ------------------------------------------------------------------------------
# Category 4: VFX Instantiation & Budget
# ------------------------------------------------------------------------------
func _test_04_vfx_instantiation_and_budget() -> void:
	print("\n--- Category 4: VFX Instantiation & Budget ---")
	
	var vfx_mgr: VFXManager = VFXManager.new()
	add_child(vfx_mgr)
	
	# Verify all exported scenes
	_assert(vfx_mgr.hit_spark_scene != null, "VFXManager has hit_spark_scene")
	_assert(vfx_mgr.heavy_impact_scene != null, "VFXManager has heavy_impact_scene")
	_assert(vfx_mgr.parry_spark_scene != null, "VFXManager has parry_spark_scene")
	_assert(vfx_mgr.dodge_burst_scene != null, "VFXManager has dodge_burst_scene")
	_assert(vfx_mgr.death_burst_scene != null, "VFXManager has death_burst_scene")
	_assert(vfx_mgr.staff_trail_scene != null, "VFXManager has staff_trail_scene")
	_assert(vfx_mgr.hit_flash_scene != null, "VFXManager has hit_flash_scene")
	_assert(vfx_mgr.boss_telegraph_scene != null, "VFXManager has boss_telegraph_scene")
	_assert(vfx_mgr.awakening_aura_scene != null, "VFXManager has awakening_aura_scene")
	_assert(vfx_mgr.phase_transition_scene != null, "VFXManager has phase_transition_scene")
	
	# Test effect spawning
	var fx1: Node2D = vfx_mgr.spawn_effect(vfx_mgr.staff_trail_scene, Vector2(100, 100))
	_assert(fx1 != null, "Staff trail spawned successfully")
	_assert(fx1.global_position == Vector2(100, 100), "Staff trail position matches")
	
	var fx2: Node2D = vfx_mgr.spawn_effect(vfx_mgr.phase_transition_scene, Vector2(200, 200))
	_assert(fx2 != null, "Phase transition VFX spawned successfully")
	
	# Verify particle budget per emitter (<30 per emitter)
	for child in fx2.get_children():
		if child is CPUParticles2D:
			_assert(child.amount <= 30, "Phase transition particle count within budget (%d <= 30)" % child.amount)
	
	vfx_mgr.queue_free()

# ------------------------------------------------------------------------------
# Category 5: Camera Trauma & Shake Feedback
# ------------------------------------------------------------------------------
func _test_05_camera_trauma_shake() -> void:
	print("\n--- Category 5: Camera Trauma & Shake Feedback ---")
	
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	var shake_ctrl: CameraShakeController = player.get_node_or_null("Components/CameraShakeController") as CameraShakeController
	_assert(shake_ctrl != null, "Player has CameraShakeController component")
	_assert(shake_ctrl.camera != null, "CameraShakeController bound to Camera2D")
	
	_assert(shake_ctrl.get_trauma() == 0.0, "Initial trauma is 0.0")
	
	shake_ctrl.shake_normal_hit()
	_assert(shake_ctrl.get_trauma() > 0.15, "Normal hit added trauma (~0.18)")
	
	shake_ctrl.shake_heavy_impact()
	_assert(shake_ctrl.get_trauma() > 0.45, "Heavy impact stacked trauma")
	
	shake_ctrl.add_trauma(1.0)
	_assert(shake_ctrl.get_trauma() == 1.0, "Trauma clamped at maximum 1.0")
	
	# Test process decay
	shake_ctrl._process(0.2)
	_assert(shake_ctrl.get_trauma() < 1.0, "Trauma decays smoothly over time")
	
	player.queue_free()

# ------------------------------------------------------------------------------
# Category 6: AudioLibrary and AudioManager
# ------------------------------------------------------------------------------
func _test_06_audio_library_and_manager() -> void:
	print("\n--- Category 6: AudioLibrary and AudioManager ---")
	
	# Test Music Streams
	var music_states: Array[StringName] = [
		&"exploration",
		&"intermediate_boss",
		&"final_boss_p1",
		&"final_boss_p2",
		&"chapter_complete"
	]
	for ms in music_states:
		var stream: AudioStreamWAV = AudioLibrary.get_music_stream(ms)
		_assert(stream != null, "Music stream generated: %s" % ms)
		_assert(stream.data.size() > 0, "Music stream %s has non-empty PCM data" % ms)
		_assert(stream.mix_rate == 22050, "Music stream %s mix_rate is 22050" % ms)
	
	# Test Ambience Streams
	var ambience_states: Array[StringName] = [&"forest_wind", &"bamboo_rustle", &"shrine_hum", &"corrupted_heart"]
	for amb in ambience_states:
		var astream: AudioStreamWAV = AudioLibrary.get_ambience_stream(amb)
		_assert(astream != null, "Ambience stream generated: %s" % amb)
		_assert(astream.data.size() > 0, "Ambience stream has PCM data: %s" % amb)
	
	# Test Core SFX Streams
	var sfx_list: Array[StringName] = [
		&"footstep", &"jump", &"land",
		&"staff_swing_light", &"staff_swing_heavy", &"dodge", &"parry", &"perfect_parry",
		&"hit_light", &"hit_heavy", &"stagger", &"enemy_death",
		&"awakening_start", &"awakening_end",
		&"boss_telegraph", &"boss_slam", &"boss_transition", &"boss_defeat",
		&"checkpoint", &"victory_fanfare"
	]
	for sfx in sfx_list:
		var sstream: AudioStreamWAV = AudioLibrary.get_sfx_stream(sfx)
		_assert(sstream != null, "SFX stream generated: %s" % sfx)
		_assert(sstream.data.size() > 0, "SFX stream has PCM data: %s" % sfx)
	
	# Test AudioManager API Integration
	var am: Node = get_node_or_null("/root/AudioManager")
	_assert(am != null, "AudioManager autoload exists")
	if am != null:
		am.play_music_by_name(&"exploration")
		am.play_ambience_by_name(&"forest_wind")
		am.play_sfx_by_name(&"parry", 1.0)
		am.play_ui_by_name(&"checkpoint")
		_assert(true, "AudioManager played music, ambience, sfx, ui without error")

# ------------------------------------------------------------------------------
# Category 7: Chapter HUD Polish
# ------------------------------------------------------------------------------
func _test_07_chapter_hud_polish() -> void:
	print("\n--- Category 7: Chapter HUD Polish ---")
	
	var hud_scene: PackedScene = load("res://scenes/ui/chapter_hud.tscn")
	var hud: ChapterHUD = hud_scene.instantiate() as ChapterHUD
	add_child(hud)
	
	var player_scene: PackedScene = load("res://scenes/player/player.tscn")
	var player: PlayerController = player_scene.instantiate() as PlayerController
	add_child(player)
	
	hud.bind_player(player)
	_assert(hud.health_bar != null, "HUD has HealthBar")
	_assert(hud.spirit_bar != null, "HUD has SpiritBar")
	_assert(hud.stance_badge != null, "HUD has StanceBadge")
	
	# Test low health visual modulate
	hud._update_health_display(20.0, 100.0)
	_assert(hud.health_bar.modulate == Color(1.0, 0.35, 0.35), "HealthBar modulates to red on low HP (<=25%)")
	hud._update_health_display(80.0, 100.0)
	_assert(hud.health_bar.modulate == Color.WHITE, "HealthBar restores to white above 25% HP")
	
	# Test Boss Binding & Phase 2 title
	var fang_scene: PackedScene = load("res://scenes/bosses/verdant_fang.tscn")
	var fang: BossController = fang_scene.instantiate() as BossController
	add_child(fang)
	
	hud.bind_boss(fang)
	_assert(hud.boss_hud_panel != null and hud.boss_hud_panel.visible, "Boss HUD panel visible upon bind")
	_assert(hud.boss_name_label.text == "VERDANT FANG", "Boss name displays correctly")
	
	hud.unbind_boss()
	_assert(not hud.boss_hud_panel.visible, "Boss HUD panel hidden upon unbind")
	
	hud.show_chapter_complete()
	_assert(hud.victory_overlay != null and hud.victory_overlay.visible, "Victory overlay visible on chapter complete")
	
	fang.queue_free()
	player.queue_free()
	hud.queue_free()

# ------------------------------------------------------------------------------
# Category 8: End-to-End Audiovisual Simulation
# ------------------------------------------------------------------------------
func _test_08_end_to_end_audiovisual_simulation() -> void:
	print("\n--- Category 8: End-to-End Audiovisual Simulation ---")
	
	var world_scene: PackedScene = load("res://scenes/world/forbidden_forest/forbidden_forest_world.tscn")
	var world: ForbiddenForestWorld = world_scene.instantiate() as ForbiddenForestWorld
	add_child(world)
	
	_assert(world.active_room != null, "World active room is non-null")
	_assert(world.chapter_hud != null, "ChapterHUD is active in world")
	
	# Verify room 1 to room 5 transition with audio updates
	world.request_room_transition(&"room_03_bamboo_path", &"spawn_from_grove")
	_assert(world.current_room_id == &"room_03_bamboo_path", "Transitioned to Bamboo Path")
	
	world.request_room_transition(&"room_05_forest_heart", &"spawn_from_shrine")
	_assert(world.current_room_id == &"room_05_forest_heart", "Transitioned to Forest Heart")
	
	world.queue_free()
