@tool
extends SceneTree

const BASE_OUT_DIR := "res://assets/characters/destined_one/generated/sprites/512_anims/"
const RESOLUTION := 512

const CANONICAL_CAM_SIZE: float = 6.0
const CANONICAL_CAM_POS: Vector3 = Vector3(-0.35, 0.35, 4.0)
const CANONICAL_CHAR_ROT: Vector3 = Vector3(0, -20, 0)

# Animations to bake into 2D sprite frames
const BAKE_ANIMS: Dictionary = {
	"idle": {
		"anim": "destined_idle",
		"frames": 4,
		"fps": 5.0
	},
	"run": {
		"anim": "destined_run",
		"frames": 6,
		"fps": 10.0
	},
	"light_01": {
		"anim": "destined_light_01",
		"frames": 4,
		"fps": 8.0
	},
	"heavy": {
		"anim": "destined_heavy",
		"frames": 4,
		"fps": 6.0
	},
	"dodge": {
		"anim": "destined_dodge",
		"frames": 4,
		"fps": 8.0
	}
}

func _init() -> void:
	print("==================================================")
	print("STARTING 512x512 2D ANIMATION FRAME RENDERING")
	print("==================================================")
	
	var start_ms = Time.get_ticks_msec()
	await _render_all_animations()
	var duration_s = float(Time.get_ticks_msec() - start_ms) / 1000.0
	print("\n[BAKING COMPLETE] Total render duration: %.2fs" % duration_s)
	
	_assemble_sprite_frames()
	quit(0)

func _render_all_animations() -> void:
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var vp = SubViewport.new()
	vp.size = Vector2i(RESOLUTION, RESOLUTION)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root_node.add_child(vp)
	
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.7, 0.72, 0.78, 1.0)
	env.ambient_light_energy = 0.85
	
	var we = WorldEnvironment.new()
	we.environment = env
	vp.add_child(we)
	
	var key_light = DirectionalLight3D.new()
	key_light.light_color = Color(1.0, 0.96, 0.90)
	key_light.light_energy = 1.4
	key_light.rotation_degrees = Vector3(-20, -35, 0)
	vp.add_child(key_light)
	
	var fill_light = DirectionalLight3D.new()
	fill_light.light_color = Color(0.85, 0.90, 1.0)
	fill_light.light_energy = 0.6
	fill_light.rotation_degrees = Vector3(15, 145, 0)
	vp.add_child(fill_light)
	
	var rim_light = DirectionalLight3D.new()
	rim_light.light_color = Color(1.0, 0.85, 0.6)
	rim_light.light_energy = 0.8
	rim_light.rotation_degrees = Vector3(-10, 170, 0)
	vp.add_child(rim_light)
	
	var cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.current = true
	cam.size = CANONICAL_CAM_SIZE
	cam.position = CANONICAL_CAM_POS
	vp.add_child(cam)
	
	var char_res = load("res://assets/characters/destined_one/source/Destined One - Born.fbx")
	var char_inst: Node3D = char_res.instantiate()
	char_inst.rotation_degrees = CANONICAL_CHAR_ROT
	vp.add_child(char_inst)
	
	var weapon_res = load("res://assets/characters/destined_one/source/weapon/Destined One - Born - Weapon.fbx")
	var weapon_inst: Node3D = weapon_res.instantiate()
	weapon_inst.name = "Weapon"
	char_inst.add_child(weapon_inst)
	
	var ap = AnimationPlayer.new()
	ap.name = "AnimationPlayer"
	char_inst.add_child(ap)
	
	var lib = load("res://assets/characters/destined_one/animations/libraries/destined_one_animation_library.res")
	ap.add_animation_library("", lib)
	
	_apply_materials(char_inst)
	_apply_materials(weapon_inst)
	
	var char_sk: Skeleton3D = char_inst.find_child("Skeleton3D", true, false)
	var weapon_sk: Skeleton3D = weapon_inst.find_child("Skeleton3D", true, false)
	var arm_bones = ["pelvis", "spine_01", "spine_02", "spine_03", "clavicle_r", "upperarm_r", "lowerarm_r", "hand_r"]
	
	var dir = DirAccess.open("res://")
	var abs_out_dir = ProjectSettings.globalize_path(BASE_OUT_DIR)
	dir.make_dir_recursive(abs_out_dir)
	
	for anim_key in BAKE_ANIMS:
		var config = BAKE_ANIMS[anim_key]
		var anim_name: String = config["anim"]
		var frame_count: int = config["frames"]
		
		if not ap.has_animation(anim_name):
			printerr("Animation not found: ", anim_name)
			continue
			
		var anim_res: Animation = ap.get_animation(anim_name)
		var total_len = anim_res.length
		var time_step = total_len / float(frame_count)
		
		print("\nRendering '%s' (%s) -> %d frames (len: %.2fs)" % [anim_key, anim_name, frame_count, total_len])
		
		ap.play(anim_name)
		
		for i in range(frame_count):
			var sample_t = i * time_step
			ap.seek(sample_t, true)
			
			for f in range(3):
				if char_sk and weapon_sk:
					var d_hand = char_sk.find_bone("hand_r")
					var w_hand = weapon_sk.find_bone("hand_r")
					if d_hand >= 0 and w_hand >= 0:
						var d_hand_global = char_sk.get_bone_global_pose(d_hand)
						weapon_sk.set_bone_global_pose_override(w_hand, d_hand_global, 1.0, true)
						weapon_sk.force_update_bone_child_transform(w_hand)
				await process_frame
				
			var tex = vp.get_texture()
			var img = tex.get_image()
			
			var frame_fname = "%s_%02d.png" % [anim_key, i]
			var frame_abs_path = abs_out_dir.path_join(frame_fname)
			var err = img.save_png(frame_abs_path)
			if err == OK:
				print("  Saved: %s (%dx%d, time: %.2fs)" % [frame_fname, img.get_width(), img.get_height(), sample_t])
			else:
				printerr("  Failed to save: ", frame_fname, " err: ", err)
				
	root_node.queue_free()

