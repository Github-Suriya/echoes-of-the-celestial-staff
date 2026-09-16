extends SceneTree

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

func _init() -> void:
	print("==================================================")
	print("STARTING WUKONG ASSET AUDIT AUTOMATED TEST SUITE")
	print("==================================================")
	
	test_source_integrity()
	test_import_and_geometry()
	test_skeleton()
	test_animation_audit()
	test_rendering_and_png_integrity()
	test_2d_pipeline()
	
	print("\n==================================================")
	print("WUKONG AUDIT TEST SUITE RESULTS")
	print("Total: %d | Passed: %d | Failed: %d" % [total_tests, passed_tests, failed_tests])
	print("==================================================")
	
	if failed_tests > 0:
		quit(1)
	else:
		quit(0)

func test_source_integrity() -> void:
	print("\n--- 1. Source Integrity Tests ---")
	var fbx_path = "res://tests/wukong_asset_audit/source/dasheng.fbx"
	assert_test(FileAccess.file_exists(fbx_path), "dasheng.fbx exists in source dir")
	
	var fbm_dir = "res://tests/wukong_asset_audit/source/dasheng.fbm/"
	assert_test(DirAccess.dir_exists_absolute(fbm_dir), "dasheng.fbm texture directory exists")
	
	var dir = DirAccess.open(fbm_dir)
	var texture_count = 0
	if dir:
		dir.list_dir_begin()
		var fn = dir.get_next()
		while fn != "":
			if fn.ends_with(".png") and not fn.ends_with(".import"):
				texture_count += 1
			fn = dir.get_next()
	assert_test(texture_count >= 40, "Required texture files exist in fbm (found %d)" % texture_count)

func test_import_and_geometry() -> void:
	print("\n--- 2. Import & Geometry Tests ---")
	var fbx_path = "res://tests/wukong_asset_audit/source/dasheng.fbx"
	var scene_res = load(fbx_path)
	assert_test(scene_res is PackedScene, "FBX loads successfully as PackedScene")
	
	var inst: Node = scene_res.instantiate()
	assert_test(inst != null, "FBX PackedScene instantiates cleanly")
	
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
	
	assert_test(mi_count >= 2, "MeshInstance3D nodes present (found %d)" % mi_count)
	assert_test(total_verts > 700000, "High-detail geometry vertex count verified (%d vertices)" % total_verts)
	assert_test(total_tris > 900000, "High-detail geometry triangle count verified (%d triangles)" % total_tris)
	inst.queue_free()

func test_skeleton() -> void:
	print("\n--- 3. Skeleton Tests ---")
	var fbx_path = "res://tests/wukong_asset_audit/source/dasheng.fbx"
	var inst = load(fbx_path).instantiate()
	
	var sk: Skeleton3D = null
	var stack = [inst]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is Skeleton3D:
			sk = n
			break
		for c in n.get_children():
			stack.append(c)
	
	assert_test(sk != null, "Skeleton3D node found in imported FBX")
	if sk:
		var bone_count = sk.get_bone_count()
		assert_test(bone_count == 466, "Bone count matches expected rig (found %d bones)" % bone_count)
		assert_test(sk.find_bone("root") != -1, "Root bone 'root' exists")
		assert_test(sk.find_bone("pelvis") != -1, "Pelvis bone 'pelvis' exists")
		assert_test(sk.find_bone("head") != -1, "Head bone 'head' exists")
		assert_test(sk.find_bone("hand_r") != -1, "Right hand bone 'hand_r' exists")
	inst.queue_free()

