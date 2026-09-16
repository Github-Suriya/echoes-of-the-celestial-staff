@tool
extends SceneTree

func _init() -> void:
	print("--- ASSEMBLING WUKONG SPRITEFRAMES RESOURCE ---")
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	
	var base_dir = "res://tests/wukong_asset_audit/generated/512/"
	var anim_list = ["idle", "walk", "run"]
	var total_frames_loaded = 0
	
	for anim_name in anim_list:
		var anim_dir = base_dir + anim_name + "/"
		if not DirAccess.dir_exists_absolute(anim_dir):
			printerr("Missing directory: ", anim_dir)
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
				var img_res_path = anim_dir + f
				var tex = load(img_res_path) as Texture2D
				if tex:
					sf.add_frame(anim_name, tex)
					total_frames_loaded += 1
				else:
					printerr("Failed to load texture: ", img_res_path)
			
			print("  Added %d frames to '%s'" % [files.size(), anim_name])
	
	var out_path = "res://tests/wukong_asset_audit/preview/wukong_512_spriteframes.tres"
	var err = ResourceSaver.save(sf, out_path)
	if err == OK:
		print("[SUCCESS] Assembled SpriteFrames with %d total frames saved to %s" % [total_frames_loaded, out_path])
	else:
		printerr("[ERROR] Failed to save SpriteFrames: ", err)
	
	quit(0)
