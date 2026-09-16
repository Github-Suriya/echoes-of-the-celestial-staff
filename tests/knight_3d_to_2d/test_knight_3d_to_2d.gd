class_name TestKnight3DTo2D
extends Node

## Comprehensive Automated Test Suite for Phase 13: Knight 3D -> 2D Sprite Proof of Concept.
## Validates 3D source asset, animation tracks, rendered PNG frames (dimensions, alpha, counts),
## generated SpriteFrames, spritesheet atlases, AnimatedSprite2D preview, and comparison scenes.

const Knight3DTo2DTestScript = preload("res://tests/knight_3d_to_2d/Knight3DTo2DTest.gd")
const KnightComparisonScript = preload("res://tests/knight_3d_to_2d/preview/KnightComparison.gd")

var passed_count: int = 0
var failed_count: int = 0


func _ready() -> void:
	print("\n==================================================")
	print("STARTING PHASE 13: KNIGHT 3D -> 2D AUTOMATED TESTS")
	print("==================================================\n")
	
	_run_all_tests()
	
	print("\n==================================================")
	print("PHASE 13 TEST RESULTS")
	print("PASSED: %d" % passed_count)
	print("FAILED: %d" % failed_count)
	print("==================================================\n")
	
	if failed_count > 0:
		print("[FAIL] Phase 13 Knight 3D -> 2D test suite encountered failures!")
		get_tree().quit(1)
	else:
		print("[PASS] All Phase 13 Knight 3D -> 2D tests passed successfully!")
		get_tree().quit(0)


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		passed_count += 1
		print("[PASS] %s" % message)
	else:
		failed_count += 1
		printerr("[FAIL] %s" % message)


func _run_all_tests() -> void:
	_test_category_1_source_asset()
	_test_category_2_animation_durations()
	_test_category_3_rendered_directories_and_counts()
	_test_category_4_png_dimensions_and_alpha()
	_test_category_5_spriteframes_resource()
	_test_category_6_spritesheet_atlases()
	_test_category_7_preview_scenes()
	_test_category_8_controller_interactivity()


func _test_category_1_source_asset() -> void:
	print("--- Category 1: Source 3D Knight Asset ---")
	var fbx_path := "res://assets/characters/knight_test/KnightCharacter.fbx"
	_assert_true(FileAccess.file_exists(fbx_path), "KnightCharacter.fbx exists")
	
	var packed: PackedScene = load(fbx_path) as PackedScene
	_assert_true(packed != null, "Source Knight scene loads as PackedScene")
	
	var inst: Node = packed.instantiate()
	_assert_true(inst is Node3D, "Knight instance is Node3D")
	
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_assert_true(ap != null, "AnimationPlayer exists on Knight")
	
	if ap:
		_assert_true(ap.has_animation("HumanArmature|Idle"), "Idle animation exists (HumanArmature|Idle)")
		_assert_true(ap.has_animation("HumanArmature|Walking"), "Walking animation exists (HumanArmature|Walking)")
		_assert_true(ap.has_animation("HumanArmature|Run"), "Run animation exists (HumanArmature|Run)")
	
	inst.free()


func _test_category_2_animation_durations() -> void:
	print("--- Category 2: Animation Durations & Frame Calculations ---")
	var fbx_path := "res://assets/characters/knight_test/KnightCharacter.fbx"
	var packed: PackedScene = load(fbx_path) as PackedScene
	var inst: Node = packed.instantiate()
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	
	if ap:
		var idle_anim: Animation = ap.get_animation("HumanArmature|Idle")
		var walk_anim: Animation = ap.get_animation("HumanArmature|Walking")
		var run_anim: Animation = ap.get_animation("HumanArmature|Run")
		
		_assert_true(idle_anim != null and idle_anim.length > 3.0, "Idle duration detected (>3.0s, actual %.3fs)" % idle_anim.length)
		_assert_true(walk_anim != null and walk_anim.length > 1.0, "Walking duration detected (>1.0s, actual %.3fs)" % walk_anim.length)
		_assert_true(run_anim != null and run_anim.length > 0.8, "Run duration detected (>0.8s, actual %.3fs)" % run_anim.length)
		
		var idle_expected_frames: int = roundi(idle_anim.length * 30.0)
		var walk_expected_frames: int = roundi(walk_anim.length * 30.0)
		var run_expected_frames: int = roundi(run_anim.length * 30.0)
		
		_assert_true(idle_expected_frames == 100, "Idle expected frame count is 100 (Found: %d)" % idle_expected_frames)
		_assert_true(walk_expected_frames == 38, "Walking expected frame count is 38 (Found: %d)" % walk_expected_frames)
		_assert_true(run_expected_frames == 25, "Run expected frame count is 25 (Found: %d)" % run_expected_frames)
	
	inst.free()


