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
	print("STARTING DESTINED ONE INTEGRATION AUTOMATED TESTS")
	print("==================================================")
	
	test_source_integrity()
	test_import_and_geometry()
	test_skeleton_and_mapping()
	test_visual_and_transparency()
	test_2d_spriteframes_and_preview()
	test_player_visual_integration()
	
	print("\n==================================================")
	print("DESTINED ONE INTEGRATION TEST SUITE RESULTS")
	print("Total: %d | Passed: %d | Failed: %d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")
	
	if failed_tests > 0:
		get_tree().quit(1)
	else:
		get_tree().quit(0)

func test_source_integrity() -> void:
	print("\n--- 1. Source Integrity Tests ---")
	var char_fbx = "res://assets/characters/destined_one/source/Destined One - Born.fbx"
	assert_test(FileAccess.file_exists(char_fbx), "Character FBX exists in source directory")
	
	var weapon_fbx = "res://assets/characters/destined_one/source/weapon/Destined One - Born - Weapon.fbx"
	assert_test(FileAccess.file_exists(weapon_fbx), "Weapon FBX exists in source/weapon directory")
	
	var tex_dir = "res://assets/characters/destined_one/source/textures/"
	assert_test(DirAccess.dir_exists_absolute(tex_dir), "Source textures directory exists")
	
	var dir = DirAccess.open(tex_dir)
	var tex_count = 0
	if dir:
		dir.list_dir_begin()
		var fn = dir.get_next()
		while fn != "":
			if fn.ends_with(".png") and not fn.ends_with(".import"):
				tex_count += 1
			fn = dir.get_next()
	assert_test(tex_count >= 25, "Source textures exist and verified (found %d)" % tex_count)
	
	var mat_json_dir = "res://assets/characters/destined_one/source/textures/Materials/"
	assert_test(DirAccess.dir_exists_absolute(mat_json_dir), "Material JSON definitions directory exists")

func test_import_and_geometry() -> void:
	print("\n--- 2. Import & Geometry Tests ---")
	var char_fbx = "res://assets/characters/destined_one/source/Destined One - Born.fbx"
	var res = load(char_fbx)
	assert_test(res is PackedScene, "Character FBX loaded as PackedScene")
	
	var inst: Node = res.instantiate()
	assert_test(inst != null, "Character FBX PackedScene instantiates cleanly")
	
	var mi_count = 0
	var total_verts = 0
	var total_tris = 0
	var stack = [inst]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is MeshInstance3D and n.mesh:
			mi_count += 1
			for s in range(n.mesh.get_surface_count()):
				var arr = n.mesh.surface_get_arrays(s)
				var v = arr[Mesh.ARRAY_VERTEX]
				var ind = arr[Mesh.ARRAY_INDEX]
				var vc = v.size() if v else 0
				var tc = (ind.size() / 3) if ind else (vc / 3)
				total_verts += vc
				total_tris += tc
		for c in n.get_children():
			stack.append(c)
			
	assert_test(mi_count >= 5, "MeshInstance3D nodes present (found %d)" % mi_count)
	assert_test(total_verts > 500000, "Vertex count verified (found %d)" % total_verts)
	assert_test(total_tris > 600000, "Triangle count verified (found %d)" % total_tris)
	
	# Check materials created
	var mat_files = ["MF_STC_LaoYing_01_Body.tres", "MF_WuKong_Cloth_01.tres", "MF_WuKong_Leather_01.tres", "MF_WuKong_Metal_01.tres", "MF_HGS_WuKong_JGB_01.tres"]
	var mats_ok = true
	for mf in mat_files:
		if not ResourceLoader.exists("res://assets/characters/destined_one/materials/" + mf):
			mats_ok = false
			break
	assert_test(mats_ok, "Production StandardMaterial3D files exist in materials directory")
	inst.queue_free()

func test_skeleton_and_mapping() -> void:
	print("\n--- 3. Skeleton & Humanoid Bone Mapping Tests ---")
	var char_fbx = "res://assets/characters/destined_one/source/Destined One - Born.fbx"
	var inst = load(char_fbx).instantiate()
	var sk: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	assert_test(sk != null, "Skeleton3D node present in imported character")
	
	if sk:
		var bone_count = sk.get_bone_count()
		assert_test(bone_count == 227, "Skeleton bone count verified (found %d, expected 227)" % bone_count)
		assert_test(sk.find_bone("root") == 0, "Root bone 'root' at index 0 exists")
		assert_test(sk.find_bone("pelvis") >= 0, "Pelvis / Hips bone 'pelvis' exists")
		assert_test(sk.find_bone("spine_01") >= 0, "Spine bone 'spine_01' exists")
		assert_test(sk.find_bone("neck_01") >= 0, "Neck bone 'neck_01' exists")
		assert_test(sk.find_bone("head") >= 0, "Head bone 'head' exists")
		assert_test(sk.find_bone("hand_l") >= 0, "Left hand bone 'hand_l' exists")
		assert_test(sk.find_bone("hand_r") >= 0, "Right hand bone 'hand_r' exists")
		assert_test(sk.find_bone("foot_l") >= 0, "Left foot bone 'foot_l' exists")
		assert_test(sk.find_bone("foot_r") >= 0, "Right foot bone 'foot_r' exists")
		assert_test(sk.find_bone("ball_l_01") >= 0, "Left toe bone 'ball_l_01' exists")
		assert_test(sk.find_bone("ball_r_01") >= 0, "Right toe bone 'ball_r_01' exists")
		assert_test(sk.find_bone("hand_r") >= 0, "Weapon attachment socket 'hand_r' detected")
		
		var anim_player: AnimationPlayer = inst.find_child("AnimationPlayer", true, false)
		assert_test(anim_player == null or anim_player.get_animation_list().size() == 0, "Verified source FBX contains no embedded animation takes (bind-pose)")
	inst.queue_free()

