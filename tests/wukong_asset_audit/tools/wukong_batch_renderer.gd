@tool
extends SceneTree

const BASE_OUT_DIR := "res://tests/wukong_asset_audit/generated/"
const TARGET_FPS := 24.0

const ANIMATIONS: Dictionary = {
	"idle": {"duration": 1.6, "stride": 0.04},  # Audit breathing sway
	"walk": {"duration": 1.2, "stride": 0.08},  # Audit walk stride
	"run":  {"duration": 0.8, "stride": 0.12}   # Audit run stride
}

const RESOLUTIONS: Array[int] = [512, 768, 1024]

func _init() -> void:
	print("==================================================")
	print("STARTING WUKONG MULTI-RESOLUTION BATCH RENDERER")
	print("==================================================")
	
	var start_time_ms = Time.get_ticks_msec()
	
	for res in RESOLUTIONS:
		await _render_resolution(res)
	
	var total_duration_s = float(Time.get_ticks_msec() - start_time_ms) / 1000.0
	print("\n[BATCH COMPLETE] Total render pipeline duration: %.2fs" % total_duration_s)
	
	# Assemble SpriteFrames for 512 (primary 2D preview)
	_assemble_sprite_frames(512)
	
	quit(0)

func _render_resolution(res: int) -> void:
	print("\n--- RENDERING RESOLUTION: %dx%d ---" % [res, res])
	var root_node = Node3D.new()
	root.add_child(root_node)
	
	var vp = SubViewport.new()
	vp.size = Vector2i(res, res)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root_node.add_child(vp)
	
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0, 0, 0, 0)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.45, 0.47, 0.52, 1.0)
	env.ambient_light_energy = 1.0
	env_node.environment = env
	vp.add_child(env_node)
	
	var key_light = DirectionalLight3D.new()
	key_light.position = Vector3(3, 6, 5)
	key_light.rotation_degrees = Vector3(-35, 30, 0)
	key_light.light_energy = 1.3
	vp.add_child(key_light)
	
	var fill_light = DirectionalLight3D.new()
	fill_light.position = Vector3(-3, 4, 3)
	fill_light.rotation_degrees = Vector3(-20, -40, 0)
	fill_light.light_color = Color(0.7, 0.8, 0.95)
	fill_light.light_energy = 0.6
	vp.add_child(fill_light)
	
	var cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.current = true
	cam.size = 6.5
	cam.position = Vector3(0.0, 2.6, 10.0)
	vp.add_child(cam)
	
	var wukong = load("res://tests/wukong_asset_audit/source/dasheng.fbx").instantiate()
	wukong.scale = Vector3(0.01, 0.01, 0.01)
	vp.add_child(wukong)
	
	# Setup AnimationPlayer
	var ap = AnimationPlayer.new()
	wukong.add_child(ap)
	var lib = AnimationLibrary.new()
	
	for anim_name in ANIMATIONS.keys():
		var data = ANIMATIONS[anim_name]
		var anim = Animation.new()
		anim.length = data["duration"]
		anim.loop_mode = Animation.LOOP_LINEAR
		
		var track_idx = anim.add_track(Animation.TYPE_POSITION_3D)
		anim.track_set_path(track_idx, "SK_mgd_jsds/Skeleton3D:pelvis")
		var dur = data["duration"]
		var stride = data["stride"]
		anim.track_insert_key(track_idx, 0.0, Vector3(0, 0, 2.05))
		anim.track_insert_key(track_idx, dur * 0.25, Vector3(0, stride, 2.05 + stride))
		anim.track_insert_key(track_idx, dur * 0.5, Vector3(0, 0, 2.05))
		anim.track_insert_key(track_idx, dur * 0.75, Vector3(0, -stride, 2.05 + stride))
		anim.track_insert_key(track_idx, dur, Vector3(0, 0, 2.05))
		lib.add_animation(anim_name, anim)
	
	ap.add_animation_library("", lib)
	
	# Warm up
	for i in range(5):
		await process_frame
	
	# For 512, render all 3 animations. For 768 and 1024, render idle benchmark.
	var anim_list_to_render = ["idle", "walk", "run"] if res == 512 else ["idle"]
	var frame_count_per_anim = 16 if res == 512 else 8
	
	for anim_name in anim_list_to_render:
		var out_dir = BASE_OUT_DIR + str(res) + "/" + anim_name + "/"
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
		
		ap.play(anim_name)
		var dur = ANIMATIONS[anim_name]["duration"]
		
		for f in range(frame_count_per_anim):
			var t = (float(f) / float(frame_count_per_anim)) * dur
			ap.seek(t, true)
			
			await process_frame
			await process_frame
			
			var img = vp.get_texture().get_image()
			var fname = "%04d.png" % f
			var fpath = out_dir + fname
			img.save_png(fpath)
		
		print("  Rendered %d frames for '%s' to %s" % [frame_count_per_anim, anim_name, out_dir])
	
	root_node.free()

func _assemble_sprite_frames(res: int) -> void:
	print("\n--- Assembling SpriteFrames Resource (%d) ---" % res)
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	
	var base_dir = BASE_OUT_DIR + str(res) + "/"
	for anim_name in ["idle", "walk", "run"]:
		var anim_dir = base_dir + anim_name + "/"
		if not DirAccess.dir_exists_absolute(anim_dir):
			continue
		
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 12.0)
		sf.set_animation_loop(anim_name, true)
		
		var dir = DirAccess.open(anim_dir)
		if dir:
			dir.list_dir_begin()
			var fname = dir.get_next()
			var files = []
			while fname != "":
				if fname.ends_with(".png") and not fname.ends_with(".import"):
					files.append(fname)
				fname = dir.get_next()
			files.sort()
			
			for f in files:
				var img_path = anim_dir + f
				var tex = load(img_path)
				if not tex:
					var img = Image.load_from_file(img_path)
					if img: tex = ImageTexture.create_from_image(img)
				if tex:
					sf.add_frame(anim_name, tex)
			
			print("  Added %d frames to animation '%s'" % [files.size(), anim_name])
	
	var tres_path = "res://tests/wukong_asset_audit/preview/wukong_%d_spriteframes.tres" % res
	var err = ResourceSaver.save(sf, tres_path)
	if err == OK:
		print("[SUCCESS] Saved SpriteFrames to ", tres_path)
	else:
		printerr("[ERROR] Failed to save SpriteFrames: ", err)