func _test_category_3_rendered_directories_and_counts() -> void:
	print("--- Category 3: Rendered Directories & Frame Counts ---")
	var idle_dir := "res://tests/knight_3d_to_2d/sprites/idle/"
	var walk_dir := "res://tests/knight_3d_to_2d/sprites/walking/"
	var run_dir := "res://tests/knight_3d_to_2d/sprites/run/"
	
	_assert_true(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(idle_dir)), "Render output directory exists: sprites/idle/")
	_assert_true(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(walk_dir)), "Render output directory exists: sprites/walking/")
	_assert_true(DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(run_dir)), "Render output directory exists: sprites/run/")
	
	var idle_count: int = _count_png_files(idle_dir)
	var walk_count: int = _count_png_files(walk_dir)
	var run_count: int = _count_png_files(run_dir)
	
	_assert_true(idle_count == 100, "Idle frames exist and match count (100 / 100, Found: %d)" % idle_count)
	_assert_true(walk_count == 38, "Walking frames exist and match count (38 / 38, Found: %d)" % walk_count)
	_assert_true(run_count == 25, "Run frames exist and match count (25 / 25, Found: %d)" % run_count)


func _test_category_4_png_dimensions_and_alpha() -> void:
	print("--- Category 4: PNG Dimensions & Transparency ---")
	var sample_paths: Array[String] = [
		"res://tests/knight_3d_to_2d/sprites/idle/0000.png",
		"res://tests/knight_3d_to_2d/sprites/idle/0050.png",
		"res://tests/knight_3d_to_2d/sprites/walking/0000.png",
		"res://tests/knight_3d_to_2d/sprites/walking/0020.png",
		"res://tests/knight_3d_to_2d/sprites/run/0000.png",
		"res://tests/knight_3d_to_2d/sprites/run/0012.png"
	]
	
	for path in sample_paths:
		_assert_true(FileAccess.file_exists(path), "Sample frame exists: %s" % path)
		var img: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
		_assert_true(img != null, "Image loaded successfully: %s" % path)
		if img:
			_assert_true(img.get_width() == 512 and img.get_height() == 512, "PNG dimensions are strictly 512×512 (%s)" % path)
			
			# Check transparency: corner pixel must be transparent, character pixel must be opaque
			var corner_pixel: Color = img.get_pixel(10, 10)
			_assert_true(corner_pixel.a < 0.05, "Background is transparent (alpha = %.2f at (10,10))" % corner_pixel.a)
			
			var has_opaque := false
			for y in range(100, 400, 20):
				for x in range(200, 320, 20):
					if img.get_pixel(x, y).a > 0.8:
						has_opaque = true
						break
				if has_opaque:
					break
			_assert_true(has_opaque, "Character has solid opaque pixels in foreground (%s)" % path)


func _test_category_5_spriteframes_resource() -> void:
	print("--- Category 5: SpriteFrames Resource ---")
	var sf_path := "res://tests/knight_3d_to_2d/generated/knight_spriteframes.tres"
	_assert_true(FileAccess.file_exists(sf_path), "knight_spriteframes.tres file exists")
	_assert_true(ResourceLoader.exists(sf_path), "knight_spriteframes.tres recognized by ResourceLoader")
	
	var sf: SpriteFrames = load(sf_path) as SpriteFrames
	_assert_true(sf != null, "SpriteFrames resource loads successfully")
	
	if sf:
		_assert_true(sf.has_animation("idle"), "idle animation exists in SpriteFrames")
		_assert_true(sf.has_animation("walking"), "walking animation exists in SpriteFrames")
		_assert_true(sf.has_animation("run"), "run animation exists in SpriteFrames")
		
		_assert_true(sf.get_frame_count("idle") == 100, "idle has 100 frames in SpriteFrames (Found: %d)" % sf.get_frame_count("idle"))
		_assert_true(sf.get_frame_count("walking") == 38, "walking has 38 frames in SpriteFrames (Found: %d)" % sf.get_frame_count("walking"))
		_assert_true(sf.get_frame_count("run") == 25, "run has 25 frames in SpriteFrames (Found: %d)" % sf.get_frame_count("run"))
		
		_assert_true(sf.get_animation_loop("idle") == true, "idle loop is enabled")
		_assert_true(sf.get_animation_loop("walking") == true, "walking loop is enabled")
		_assert_true(sf.get_animation_loop("run") == true, "run loop is enabled")
		
		_assert_true(is_equal_approx(sf.get_animation_speed("idle"), 30.0), "idle animation speed is 30 FPS")
		_assert_true(is_equal_approx(sf.get_animation_speed("walking"), 30.0), "walking animation speed is 30 FPS")
		_assert_true(is_equal_approx(sf.get_animation_speed("run"), 30.0), "run animation speed is 30 FPS")


