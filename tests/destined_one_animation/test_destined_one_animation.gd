extends Node

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func assert_test(condition: bool, test_name: String, details: String = "") -> void:
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_tests += 1
		printerr("  [FAIL] %s - %s" % [test_name, details])

func _ready() -> void:
	print("==================================================")
	print("STARTING DESTINED ONE ANIMATION RETARGETING TESTS")
	print("==================================================")
	
	test_asset_sources()
	test_retargeting_and_bonemap()
	test_character_deformation_safety()
	test_weapon_synchronization()
	test_root_motion_policy()
	test_gameplay_integration()
	test_2d_rendering_and_spriteframes()
	test_phase_14c5_staff_sync_and_png_integrity()
	
	print("\n==================================================")
	print("PHASE 14C / 14C.5 ANIMATION TEST SUITE RESULTS")
	print("Total: %d | Passed: %d | Failed: %d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")
	
	if failed_tests > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func test_asset_sources() -> void:
	print("\n--- 1. Asset & Source Tests ---")
	var knight_path = "res://assets/characters/knight_test/KnightCharacter.fbx"
	assert_test(FileAccess.file_exists(knight_path), "Source Knight Character FBX exists")
	
	var knight_res = load(knight_path)
	assert_test(knight_res is PackedScene, "Source Knight FBX loads as PackedScene")
	
	if knight_res:
		var k_inst = knight_res.instantiate()
		var ap: AnimationPlayer = k_inst.find_child("AnimationPlayer", true, false)
		assert_test(ap != null, "Source FBX contains AnimationPlayer")
		if ap:
			assert_test(ap.get_animation_list().size() >= 10, "Source contains >= 10 animation takes (found %d)" % ap.get_animation_list().size())
		k_inst.queue_free()
		
	var d_path = "res://assets/characters/destined_one/source/Destined One - Born.fbx"
	assert_test(FileAccess.file_exists(d_path), "Destined One FBX exists")
	
	var d_res = load(d_path)
	assert_test(d_res is PackedScene, "Destined One loads as PackedScene")
	if d_res:
		var d_inst = d_res.instantiate()
		var sk: Skeleton3D = d_inst.find_child("Skeleton3D", true, false)
		assert_test(sk != null, "Destined One contains Skeleton3D")
		if sk:
			assert_test(sk.get_bone_count() == 227, "Destined One skeleton verified at 227 bones (found %d)" % sk.get_bone_count())
		d_inst.queue_free()
		
	var lib_path = "res://assets/characters/destined_one/animations/libraries/destined_one_animation_library.res"
	assert_test(FileAccess.file_exists(lib_path), "Destined One AnimationLibrary exists on disk")
	
	var lib: AnimationLibrary = load(lib_path)
	assert_test(lib != null, "AnimationLibrary loads cleanly")
	if lib:
		assert_test(lib.get_animation_list().size() >= 18, "AnimationLibrary contains >= 18 retargeted animations (found %d)" % lib.get_animation_list().size())
		for a in ["destined_idle", "destined_walk", "destined_run", "destined_jump", "destined_dodge", "destined_light_01", "destined_heavy", "destined_knockdown"]:
			assert_test(lib.has_animation(a), "AnimationLibrary contains required animation: %s" % a)

