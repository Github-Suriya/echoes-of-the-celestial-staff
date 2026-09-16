@tool
extends SceneTree

func _init() -> void:
	print("Building lightweight SpriteFrames with ExtResources...")
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")
	
	var anim_counts: Dictionary = {
		"idle": 100,
		"walking": 38,
		"run": 25
	}
	
	for anim_name in anim_counts.keys():
		sf.add_animation(anim_name)
		sf.set_animation_speed(anim_name, 30.0)
		sf.set_animation_loop(anim_name, true)
		
		var count: int = anim_counts[anim_name]
		for i in range(count):
			var path := "res://tests/knight_3d_to_2d/sprites/%s/%04d.png" % [anim_name, i]
			var tex = load(path)
			if tex:
				sf.add_frame(anim_name, tex)
			else:
				printerr("Failed to load: ", path)
		
		print("Added animation '%s' with %d frames" % [anim_name, sf.get_frame_count(anim_name)])
	
	var save_path := "res://tests/knight_3d_to_2d/generated/knight_spriteframes.tres"
	var err := ResourceSaver.save(sf, save_path)
	print("Saved SpriteFrames to: ", save_path, " Result: ", err)
	
	quit()