func _test_category_6_spritesheet_atlases() -> void:
	print("--- Category 6: Spritesheet Atlases ---")
	var sheet_idle := "res://tests/knight_3d_to_2d/generated/spritesheets/knight_idle.png"
	var sheet_walk := "res://tests/knight_3d_to_2d/generated/spritesheets/knight_walking.png"
	var sheet_run := "res://tests/knight_3d_to_2d/generated/spritesheets/knight_run.png"
	
	_assert_true(FileAccess.file_exists(sheet_idle), "Idle spritesheet exists")
	_assert_true(FileAccess.file_exists(sheet_walk), "Walking spritesheet exists")
	_assert_true(FileAccess.file_exists(sheet_run), "Run spritesheet exists")
	
	var img_idle: Image = Image.load_from_file(ProjectSettings.globalize_path(sheet_idle))
	_assert_true(img_idle != null and img_idle.get_width() == 2560 and img_idle.get_height() == 2560, "Idle spritesheet dimensions are 2560x2560 (10x10 tiles)")
	
	var img_walk: Image = Image.load_from_file(ProjectSettings.globalize_path(sheet_walk))
	_assert_true(img_walk != null and img_walk.get_width() == 2048 and img_walk.get_height() == 1280, "Walking spritesheet dimensions are 2048x1280 (8x5 tiles)")
	
	var img_run: Image = Image.load_from_file(ProjectSettings.globalize_path(sheet_run))
	_assert_true(img_run != null and img_run.get_width() == 1280 and img_run.get_height() == 1280, "Run spritesheet dimensions are 1280x1280 (5x5 tiles)")


func _test_category_7_preview_scenes() -> void:
	print("--- Category 7: Preview & Comparison Scenes ---")
	var test_scene_path := "res://tests/knight_3d_to_2d/Knight3DTo2DTest.tscn"
	_assert_true(ResourceLoader.exists(test_scene_path), "Knight3DTo2DTest.tscn exists and is loadable")
	
	var packed: PackedScene = load(test_scene_path) as PackedScene
	_assert_true(packed != null, "Knight3DTo2DTest.tscn loaded as PackedScene")
	
	var inst: Node = packed.instantiate()
	_assert_true(inst.get_script() == Knight3DTo2DTestScript, "Knight3DTo2DTest root script matches")
	
	var anim_sprite: AnimatedSprite2D = inst.find_child("AnimatedSprite2D", true, false) as AnimatedSprite2D
	_assert_true(anim_sprite != null, "AnimatedSprite2D exists in preview scene")
	if anim_sprite:
		_assert_true(anim_sprite.sprite_frames != null, "AnimatedSprite2D has SpriteFrames assigned")
	
	inst.free()
	
	var comp_scene_path := "res://tests/knight_3d_to_2d/preview/KnightComparison.tscn"
	_assert_true(ResourceLoader.exists(comp_scene_path), "KnightComparison.tscn exists and is loadable")
	
	var comp_packed: PackedScene = load(comp_scene_path) as PackedScene
	var comp_inst: Node = comp_packed.instantiate()
	_assert_true(comp_inst.get_script() == KnightComparisonScript, "KnightComparison root script matches")
	comp_inst.free()


func _test_category_8_controller_interactivity() -> void:
	print("--- Category 8: Controller Interactivity ---")
	var test_scene_path := "res://tests/knight_3d_to_2d/Knight3DTo2DTest.tscn"
	var packed: PackedScene = load(test_scene_path) as PackedScene
	var inst: Node2D = packed.instantiate() as Node2D
	add_child(inst)
	
	var ctrl = inst
	_assert_true(ctrl.get_current_animation_name() == &"idle", "Initial preview animation is 'idle'")
	_assert_true(ctrl.get_total_frames(&"idle") == 100, "Idle total frames is 100")
	
	# Switch to walking
	ctrl._play_animation_by_index(1)
	_assert_true(ctrl.get_current_animation_name() == &"walking", "Switched to 'walking' animation")
	_assert_true(ctrl.get_total_frames(&"walking") == 38, "Walking total frames is 38")
	
	# Switch to run
	ctrl._play_animation_by_index(2)
	_assert_true(ctrl.get_current_animation_name() == &"run", "Switched to 'run' animation")
	_assert_true(ctrl.get_total_frames(&"run") == 25, "Run total frames is 25")
	
	# Pause / Resume / Restart
	ctrl._toggle_pause()
	_assert_true(ctrl.is_paused, "Paused successfully")
	ctrl._toggle_pause()
	_assert_true(not ctrl.is_paused, "Resumed successfully")
	ctrl._restart_animation()
	_assert_true(ctrl.get_current_frame() == 0, "Restart reset frame to 0")
	
	inst.queue_free()


func _count_png_files(dir_path: String) -> int:
	var count := 0
	var dir := DirAccess.open(dir_path)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".png") and not file_name.ends_with(".import"):
				count += 1
			file_name = dir.get_next()
		dir.list_dir_end()
	return count