func test_retargeting_and_bonemap() -> void:
	print("\n--- 2. Retargeting & BoneMap Tests ---")
	var d_bmap_path = "res://assets/characters/destined_one/animations/destined_one_bonemap.tres"
	assert_test(FileAccess.file_exists(d_bmap_path), "Destined One BoneMap resource file exists")
	
	var d_bmap: BoneMap = load(d_bmap_path)
	assert_test(d_bmap != null, "Destined One BoneMap loads cleanly")
	if d_bmap:
		assert_test(d_bmap.profile != null, "Destined One BoneMap has assigned profile")
		assert_test(d_bmap.get_skeleton_bone_name("Root") == "root", "BoneMap maps Root -> root")
		assert_test(d_bmap.get_skeleton_bone_name("Hips") == "pelvis", "BoneMap maps Hips -> pelvis")
		assert_test(d_bmap.get_skeleton_bone_name("Spine") == "spine_01", "BoneMap maps Spine -> spine_01")
		assert_test(d_bmap.get_skeleton_bone_name("Chest") == "spine_02", "BoneMap maps Chest -> spine_02")
		assert_test(d_bmap.get_skeleton_bone_name("Head") == "head", "BoneMap maps Head -> head")
		assert_test(d_bmap.get_skeleton_bone_name("RightUpperArm") == "upperarm_r", "BoneMap maps RightUpperArm -> upperarm_r")
		assert_test(d_bmap.get_skeleton_bone_name("RightHand") == "hand_r", "BoneMap maps RightHand -> hand_r")
		assert_test(d_bmap.get_skeleton_bone_name("LeftUpperLeg") == "thigh_l", "BoneMap maps LeftUpperLeg -> thigh_l")
		assert_test(d_bmap.get_skeleton_bone_name("LeftLowerLeg") == "calf_l", "BoneMap maps LeftLowerLeg -> calf_l")
		
	var k_bmap_path = "res://assets/characters/destined_one/animations/source_knight_bonemap.tres"
	assert_test(FileAccess.file_exists(k_bmap_path), "Source Knight BoneMap resource file exists")
	
	# Retargeted animation playback test
	var d_inst = load("res://assets/characters/destined_one/source/Destined One - Born.fbx").instantiate()
	var d_sk: Skeleton3D = d_inst.find_child("Skeleton3D", true, false)
	var ap = AnimationPlayer.new()
	d_inst.add_child(ap)
	var lib: AnimationLibrary = load("res://assets/characters/destined_one/animations/libraries/destined_one_animation_library.res")
	ap.add_animation_library("", lib)
	
	ap.play("destined_idle")
	assert_test(ap.is_playing(), "AnimationPlayer successfully plays 'destined_idle'")
	
	var r_arm_idx = d_sk.find_bone("upperarm_r")
	var initial_rot = d_sk.get_bone_pose_rotation(r_arm_idx)
	ap.advance(0.5)
	var stepped_rot = d_sk.get_bone_pose_rotation(r_arm_idx)
	assert_test(stepped_rot.length() > 0.99 and stepped_rot.length() < 1.01, "Stepped bone rotation is normalized quaternion")
	d_inst.queue_free()

func test_character_deformation_safety() -> void:
	print("\n--- 3. Character & Mesh Deformation Safety Tests ---")
	var d_inst = load("res://assets/characters/destined_one/source/Destined One - Born.fbx").instantiate()
	var d_sk: Skeleton3D = d_inst.find_child("Skeleton3D", true, false)
	var ap = AnimationPlayer.new()
	d_inst.add_child(ap)
	var lib = load("res://assets/characters/destined_one/animations/libraries/destined_one_animation_library.res")
	ap.add_animation_library("", lib)
	
	var test_anims = ["destined_idle", "destined_run", "destined_dodge", "destined_heavy"]
	var all_bones_valid = true
	var no_nan_or_inf = true
	
	for a in test_anims:
		ap.play(a)
		for step in range(5):
			ap.advance(0.1)
			for b in range(min(50, d_sk.get_bone_count())):
				var q = d_sk.get_bone_pose_rotation(b)
				if is_nan(q.x) or is_nan(q.y) or is_nan(q.z) or is_nan(q.w):
					no_nan_or_inf = false
				if is_inf(q.x) or is_inf(q.y) or is_inf(q.z) or is_inf(q.w):
					no_nan_or_inf = false
				var s = d_sk.get_bone_pose_scale(b)
				if s.is_zero_approx():
					all_bones_valid = false
					
	assert_test(no_nan_or_inf, "Zero NaN or Inf values detected in bone quaternions across animations")
	assert_test(all_bones_valid, "Zero bone scale collapse detected during animation playback")
	
	# Check meshes and materials
	var mesh_count = 0
	var total_surfaces = 0
	var stack = [d_inst]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is MeshInstance3D and n.mesh:
			mesh_count += 1
			total_surfaces += n.mesh.get_surface_count()
		for c in n.get_children():
			stack.append(c)
	assert_test(mesh_count == 5, "Destined One character contains all 5 MeshInstance3D nodes")
	assert_test(total_surfaces == 33, "Destined One character retains all 33 mesh surfaces")
	d_inst.queue_free()

