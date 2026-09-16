extends SceneTree

func _init() -> void:
	var fbx_path = "res://assets/characters/destined_one/source/Destined One - Born.fbx"
	var inst = load(fbx_path).instantiate()
	var sk: Skeleton3D = inst.find_child("Skeleton3D", true, false)
	if sk:
		var head_idx = sk.find_bone("head")
		var nose_idx = sk.find_bone("noseUpJoint")
		var p_head = sk.get_bone_global_rest(head_idx).origin
		var p_nose = sk.get_bone_global_rest(nose_idx).origin if nose_idx >= 0 else Vector3.ZERO
		print("head: ", p_head)
		print("nose: ", p_nose)
		print("Nose offset from head: ", (p_nose - p_head))
	inst.queue_free()
	quit(0)
