extends SceneTree

func _init() -> void:
	var fbx_path = "res://assets/characters/destined_one/source/Destined One - Born.fbx"
	var inst = load(fbx_path).instantiate()
	var sk: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	if sk:
		var hand_l_idx = sk.find_bone("hand_l")
		var hand_r_idx = sk.find_bone("hand_r")
		var foot_l_idx = sk.find_bone("foot_l")
		var foot_r_idx = sk.find_bone("foot_r")
		var head_idx = sk.find_bone("head")
		
		var p_hl = sk.get_bone_global_rest(hand_l_idx).origin
		var p_hr = sk.get_bone_global_rest(hand_r_idx).origin
		var p_fl = sk.get_bone_global_rest(foot_l_idx).origin
		var p_fr = sk.get_bone_global_rest(foot_r_idx).origin
		var p_head = sk.get_bone_global_rest(head_idx).origin
		
		print("hand_l rest pos: ", p_hl)
		print("hand_r rest pos: ", p_hr)
		print("foot_l rest pos: ", p_fl)
		print("foot_r rest pos: ", p_fr)
		print("head rest pos:   ", p_head)
		
		# Look at which axis separates left and right limbs
		print("Vector from right to left hand: ", (p_hl - p_hr))
		print("Vector from right to left foot: ", (p_fl - p_fr))
	inst.queue_free()
	quit(0)