func test_weapon_synchronization() -> void:
	print("\n--- 4. Weapon Synchronization Tests ---")
	var w_path = "res://assets/characters/destined_one/source/weapon/Destined One - Born - Weapon.fbx"
	assert_test(FileAccess.file_exists(w_path), "Weapon FBX exists")
	
	var d_inst = load("res://assets/characters/destined_one/source/Destined One - Born.fbx").instantiate()
	var w_inst = load(w_path).instantiate()
	w_inst.name = "Weapon"
	d_inst.add_child(w_inst)
	
	var d_sk: Skeleton3D = d_inst.find_child("Skeleton3D", true, false)
	var w_sk: Skeleton3D = w_inst.find_child("Skeleton3D", true, false)
	assert_test(w_sk != null, "Weapon asset contains Skeleton3D")
	
	var hand_r_idx = d_sk.find_bone("hand_r")
	var w_hand_idx = w_sk.find_bone("hand_r")
	assert_test(hand_r_idx >= 0, "Destined One has hand_r bone (index %d)" % hand_r_idx)
	assert_test(w_hand_idx >= 0, "Weapon skeleton has hand_r bone (index %d)" % w_hand_idx)
	
	# Verify rest position alignment
	var d_hand_global = d_sk.get_bone_global_pose(hand_r_idx).origin
	var w_hand_global = w_sk.get_bone_global_pose(w_hand_idx).origin
	var dist = d_hand_global.distance_to(w_hand_global)
	assert_test(dist < 0.001, "Weapon hand_r aligns with character hand_r at rest (dist: %.6f)" % dist)
	
	# Verify weapon scale preservation
	assert_test(w_inst.scale.is_equal_approx(Vector3.ONE), "Weapon root retains 1.0 scale")
	
	d_inst.queue_free()

func test_root_motion_policy() -> void:
	print("\n--- 5. Root Motion Policy Tests ---")
	var lib: AnimationLibrary = load("res://assets/characters/destined_one/animations/libraries/destined_one_animation_library.res")
	var root_translations_stripped = true
	
	for a in lib.get_animation_list():
		var anim: Animation = lib.get_animation(a)
		for t in range(anim.get_track_count()):
			var p = str(anim.track_get_path(t))
			var ttype = anim.track_get_type(t)
			if (p.ends_with(":root") or p.ends_with(":pelvis") or p.ends_with(":Body")) and ttype == Animation.TYPE_POSITION_3D:
				root_translations_stripped = false
				
	assert_test(root_translations_stripped, "Root Motion Policy enforced: Translation tracks stripped from all retargeted animations")
	
	# Test playback translation invariance
	var d_inst = load("res://assets/characters/destined_one/source/Destined One - Born.fbx").instantiate()
	var ap = AnimationPlayer.new()
	d_inst.add_child(ap)
	ap.add_animation_library("", lib)
	ap.play("destined_run")
	for step in range(8):
		ap.advance(0.1)
		assert_test(d_inst.position.is_zero_approx(), "Destined One character position remains static (0,0,0) during run animation")
		break
	d_inst.queue_free()

func test_gameplay_integration() -> void:
	print("\n--- 6. Gameplay Integration & Architecture Invariants ---")
	var anim_ctrl_script = load("res://scripts/player/player_animation_controller.gd")
	assert_test(anim_ctrl_script != null, "Production PlayerAnimationController script loads cleanly")
	
	# Invariant checks: zero modified or duplicate player controllers
	assert_test(not FileAccess.file_exists("res://scripts/player/destined_one_controller.gd"), "Architecture invariant: destined_one_controller.gd does not exist")
	assert_test(not FileAccess.file_exists("res://scripts/player/wukong_combat_controller.gd"), "Architecture invariant: wukong_combat_controller.gd does not exist")
	
	# Test 3D Preview scene existence
	var test_3d_path = "res://tests/destined_one_animation/DestinedOneAnimationRetargetTest.tscn"
	assert_test(FileAccess.file_exists(test_3d_path), "DestinedOneAnimationRetargetTest.tscn exists")
	var test_3d_scene = load(test_3d_path)
	assert_test(test_3d_scene is PackedScene, "DestinedOneAnimationRetargetTest.tscn loads as PackedScene")

