@tool
extends SceneTree

const BASE_OUT_DIR := "res://assets/characters/destined_one/generated/sprites/"
const RESOLUTIONS: Array[int] = [512, 768]

# Technical test poses per spec Section 15
const POSES: Dictionary = {
	"idle_test": {
		"frames": 4,
		"pelvis_y_offset": 0.0,
		"spine_rot_z": 0.0,
		"staff_rot_z": 0.0
	},
	"stance_test": {
		"frames": 4,
		"pelvis_y_offset": -0.05,
		"spine_rot_z": 0.03,
		"staff_rot_z": 0.05
	},
	"movement_test": {
		"frames": 4,
		"pelvis_y_offset": -0.02,
		"spine_rot_z": -0.04,
		"staff_rot_z": -0.08
	}
}

func _init() -> void:
	print("==================================================")
	print("STARTING DESTINED ONE 2D MULTI-RESOLUTION BAKING")
	print("==================================================")
	
	var start_ms = Time.get_ticks_msec()
	
	for r in RESOLUTIONS:
		await _render_resolution(r)
		
	var duration_s = float(Time.get_ticks_msec() - start_ms) / 1000.0
	print("\n[BAKING COMPLETE] Total render duration: %.2fs" % duration_s)
	
	# Assemble SpriteFrames resource for 512x512
	_assemble_sprite_frames(512)
	
	quit(0)

func _render_resolution(res: int) -> void:
	print("\n--- Rendering Resolution: %dx%d ---" % [res, res])
	
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var vp = SubViewport.new()
	vp.size = Vector2i(res, res)
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
	cam.size = 3.85
	cam.position = Vector3(-0.25, 1.25, 4.0)
	cam.rotation_degrees = Vector3(0, 0, 0)
	vp.add_child(cam)
	
	var char_res = load("res://assets/characters/destined_one/source/Destined One - Born.fbx")
	var char_inst: Node3D = char_res.instantiate()
	char_inst.rotation_degrees = Vector3(0, -20, 0)
	vp.add_child(char_inst)
	
	var w_res = load("res://assets/characters/destined_one/source/weapon/Destined One - Born - Weapon.fbx")
	var w_inst: Node3D = w_res.instantiate()
	w_inst.rotation_degrees = Vector3(0, -20, 0)
	vp.add_child(w_inst)
	
	# Apply production materials
	var mat_dir = "res://assets/characters/destined_one/materials/"
	var apply_mats = func(root_node_to_apply: Node):
		var stack = [root_node_to_apply]
		while stack.size() > 0:
			var n = stack.pop_back()
			if n is MeshInstance3D and n.mesh:
				for s in range(n.mesh.get_surface_count()):
					var orig_mat = n.mesh.surface_get_material(s)
					var mname = orig_mat.resource_name if orig_mat else ""
					if mname != "":
						var custom_path = mat_dir + mname + ".tres"
						if ResourceLoader.exists(custom_path):
							var loaded_mat = load(custom_path)
							n.set_surface_override_material(s, loaded_mat)
			for c in n.get_children():
				stack.append(c)
	
	apply_mats.call(char_inst)
	apply_mats.call(w_inst)
	
	var skel: Skeleton3D = char_inst.find_child("Skeleton3D", true, false)
	var pelvis_idx = skel.find_bone("pelvis") if skel else -1
	var spine_idx = skel.find_bone("spine_01") if skel else -1
	
	# Warm up
	for i in range(5):
		await process_frame
		
	for pose_name in POSES.keys():
		var pose_data = POSES[pose_name]
		var frame_count: int = pose_data["frames"]
		var out_dir = BASE_OUT_DIR + str(res) + "/" + pose_name + "/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
		
		for f in range(frame_count):
			var cycle_t = float(f) / float(frame_count)
			var sway = sin(cycle_t * TAU)
			
			if skel and pelvis_idx >= 0 and spine_idx >= 0:
				var p_rest = skel.get_bone_rest(pelvis_idx)
				var s_rest = skel.get_bone_rest(spine_idx)
				
				var y_offset = pose_data["pelvis_y_offset"] + sway * 0.01
				var z_rot = pose_data["spine_rot_z"] + sway * 0.015
				
				skel.set_bone_pose_position(pelvis_idx, p_rest.origin + Vector3(0, y_offset, 0))
				skel.set_bone_pose_rotation(spine_idx, s_rest.basis.rotated(Vector3(0, 0, 1), z_rot).get_rotation_quaternion())
			
			await process_frame
			await process_frame
			
			var img = vp.get_texture().get_image()
			var fname = "%04d.png" % f
			var fpath = out_dir + fname
			img.save_png(fpath)
			
		print("  Rendered %d frames for '%s' to %s" % [frame_count, pose_name, out_dir])
		
	root_node.queue_free()

func _assemble_sprite_frames(res: int) -> void:
	print("\n--- Assembling SpriteFrames Resource for %dx%d ---" % [res, res])
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
		
	var base_dir = BASE_OUT_DIR + str(res) + "/"
	
	for pose_name in POSES.keys():
		var frame_count: int = POSES[pose_name]["frames"]
		var anim_name = StringName(pose_name)
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 6.0)
		sf.set_animation_loop(anim_name, true)
		
		for f in range(frame_count):
			var rel_path = base_dir + pose_name + "/%04d.png" % f
			var tex = load(rel_path)
			if tex is Texture2D:
				sf.add_frame(anim_name, tex)
			else:
				# Fallback load image
				var img = Image.load_from_file(ProjectSettings.globalize_path(rel_path))
				if img:
					var itex = ImageTexture.create_from_image(img)
					sf.add_frame(anim_name, itex)
					
		print("  Added '%s' with %d frames to SpriteFrames" % [anim_name, sf.get_frame_count(anim_name)])
		
	# Also add standard game mapping aliases (idle -> idle_test, etc.)
	for alias_pair in [["idle", "idle_test"], ["run", "movement_test"], ["walk", "movement_test"], ["jump", "stance_test"], ["fall", "stance_test"]]:
		var target_anim = StringName(alias_pair[0])
		var src_anim = StringName(alias_pair[1])
		sf.add_animation(target_anim)
		sf.set_animation_speed(target_anim, 6.0)
		sf.set_animation_loop(target_anim, true)
		for f in range(sf.get_frame_count(src_anim)):
			sf.add_frame(target_anim, sf.get_frame_texture(src_anim, f))
		print("  Mapped standard alias '%s' -> '%s' (%d frames)" % [target_anim, src_anim, sf.get_frame_count(target_anim)])
	
	var sf_path = "res://assets/characters/destined_one/spriteframes/destined_one_%d_spriteframes.tres" % res
	var err = ResourceSaver.save(sf, sf_path)
	if err == OK:
		print("Saved SpriteFrames to: %s" % sf_path)
	else:
		printerr("Failed to save SpriteFrames: %d" % err)
