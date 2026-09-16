extends SceneTree

const BASE_OUT_DIR := "res://assets/characters/destined_one/generated/sprites/512/"
const POSES: Array[String] = ["idle_test", "stance_test", "movement_test"]

func _init() -> void:
	print("==================================================")
	print("ASSEMBLING CLEAN DESTINED ONE SPRITEFRAMES")
	print("==================================================")
	
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
		
	for pose in POSES:
		var anim_name = StringName(pose)
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 6.0)
		sf.set_animation_loop(anim_name, true)
		
		for f in range(4):
			var tex_path = BASE_OUT_DIR + pose + "/%04d.png" % f
			var tex = load(tex_path)
			if tex is Texture2D:
				sf.add_frame(anim_name, tex)
				print("  [OK] Added %s frame %d from %s" % [anim_name, f, tex_path])
			else:
				printerr("  [FAIL] Could not load texture from: ", tex_path)
				
	# Standard gameplay state aliases
	var aliases = [
		["idle", "idle_test"],
		["run", "movement_test"],
		["walk", "movement_test"],
		["jump", "stance_test"],
		["fall", "stance_test"],
		["land", "stance_test"]
	]
	
	for a in aliases:
		var target_name = StringName(a[0])
		var src_name = StringName(a[1])
		sf.add_animation(target_name)
		sf.set_animation_speed(target_name, 6.0)
		sf.set_animation_loop(target_name, true)
		for f in range(sf.get_frame_count(src_name)):
			sf.add_frame(target_name, sf.get_frame_texture(src_name, f))
		print("  Mapped alias '%s' -> '%s' (%d frames)" % [target_name, src_name, sf.get_frame_count(target_name)])
		
	var save_path = "res://assets/characters/destined_one/spriteframes/destined_one_512_spriteframes.tres"
	var err = ResourceSaver.save(sf, save_path)
	if err == OK:
		print("Saved clean SpriteFrames to: ", save_path)
	else:
		printerr("Error saving SpriteFrames: ", err)
		quit(1)
		return
		
	quit(0)
