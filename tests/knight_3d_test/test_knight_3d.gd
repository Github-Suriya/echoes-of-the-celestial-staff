class_name TestKnight3D
extends Node

## Automated test suite for Quaternius Knight 3D Direct Import.
## Verifies FBX scene import, mesh integrity, skeleton hierarchy,
## material bindings, animation playback, and test controller scene functionality.

const Knight3DTestScript = preload("res://tests/knight_3d_test/Knight3DTest.gd")

var passed_count: int = 0
var failed_count: int = 0


func _ready() -> void:
	print("\n==================================================")
	print("STARTING QUATERNIUS KNIGHT 3D DIRECT IMPORT TESTS")
	print("==================================================\n")
	
	_run_all_tests()
	
	print("\n==================================================")
	print("KNIGHT 3D IMPORT TEST RESULTS")
	print("PASSED: %d" % passed_count)
	print("FAILED: %d" % failed_count)
	print("==================================================\n")
	
	if failed_count > 0:
		print("[FAIL] Knight 3D Direct Import test suite failed!")
	else:
		print("[PASS] All Knight 3D Direct Import tests passed successfully!")


func _run_all_tests() -> void:
	_test_category_1_file_and_import()
	_test_category_2_mesh_and_materials()
	_test_category_3_skeleton()
	_test_category_4_animation_player()
	_test_category_5_scene_and_camera()
	_test_category_6_controller_controls()


func _assert_true(condition: bool, message: String) -> void:
	if condition:
		passed_count += 1
		print("[PASS] %s" % message)
	else:
		failed_count += 1
		printerr("[FAIL] %s" % message)


func _test_category_1_file_and_import() -> void:
	print("--- Category 1: Asset & Import Integrity ---")
	var fbx_path: String = "res://assets/characters/knight_test/KnightCharacter.fbx"
	var import_path: String = "res://assets/characters/knight_test/KnightCharacter.fbx.import"
	
	_assert_true(FileAccess.file_exists(fbx_path), "KnightCharacter.fbx exists at designated path")
	_assert_true(FileAccess.file_exists(import_path), "KnightCharacter.fbx.import exists")
	_assert_true(ResourceLoader.exists(fbx_path), "KnightCharacter.fbx is recognized by ResourceLoader")
	
	var scene_res = load(fbx_path)
	_assert_true(scene_res is PackedScene, "KnightCharacter.fbx successfully loaded as PackedScene")


func _test_category_2_mesh_and_materials() -> void:
	print("--- Category 2: Mesh & Materials ---")
	var fbx_path: String = "res://assets/characters/knight_test/KnightCharacter.fbx"
	var packed: PackedScene = load(fbx_path) as PackedScene
	var inst: Node = packed.instantiate()
	
	_assert_true(inst is Node3D, "KnightCharacter root is Node3D")
	
	var knight_mesh: MeshInstance3D = inst.find_child("Knight", true, false) as MeshInstance3D
	_assert_true(knight_mesh != null, "Found 'Knight' MeshInstance3D child node")
	
	if knight_mesh:
		var mesh: Mesh = knight_mesh.mesh
		_assert_true(mesh != null, "MeshInstance3D contains valid Mesh resource")
		if mesh:
			_assert_true(mesh is ArrayMesh, "Mesh is ArrayMesh")
			var surf_count: int = mesh.get_surface_count()
			_assert_true(surf_count >= 3, "Mesh has at least 3 surfaces (Found: %d)" % surf_count)
			
			var mat0 = mesh.surface_get_material(0)
			var mat1 = mesh.surface_get_material(1)
			var mat2 = mesh.surface_get_material(2)
			
			_assert_true(mat0 is Material, "Surface 0 has valid Material (Armor)")
			_assert_true(mat1 is Material, "Surface 1 has valid Material (Skin)")
			_assert_true(mat2 is Material, "Surface 2 has valid Material (Boots)")
			
			if mat0:
				print("  Surface 0 material name: '%s' (%s)" % [mat0.resource_name, mat0.get_class()])
			if mat1:
				print("  Surface 1 material name: '%s' (%s)" % [mat1.resource_name, mat1.get_class()])
			if mat2:
				print("  Surface 2 material name: '%s' (%s)" % [mat2.resource_name, mat2.get_class()])
	
	inst.free()


func _test_category_3_skeleton() -> void:
	print("--- Category 3: Skeleton Hierarchy ---")
	var fbx_path: String = "res://assets/characters/knight_test/KnightCharacter.fbx"
	var packed: PackedScene = load(fbx_path) as PackedScene
	var inst: Node = packed.instantiate()
	
	var skeleton: Skeleton3D = inst.find_child("Skeleton3D", true, false) as Skeleton3D
	_assert_true(skeleton != null, "Found Skeleton3D node in hierarchy")
	
	if skeleton:
		var bone_count: int = skeleton.get_bone_count()
		_assert_true(bone_count == 42, "Skeleton3D has 42 bones (Found: %d)" % bone_count)
		
		var has_root: bool = false
		var has_head: bool = false
		var has_hand: bool = false
		for i in range(bone_count):
			var bname: String = skeleton.get_bone_name(i).to_lower()
			if "root" in bname or "pelvis" in bname or "hips" in bname:
				has_root = true
			if "head" in bname:
				has_head = true
			if "hand" in bname:
				has_hand = true
		
		_assert_true(has_root, "Skeleton contains root/hip bone")
		_assert_true(has_head, "Skeleton contains head bone")
		_assert_true(has_hand, "Skeleton contains hand bone")
	
	inst.free()


