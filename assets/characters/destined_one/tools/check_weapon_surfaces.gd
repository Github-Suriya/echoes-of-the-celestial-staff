extends SceneTree

func _init() -> void:
	var wpath = "res://assets/characters/destined_one/source/weapon/Destined One - Born - Weapon.fbx"
	var inst = load(wpath).instantiate()
	var mi: MeshInstance3D = inst.find_child("SK_Wukong_weapon_born_mo", true, false)
	if mi and mi.mesh:
		for s in range(mi.mesh.get_surface_count()):
			var mat = mi.mesh.surface_get_material(s)
			var arr = mi.mesh.surface_get_arrays(s)
			var v = arr[Mesh.ARRAY_VERTEX].size()
			print("Surface %d: name=%s, verts=%d" % [s, mat.resource_name if mat else "None", v])
	inst.queue_free()
	quit(0)