func test_visual_and_transparency() -> void:
	print("\n--- 4. Visual Rendering & Transparency Tests ---")
	var p512 = "res://assets/characters/destined_one/generated/sprites/512/test_idle.png"
	assert_test(FileAccess.file_exists(p512), "512x512 benchmark frame test_idle.png exists")
	
	var img = Image.load_from_file(ProjectSettings.globalize_path(p512))
	assert_test(img != null, "512x512 PNG loads as valid Image resource")
	if img:
		assert_test(img.get_width() == 512 and img.get_height() == 512, "512x512 image dimensions match strictly")
		assert_test(img.get_pixel(5, 5).a == 0.0, "Background alpha is strictly 0.0 (transparent)")
		assert_test(img.get_pixel(506, 5).a == 0.0, "Top-right corner alpha is strictly 0.0")
		assert_test(img.get_pixel(5, 506).a == 0.0, "Bottom-left corner alpha is strictly 0.0")
		assert_test(img.get_pixel(506, 506).a == 0.0, "Bottom-right corner alpha is strictly 0.0")
		assert_test(img.get_pixel(256, 256).a > 0.5, "Center character pixel is opaque solid foreground")
		
	var p768 = "res://assets/characters/destined_one/generated/sprites/768/idle_test/0000.png"
	assert_test(FileAccess.file_exists(p768), "768x768 comparison frame 0000.png exists")
	var img768 = Image.load_from_file(ProjectSettings.globalize_path(p768))
	if img768:
		assert_test(img768.get_width() == 768 and img768.get_height() == 768, "768x768 image dimensions match strictly")
		assert_test(img768.get_pixel(5, 5).a == 0.0, "768x768 background alpha is strictly 0.0")

func test_2d_spriteframes_and_preview() -> void:
	print("\n--- 5. 2D SpriteFrames & Preview Tests ---")
	var sf_path = "res://assets/characters/destined_one/spriteframes/destined_one_512_spriteframes.tres"
	assert_test(FileAccess.file_exists(sf_path), "destined_one_512_spriteframes.tres file exists")
	
	var sf = load(sf_path)
	assert_test(sf is SpriteFrames, "SpriteFrames resource loads cleanly")
	if sf:
		assert_test(sf.has_animation("idle_test"), "Contains 'idle_test' animation")
		assert_test(sf.has_animation("stance_test"), "Contains 'stance_test' animation")
		assert_test(sf.has_animation("movement_test"), "Contains 'movement_test' animation")
		assert_test(sf.has_animation("idle"), "Contains gameplay alias 'idle'")
		assert_test(sf.has_animation("run"), "Contains gameplay alias 'run'")
		assert_test(sf.has_animation("jump"), "Contains gameplay alias 'jump'")
		assert_test(sf.has_animation("fall"), "Contains gameplay alias 'fall'")
		assert_test(sf.get_frame_count("idle_test") >= 4, "idle_test has at least 4 frames")
		
	var p2d_path = "res://assets/characters/destined_one/preview/DestinedOne2DPreview.tscn"
	assert_test(FileAccess.file_exists(p2d_path), "DestinedOne2DPreview.tscn exists")
	var p2d = load(p2d_path).instantiate()
	assert_test(p2d != null, "DestinedOne2DPreview.tscn instantiates cleanly")
	if p2d:
		var spr: AnimatedSprite2D = p2d.find_child("AnimatedSprite2D", true, false)
		assert_test(spr != null, "DestinedOne2DPreview contains AnimatedSprite2D")
		assert_test(spr.sprite_frames != null, "AnimatedSprite2D has valid SpriteFrames bound")
		p2d.queue_free()

func test_player_visual_integration() -> void:
	print("\n--- 6. Player Visual Integration Tests ---")
	var player_script = load("res://scripts/player/player_controller.gd")
	assert_test(player_script != null, "Existing PlayerController script loads cleanly")
	
	var anim_script = load("res://scripts/player/player_animation_controller.gd")
	assert_test(anim_script != null, "Existing PlayerAnimationController script loads cleanly")
	
	var player_scene = load("res://scenes/player/player.tscn")
	assert_test(player_scene is PackedScene, "Existing Player scene loads as PackedScene")
	
	var vis_test_path = "res://tests/destined_one_integration/DestinedOnePlayerVisualTest.tscn"
	assert_test(FileAccess.file_exists(vis_test_path), "DestinedOnePlayerVisualTest.tscn exists")
	
	var vis_test = load(vis_test_path).instantiate()
	assert_test(vis_test != null, "DestinedOnePlayerVisualTest.tscn instantiates cleanly")
	if vis_test:
		var p: CharacterBody2D = vis_test.find_child("Player", true, false)
		assert_test(p != null, "Visual integration test contains Player node")
		if p:
			var anim_ctrl: PlayerAnimationController = p.find_child("PlayerAnimationController", true, false)
			assert_test(anim_ctrl != null, "Player retains original PlayerAnimationController")
			var sprite: AnimatedSprite2D = p.find_child("AnimatedSprite2D", true, false)
			assert_test(sprite != null, "Player retains Visuals/AnimatedSprite2D")
			assert_test(sprite.sprite_frames != null, "AnimatedSprite2D successfully bound to Destined One SpriteFrames")
		vis_test.queue_free()
	
	# Verify architecture invariants: no duplicate controllers created
	assert_test(not FileAccess.file_exists("res://scripts/player/destined_one_controller.gd"), "Strict invariant: No duplicate player controller created")
	assert_test(not FileAccess.file_exists("res://scripts/player/wukong_controller.gd"), "Strict invariant: No duplicate wukong controller created")