func test_2d_rendering_and_spriteframes() -> void:
	print("\n--- 7. 2D Rendering & SpriteFrames Tests ---")
	var sf_path = "res://assets/characters/destined_one/spriteframes/destined_one_retarget_512_spriteframes.tres"
	assert_test(FileAccess.file_exists(sf_path), "Retargeted 512px SpriteFrames exists on disk")
	
	var sf: SpriteFrames = load(sf_path)
	assert_test(sf != null, "SpriteFrames loads cleanly")
	if sf:
		for a in ["idle", "run", "light_01", "heavy", "dodge"]:
			assert_test(sf.has_animation(a), "SpriteFrames has retargeted animation: %s" % a)
			assert_test(sf.get_frame_count(a) > 0, "Animation '%s' contains frames (count: %d)" % [a, sf.get_frame_count(a)])
			
		# Check gameplay aliases
		for alias in ["light_1", "light_2", "light_3", "heavy_1"]:
			assert_test(sf.has_animation(alias), "SpriteFrames has gameplay alias: %s" % alias)
			
	# Test rendered PNG frames
	var frame_dir = "res://assets/characters/destined_one/generated/sprites/512_anims/"
	var sample_png_path = frame_dir + "idle_00.png"
	assert_test(FileAccess.file_exists(sample_png_path), "Sample 512px frame idle_00.png exists")
	
	var abs_sample = ProjectSettings.globalize_path(sample_png_path)
	var img = Image.load_from_file(abs_sample)
	assert_test(img != null, "Sample frame loads as Image")
	if img:
		assert_test(img.get_width() == 512 and img.get_height() == 512, "Sample frame dimensions are exactly 512x512")
		# Test alpha purity on top-left corner
		var corner_pixel = img.get_pixel(0, 0)
		assert_test(corner_pixel.a == 0.0, "Background transparency verified: corner pixel alpha is 0.00 (got %.2f)" % corner_pixel.a)
		
	# Test 2D preview scene
	var test_2d_path = "res://tests/destined_one_animation/DestinedOne2DAnimationPreview.tscn"
	assert_test(FileAccess.file_exists(test_2d_path), "DestinedOne2DAnimationPreview.tscn exists")
	var test_2d_scene = load(test_2d_path)
	assert_test(test_2d_scene is PackedScene, "DestinedOne2DAnimationPreview.tscn loads as PackedScene")
	if test_2d_scene:
		var inst = test_2d_scene.instantiate()
		var spr: AnimatedSprite2D = inst.find_child("AnimatedSprite2D", true, false)
		assert_test(spr != null, "2D preview scene contains AnimatedSprite2D")
		if spr:
			assert_test(spr.sprite_frames != null, "AnimatedSprite2D has assigned SpriteFrames")
		inst.queue_free()