func _test_category_4_animation_player() -> void:
	print("--- Category 4: AnimationPlayer & Tracks ---")
	var fbx_path: String = "res://assets/characters/knight_test/KnightCharacter.fbx"
	var packed: PackedScene = load(fbx_path) as PackedScene
	var inst: Node = packed.instantiate()
	
	var ap: AnimationPlayer = inst.find_child("AnimationPlayer", true, false) as AnimationPlayer
	_assert_true(ap != null, "Found AnimationPlayer node in hierarchy")
	
	if ap:
		var anims: PackedStringArray = ap.get_animation_list()
		_assert_true(anims.size() == 12, "AnimationPlayer has exactly 12 animations (Found: %d)" % anims.size())
		
		var expected_anims: Array[String] = [
			"HumanArmature|Death",
			"HumanArmature|Idle",
			"HumanArmature|Idle_swordLeft",
			"HumanArmature|Idle_swordRight",
			"HumanArmature|Jump",
			"HumanArmature|Roll",
			"HumanArmature|Roll_sword",
			"HumanArmature|Run",
			"HumanArmature|Run_swordAttack",
			"HumanArmature|Run_swordRight",
			"HumanArmature|Walking",
			"HumanArmature|swordAttackJump"
		]
		
		for expected in expected_anims:
			_assert_true(ap.has_animation(expected), "AnimationPlayer has track: %s" % expected)
		
		# Test playing each animation
		for anim_name in expected_anims:
			ap.play(anim_name)
			_assert_true(ap.current_animation == anim_name, "Successfully triggered playback: %s" % anim_name)
			var anim_res: Animation = ap.get_animation(anim_name)
			_assert_true(anim_res != null and anim_res.length > 0.0, "Track %s has non-zero duration (%.2fs)" % [anim_name, anim_res.length if anim_res else 0.0])
	
	inst.free()


func _test_category_5_scene_and_camera() -> void:
	print("--- Category 5: Isolated Test Scene Structure ---")
	var test_scene_path: String = "res://tests/knight_3d_test/Knight3DTest.tscn"
	_assert_true(ResourceLoader.exists(test_scene_path), "Knight3DTest.tscn exists and is loadable")
	
	var packed: PackedScene = load(test_scene_path) as PackedScene
	_assert_true(packed != null, "Knight3DTest.tscn loaded as PackedScene")
	
	var scene_root: Node = packed.instantiate()
	_assert_true(scene_root.get_script() == Knight3DTestScript, "Scene root script is Knight3DTest")
	
	var cam: Camera3D = scene_root.find_child("Camera3D", true, false) as Camera3D
	_assert_true(cam != null, "Camera3D node exists in scene")
	if cam:
		_assert_true(cam.fov >= 40.0 and cam.fov <= 80.0, "Camera3D FOV is in reasonable range (%.1f)" % cam.fov)
		_assert_true(cam.position.z > 1.5, "Camera3D positioned in front of character (z = %.2f)" % cam.position.z)
		_assert_true(cam.position.y >= 0.5, "Camera3D elevated at reasonable height (y = %.2f)" % cam.position.y)
	
	var light: DirectionalLight3D = scene_root.find_child("DirectionalLight3D", true, false) as DirectionalLight3D
	_assert_true(light != null, "DirectionalLight3D exists in scene")
	
	var ground: MeshInstance3D = scene_root.find_child("Ground", true, false) as MeshInstance3D
	_assert_true(ground != null, "Ground MeshInstance3D exists in scene")
	
	var knight_node: Node = scene_root.get_node_or_null("Knight")
	_assert_true(knight_node != null, "Knight instance attached under root as 'Knight'")
	
	scene_root.free()


func _test_category_6_controller_controls() -> void:
	print("--- Category 6: Controller & Dynamic Controls ---")
	var test_scene_path: String = "res://tests/knight_3d_test/Knight3DTest.tscn"
	var packed: PackedScene = load(test_scene_path) as PackedScene
	var scene: Node = packed.instantiate()
	
	# Add to tree so _ready runs
	add_child(scene)
	
	var discovered: Array[StringName] = scene.get_discovered_animations()
	_assert_true(discovered.size() == 12, "Controller discovered 12 animations dynamically")
	
	var cur_anim: StringName = scene.get_current_animation_name()
	_assert_true(cur_anim == &"HumanArmature|Idle", "Default initial animation is Idle (Found: %s)" % cur_anim)
	
	# Test Next animation
	scene._next_animation()
	_assert_true(scene.current_anim_index == 2, "Next animation moved to index 2")
	
	# Test Prev animation
	scene._prev_animation()
	_assert_true(scene.current_anim_index == 1, "Prev animation returned to index 1")
	
	# Test Direct selection
	scene._play_animation_by_index(0)
	_assert_true(scene.current_anim_index == 0, "Direct select 0 played Death animation")
	
	# Test Pause / Unpause
	scene._toggle_pause()
	_assert_true(scene.is_paused, "Pause toggled successfully")
	scene._toggle_pause()
	_assert_true(not scene.is_paused, "Unpause toggled successfully")
	
	# Test Restart
	scene._restart_animation()
	_assert_true(not scene.is_paused, "Restart resumed playback")
	
	scene.queue_free()