func test_animation_audit() -> void:
	print("\n--- 4. Animation Audit Tests ---")
	var fbx_path = "res://tests/wukong_asset_audit/source/dasheng.fbx"
	var inst = load(fbx_path).instantiate()
	var raw_ap = inst.find_child("AnimationPlayer", true, false)
	assert_test(raw_ap == null or raw_ap.get_animation_list().size() == 0, "Source FBX verified to contain 0 embedded animation takes (bind-pose skeletal mesh)")
	inst.queue_free()
	
	var audit_scene_path = "res://tests/wukong_asset_audit/Wukong3DAudit.tscn"
	assert_test(ResourceLoader.exists(audit_scene_path), "Wukong3DAudit.tscn exists")
	var audit_scene = load(audit_scene_path).instantiate()
	assert_test(audit_scene != null, "Wukong3DAudit.tscn instantiates cleanly")
	
	# Verify UI controls exist
	assert_test(audit_scene.find_child("PrevBtn", true, false) != null, "UI PrevBtn exists")
	assert_test(audit_scene.find_child("NextBtn", true, false) != null, "UI NextBtn exists")
	assert_test(audit_scene.find_child("PlayBtn", true, false) != null, "UI PlayBtn exists")
	assert_test(audit_scene.find_child("RestartBtn", true, false) != null, "UI RestartBtn exists")
	assert_test(audit_scene.find_child("AnimName", true, false) != null, "UI AnimName label exists")
	assert_test(audit_scene.find_child("FPSLabel", true, false) != null, "UI FPSLabel exists")
	audit_scene.queue_free()

func test_rendering_and_png_integrity() -> void:
	print("\n--- 5. Rendering & PNG Frame Integrity Tests ---")
	for res in [512, 768, 1024]:
		var dir_path = "res://tests/wukong_asset_audit/generated/%d/idle/" % res
		assert_test(DirAccess.dir_exists_absolute(dir_path), "Render output directory for %dx%d exists" % [res, res])
		
		var sample_file = dir_path + "0000.png"
		assert_test(FileAccess.file_exists(sample_file), "%dx%d frame 0000.png exists" % [res, res])
		
		var img = Image.load_from_file(sample_file)
		assert_test(img != null, "%dx%d PNG is not corrupt and loads cleanly" % [res, res])
		if img:
			assert_test(img.get_width() == res and img.get_height() == res, "%dx%d dimensions match target" % [res, res])
			var corner = img.get_pixel(0, 0)
			assert_test(corner.a < 0.001, "%dx%d background alpha is 0.0 (transparent)" % [res, res])
			assert_test(img.detect_alpha() != Image.ALPHA_NONE, "%dx%d character contains valid alpha channels" % [res, res])

func test_2d_pipeline() -> void:
	print("\n--- 6. 2D Pipeline & Preview Tests ---")
	var sf_path = "res://tests/wukong_asset_audit/preview/wukong_512_spriteframes.tres"
	assert_test(ResourceLoader.exists(sf_path), "wukong_512_spriteframes.tres resource exists")
	
	var sf: SpriteFrames = load(sf_path)
	assert_test(sf != null, "SpriteFrames loads successfully")
	if sf:
		assert_test(sf.has_animation("idle"), "SpriteFrames contains 'idle' animation")
		assert_test(sf.has_animation("walk"), "SpriteFrames contains 'walk' animation")
		assert_test(sf.has_animation("run"), "SpriteFrames contains 'run' animation")
		assert_test(sf.get_frame_count("idle") == 16, "Idle animation contains 16 frames")
		assert_test(sf.get_frame_count("walk") == 16, "Walk animation contains 16 frames")
		assert_test(sf.get_frame_count("run") == 16, "Run animation contains 16 frames")
	
	var preview_scene_path = "res://tests/wukong_asset_audit/preview/Wukong2DPreview.tscn"
	assert_test(ResourceLoader.exists(preview_scene_path), "Wukong2DPreview.tscn exists")
	var preview_scene = load(preview_scene_path).instantiate()
	assert_test(preview_scene != null, "Wukong2DPreview.tscn instantiates cleanly")
	
	var anim_sprite: AnimatedSprite2D = preview_scene.find_child("AnimatedSprite2D", true, false)
	assert_test(anim_sprite != null, "Wukong2DPreview contains AnimatedSprite2D")
	if anim_sprite:
		assert_test(anim_sprite.sprite_frames != null, "AnimatedSprite2D has valid SpriteFrames bound")
		assert_test(anim_sprite.animation == "idle", "AnimatedSprite2D default animation is 'idle'")
	preview_scene.queue_free()