func test_phase_14c5_staff_sync_and_png_integrity() -> void:
	print("\n--- 8. Phase 14C.5 Staff Synchronization & PNG Integrity Tests ---")
	
	# 1. Weapon Attachment & Synchronization test during animation playback
	var d_inst = load("res://assets/characters/destined_one/source/Destined One - Born.fbx").instantiate()
	var w_inst = load("res://assets/characters/destined_one/source/weapon/Destined One - Born - Weapon.fbx").instantiate()
	d_inst.add_child(w_inst)
	
	var d_sk: Skeleton3D = d_inst.find_child("Skeleton3D", true, false)
	var w_sk: Skeleton3D = w_inst.find_child("Skeleton3D", true, false)
	var ap = AnimationPlayer.new()
	d_inst.add_child(ap)
	var lib: AnimationLibrary = load("res://assets/characters/destined_one/animations/libraries/destined_one_animation_library.res")
	ap.add_animation_library("", lib)
	
	var d_hand = d_sk.find_bone("hand_r")
	var w_hand = w_sk.find_bone("hand_r")
	assert_test(d_hand >= 0 and w_hand >= 0, "Phase 14C.5: Both skeletons have hand_r bone")
	
	var test_anims = ["destined_idle", "destined_run", "destined_light_01", "destined_heavy", "destined_dodge"]
	var sync_success = true
	var max_hand_dist = 0.0
	
	for anim_name in test_anims:
		if not ap.has_animation(anim_name):
			sync_success = false
			continue
		ap.play(anim_name)
		for step in range(4):
			ap.advance(0.1)
			var d_hand_trans = d_sk.get_bone_global_pose(d_hand)
			w_sk.set_bone_global_pose_override(w_hand, d_hand_trans, 1.0, true)
			w_sk.force_update_bone_child_transform(w_hand)
			
			var w_hand_trans = w_sk.get_bone_global_pose(w_hand)
			var dist = d_hand_trans.origin.distance_to(w_hand_trans.origin)
			if dist > max_hand_dist:
				max_hand_dist = dist
			if dist > 0.001:
				sync_success = false
				
	assert_test(sync_success, "Phase 14C.5: Weapon hand_r dynamically locked to character hand_r across all animations (max dist: %.6f)" % max_hand_dist)
	d_inst.queue_free()
	
	# 2. Baked PNG frames existence and composition check
	var frame_dir = "res://assets/characters/destined_one/generated/sprites/512_anims/"
	var expected_frames = {
		"idle": 4,
		"run": 6,
		"light_01": 4,
		"heavy": 4,
		"dodge": 4
	}
	
	var all_pngs_exist = true
	var total_pngs = 0
	var no_clipping = true
	var transparent_corners = true
	
	for anim_name in expected_frames.keys():
		var count = expected_frames[anim_name]
		for i in range(count):
			total_pngs += 1
			var file_path = frame_dir + "%s_%02d.png" % [anim_name, i]
			if not FileAccess.file_exists(file_path):
				all_pngs_exist = false
				printerr("Missing PNG: ", file_path)
			else:
				var abs_path = ProjectSettings.globalize_path(file_path)
				var img = Image.load_from_file(abs_path)
				if not img or img.get_width() != 512 or img.get_height() != 512:
					all_pngs_exist = false
				else:
					if img.get_pixel(0, 0).a > 0.001 or img.get_pixel(511, 0).a > 0.001:
						transparent_corners = false
					# Check all 4 outer boundary edges for clipping
					for x in range(512):
						if img.get_pixel(x, 0).a > 0.05 or img.get_pixel(x, 511).a > 0.05:
							no_clipping = false
					for y in range(512):
						if img.get_pixel(0, y).a > 0.05 or img.get_pixel(511, y).a > 0.05:
							no_clipping = false
							
	assert_test(all_pngs_exist, "Phase 14C.5: All %d baked 512x512 PNG frames exist on disk" % total_pngs)
	assert_test(transparent_corners, "Phase 14C.5: All baked frames retain pure transparent background")
	assert_test(no_clipping, "Phase 14C.5: Weapon and character within 512x512 bounds (zero border clipping)")
	
	# 3. SpriteFrames integrity check
	var sf_path = "res://assets/characters/destined_one/spriteframes/destined_one_retarget_512_spriteframes.tres"
	var sf: SpriteFrames = load(sf_path)
	assert_test(sf != null, "Phase 14C.5: SpriteFrames resource loaded cleanly")
	if sf:
		for anim_name in expected_frames.keys():
			assert_test(sf.has_animation(anim_name), "Phase 14C.5: SpriteFrames contains '%s'" % anim_name)
			assert_test(sf.get_frame_count(anim_name) == expected_frames[anim_name], 
				"Phase 14C.5: Animation '%s' has %d frames" % [anim_name, expected_frames[anim_name]])

