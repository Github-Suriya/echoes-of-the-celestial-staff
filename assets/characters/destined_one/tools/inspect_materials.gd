extends SceneTree

func _init() -> void:
	var fbx_path = "res://assets/characters/destined_one/source/Destined One - Born.fbx"
	var inst = load(fbx_path).instantiate()
	var stack = [inst]
	
	print("--- INSPECTING SURFACE MATERIALS ---")
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is MeshInstance3D and n.mesh:
			print("Mesh: ", n.name)
			for s in range(n.mesh.get_surface_count()):
				var mat = n.get_surface_override_material(s)
				if mat == null:
					mat = n.mesh.surface_get_material(s)
				if mat is StandardMaterial3D:
					var sm: StandardMaterial3D = mat
					var alb = sm.albedo_texture.resource_path if sm.albedo_texture else "None"
					var nrm = sm.normal_texture.resource_path if sm.normal_texture else "None"
					print("  Surface %d (%s): albedo=%s, normal=%s, cull_mode=%d, transparency=%d" % [s, sm.resource_name, alb, nrm, sm.cull_mode, sm.transparency])
				else:
					print("  Surface %d: mat=%s" % [s, str(mat)])
		for c in n.get_children():
			stack.append(c)
	inst.queue_free()
	quit(0)