func _assemble_sprite_frames() -> void:
	print("\n--- Assembling 2D SpriteFrames Resource ---")
	var sf = SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
		
	var abs_out_dir = ProjectSettings.globalize_path(BASE_OUT_DIR)
	
	for anim_key in BAKE_ANIMS:
		var config = BAKE_ANIMS[anim_key]
		var frame_count: int = config["frames"]
		var fps: float = config["fps"]
		
		var s_anim = StringName(anim_key)
		sf.add_animation(s_anim)
		sf.set_animation_speed(s_anim, fps)
		sf.set_animation_loop(s_anim, anim_key == "idle" or anim_key == "run")
		
		for i in range(frame_count):
			var frame_fname = "%s_%02d.png" % [anim_key, i]
			var frame_abs_path = abs_out_dir.path_join(frame_fname)
			var img = Image.load_from_file(frame_abs_path)
			if img:
				var itex = ImageTexture.create_from_image(img)
				sf.add_frame(s_anim, itex)
			else:
				print("Warning: Missing image file: ", frame_abs_path)
				
		print("Added animation to SpriteFrames: %s (%d frames, %.1f FPS)" % [
			s_anim, sf.get_frame_count(s_anim), fps
		])
		
	# Add gameplay aliases matching PlayerAnimationController & AttackData
	var aliases = [
		["light_1", "light_01"],
		["light_2", "light_01"],
		["light_3", "light_01"],
		["heavy_1", "heavy"],
		["walk", "run"]
	]
	for pair in aliases:
		var target_anim = StringName(pair[0])
		var src_anim = StringName(pair[1])
		if sf.has_animation(src_anim):
			sf.add_animation(target_anim)
			sf.set_animation_speed(target_anim, sf.get_animation_speed(src_anim))
			sf.set_animation_loop(target_anim, sf.get_animation_loop(src_anim))
			for f in range(sf.get_frame_count(src_anim)):
				sf.add_frame(target_anim, sf.get_frame_texture(src_anim, f))
			print("Mapped gameplay alias '%s' -> '%s' (%d frames)" % [
				target_anim, src_anim, sf.get_frame_count(target_anim)
			])
		
	var out_path = "res://assets/characters/destined_one/spriteframes/destined_one_retarget_512_spriteframes.tres"
	var err = ResourceSaver.save(sf, out_path)
	if err == OK:
		print("Successfully saved SpriteFrames to: ", out_path)
	else:
		printerr("Failed to save SpriteFrames: ", err)

func _apply_materials(node: Node) -> void:
	var mat_dir = "res://assets/characters/destined_one/materials/"
	for child in node.get_children():
		if child is MeshInstance3D:
			for s in range(child.get_surface_override_material_count()):
				var orig = child.mesh.surface_get_material(s)
				if orig and orig.resource_name != "":
					var p = mat_dir + orig.resource_name + ".tres"
					if ResourceLoader.exists(p):
						child.set_surface_override_material(s, load(p))
		_apply_materials(child)
