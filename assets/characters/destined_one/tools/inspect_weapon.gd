extends SceneTree

func _init() -> void:
	var wpath = "res://assets/characters/destined_one/source/weapon/Destined One - Born - Weapon.fbx"
	var inst = load(wpath).instantiate()
	print("--- WEAPON INSPECTION ---")
	print("Root: ", inst.name)
	for c in inst.get_children():
		print("  Child: ", c.name, " (", c.get_class(), ")")
		if c is MeshInstance3D:
			print("    AABB: ", c.get_aabb())
		elif c is Skeleton3D:
			print("    Bone count: ", c.get_bone_count())
			for b in range(c.get_bone_count()):
				print("      Bone %d: %s (pos: %s)" % [b, c.get_bone_name(b), c.get_bone_global_rest(b).origin])
			for sc in c.get_children():
				if sc is MeshInstance3D:
					print("      Skeleton child mesh: ", sc.name, " AABB: ", sc.get_aabb())
	inst.queue_free()
	quit(0)
