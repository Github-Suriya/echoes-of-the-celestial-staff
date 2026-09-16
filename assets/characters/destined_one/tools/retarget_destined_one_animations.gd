@tool
extends SceneTree

const SOURCE_PATH := "res://assets/characters/knight_test/KnightCharacter.fbx"
const DESTINED_PATH := "res://assets/characters/destined_one/source/Destined One - Born.fbx"
const WEAPON_PATH := "res://assets/characters/destined_one/source/weapon/Destined One - Born - Weapon.fbx"

const ANIM_BASE_DIR := "res://assets/characters/destined_one/animations/"

# Animation definitions:
# name, source_anim_name, start_time, end_time (or -1 for full), loop_mode, category, reverse
const ANIM_DEFS: Array[Dictionary] = [
	{
		"name": "destined_idle",
		"source": "HumanArmature|Idle",
		"start": 0.0,
		"end": -1.0,
		"loop": Animation.LOOP_LINEAR,
		"category": "movement"
	},
	{
		"name": "destined_combat_idle",
		"source": "HumanArmature|Idle_swordRight",
		"start": 0.0,
		"end": -1.0,
		"loop": Animation.LOOP_LINEAR,
		"category": "movement"
	},
	{
		"name": "destined_walk",
		"source": "HumanArmature|Walking",
		"start": 0.0,
		"end": -1.0,
		"loop": Animation.LOOP_LINEAR,
		"category": "movement"
	},
	{
		"name": "destined_run",
		"source": "HumanArmature|Run",
		"start": 0.0,
		"end": -1.0,
		"loop": Animation.LOOP_LINEAR,
		"category": "movement"
	},
	{
		"name": "destined_jump",
		"source": "HumanArmature|Jump",
		"start": 0.0,
		"end": 0.45,
		"loop": Animation.LOOP_NONE,
		"category": "movement"
	},
	{
		"name": "destined_fall",
		"source": "HumanArmature|Jump",
		"start": 0.45,
		"end": 0.90,
		"loop": Animation.LOOP_LINEAR,
		"category": "movement"
	},
	{
		"name": "destined_land",
		"source": "HumanArmature|Jump",
		"start": 0.90,
		"end": 1.208,
		"loop": Animation.LOOP_NONE,
		"category": "movement"
	},
	{
		"name": "destined_dodge",
		"source": "HumanArmature|Roll_sword",
		"start": 0.0,
		"end": 0.85,
		"loop": Animation.LOOP_NONE,
		"category": "dodge"
	},
	{
		"name": "destined_dodge_recovery",
		"source": "HumanArmature|Roll_sword",
		"start": 0.85,
		"end": 1.25,
		"loop": Animation.LOOP_NONE,
		"category": "dodge"
	},
	{
		"name": "destined_light_01",
		"source": "HumanArmature|Run_swordAttack",
		"start": 0.0,
		"end": 0.833,
		"loop": Animation.LOOP_NONE,
		"category": "combat"
	},
	{
		"name": "destined_light_02",
		"source": "HumanArmature|swordAttackJump",
		"start": 0.0,
		"end": 0.60,
		"loop": Animation.LOOP_NONE,
		"category": "combat"
	},
	{
		"name": "destined_light_03",
		"source": "HumanArmature|swordAttackJump",
		"start": 0.55,
		"end": 1.167,
		"loop": Animation.LOOP_NONE,
		"category": "combat"
	},
	{
		"name": "destined_heavy",
		"source": "HumanArmature|swordAttackJump",
		"start": 0.0,
		"end": 1.167,
		"loop": Animation.LOOP_NONE,
		"category": "combat"
	},
	{
		"name": "destined_heavy_charge",
		"source": "HumanArmature|swordAttackJump",
		"start": 0.0,
		"end": 0.35,
		"loop": Animation.LOOP_LINEAR,
		"category": "combat"
	},
	{
		"name": "destined_hurt",
		"source": "HumanArmature|Death",
		"start": 0.0,
		"end": 0.25,
		"loop": Animation.LOOP_NONE,
		"category": "damage"
	},
	{
		"name": "destined_stagger",
		"source": "HumanArmature|Death",
		"start": 0.0,
		"end": 0.50,
		"loop": Animation.LOOP_NONE,
		"category": "damage"
	},
	{
		"name": "destined_knockdown",
		"source": "HumanArmature|Death",
		"start": 0.0,
		"end": 1.417,
		"loop": Animation.LOOP_NONE,
		"category": "damage"
	},
	{
		"name": "destined_getup",
		"source": "HumanArmature|Death",
		"start": 0.60,
		"end": 0.0,
		"loop": Animation.LOOP_NONE,
		"category": "damage",
		"reverse": true
	}
]

func _init() -> void:
	print("==================================================")
	print("STARTING DESTINED ONE ANIMATION RETARGETING")
	print("==================================================")
	
	var knight_res = load(SOURCE_PATH)
	if not knight_res:
		printerr("Failed to load source FBX: ", SOURCE_PATH)
		quit(1)
		return
	var knight_inst = knight_res.instantiate()
	var knight_sk: Skeleton3D = knight_inst.find_child("Skeleton3D", true, false)
	var knight_ap: AnimationPlayer = knight_inst.find_child("AnimationPlayer", true, false)
	
	var destined_res = load(DESTINED_PATH)
	if not destined_res:
		printerr("Failed to load Destined One FBX: ", DESTINED_PATH)
		quit(1)
		return
	var destined_inst = destined_res.instantiate()
	var destined_sk: Skeleton3D = destined_inst.find_child("Skeleton3D", true, false)
	
	var weapon_res = load(WEAPON_PATH)
	var weapon_inst = weapon_res.instantiate()
	var weapon_sk: Skeleton3D = weapon_inst.find_child("Skeleton3D", true, false)
	
	# Humanoid bone mapping dictionary from source Knight bone names to Destined One bone names
	var bone_map: Dictionary = {
		"Body": "root",
		"Hips": "pelvis",
		"Abdomen": "spine_01",
		"Torso": "spine_02",
		"Neck": "neck_01",
		"Head": "head",
		"Shoulder.L": "clavicle_l",
		"UpperArm.L": "upperarm_l",
		"LowerArm.L": "lowerarm_l",
		"Palm.L": "hand_l",
		"Shoulder.R": "clavicle_r",
		"UpperArm.R": "upperarm_r",
		"LowerArm.R": "lowerarm_r",
		"Palm.R": "hand_r",
		"UpperLeg.L": "thigh_l",
		"LowerLeg.L": "calf_l",
		"Foot.L": "foot_l",
		"UpperLeg.R": "thigh_r",
		"LowerLeg.R": "calf_r",
		"Foot.R": "foot_r",
		"Thumb.L": "thumb_01_l",
		"Thumb2.L": "thumb_02_l",
		"Thumb.R": "thumb_01_r",
		"Thumb2.R": "thumb_02_r",
		"MiddleHand.L": "index_01_l",
		"Fingers.L": "index_02_l",
		"MiddleHand.R": "index_01_r",
		"Fingers.R": "index_02_r"
	}
	
	# Arm & torso bones present in Weapon skeleton for lockstep tracking
	var weapon_bones: Array[String] = [
		"pelvis", "spine_01", "spine_02", "spine_03",
		"clavicle_r", "upperarm_r", "lowerarm_r", "hand_r"
	]
	
	var main_lib = AnimationLibrary.new()
	var generated_count = 0
	
	for def in ANIM_DEFS:
		var anim_name: String = def["name"]
		var src_name: String = def["source"]
		var cat: String = def["category"]
		var loop_m: int = def["loop"]
		var is_rev: bool = def.get("reverse", false)
		
		var src_anim: Animation = knight_ap.get_animation(src_name)
		if not src_anim:
			printerr("Source animation not found: ", src_name)
			continue
			
		var t_start: float = def["start"]
		var t_end: float = def["end"] if def["end"] > 0 else src_anim.length
		var clip_len: float = abs(t_end - t_start)
		
		var target_anim = Animation.new()
		target_anim.length = clip_len
		target_anim.loop_mode = loop_m
		
		# Process tracks
		for t in range(src_anim.get_track_count()):
			var tpath_str = str(src_anim.track_get_path(t))
			var ttype = src_anim.track_get_type(t)
			
			var parts = tpath_str.split(":")
			if parts.size() < 2:
				continue
			var src_bone = parts[1]
			if not bone_map.has(src_bone):
				continue
				
			var dst_bone = bone_map[src_bone]
			var src_idx = knight_sk.find_bone(src_bone)
			var dst_idx = destined_sk.find_bone(dst_bone)
			if src_idx < 0 or dst_idx < 0:
				continue
				
			# ROOT MOTION POLICY:
			# Discard translation tracks to ensure PlayerController physics remains authoritative
			if ttype == Animation.TYPE_POSITION_3D:
				continue
			if ttype == Animation.TYPE_SCALE_3D:
				continue
			if ttype != Animation.TYPE_ROTATION_3D:
				continue
				
			var src_rest_q: Quaternion = knight_sk.get_bone_rest(src_idx).basis.get_rotation_quaternion().normalized()
			var dst_rest_q: Quaternion = destined_sk.get_bone_rest(dst_idx).basis.get_rotation_quaternion().normalized()
			
			# 1. Add track for character Skeleton3D
			var char_track = target_anim.add_track(Animation.TYPE_ROTATION_3D)
			target_anim.track_set_path(char_track, NodePath("Skeleton3D:" + dst_bone))
			target_anim.track_set_interpolation_type(char_track, src_anim.track_get_interpolation_type(t))
			
			var kcount = src_anim.track_get_key_count(t)
			var keys_added = 0
			for k in range(kcount):
				var ktime = src_anim.track_get_key_time(t, k)
				
				# Check if key is within clip range
				var min_t = min(t_start, t_end)
				var max_t = max(t_start, t_end)
				if ktime < min_t or ktime > max_t:
					continue
					
				var new_ktime: float
				if is_rev:
					new_ktime = t_start - ktime
				else:
					new_ktime = ktime - t_start
				new_ktime = clamp(new_ktime, 0.0, clip_len)
				
				var src_q: Quaternion = src_anim.track_get_key_value(t, k)
				src_q = src_q.normalized()
				
				# Relative delta rotation on source bone
				var delta_q = src_rest_q.inverse() * src_q
				# Apply delta to Destined One rest pose
				var target_q = (dst_rest_q * delta_q).normalized()
				
				var trans = src_anim.track_get_key_transition(t, k)
				target_anim.track_insert_key(char_track, new_ktime, target_q, trans)
				keys_added += 1
				
			# If no keys fell exactly at 0 or end, ensure boundaries
			if target_anim.track_get_key_count(char_track) == 0:
				# Insert rest pose default
				target_anim.track_insert_key(char_track, 0.0, dst_rest_q)
				target_anim.track_insert_key(char_track, clip_len, dst_rest_q)
					
		# Save individual animation resource
		var sub_path = ANIM_BASE_DIR + cat + "/" + anim_name + ".res"
		var err = ResourceSaver.save(target_anim, sub_path)
		if err == OK:
			print("Saved: %-25s | Category: %-8s | Len: %.2fs | Tracks: %d" % [
				anim_name, cat, clip_len, target_anim.get_track_count()
			])
			generated_count += 1
		else:
			printerr("Failed to save animation: ", sub_path, " err: ", err)
			
		# Add to library
		main_lib.add_animation(anim_name, target_anim)
		
	# Save complete library
	var lib_path = ANIM_BASE_DIR + "libraries/destined_one_animation_library.res"
	var err = ResourceSaver.save(main_lib, lib_path)
	if err == OK:
		print("\n[SUCCESS] Saved complete AnimationLibrary to: ", lib_path)
		print("Total retargeted animations: ", generated_count)
	else:
		printerr("Failed to save AnimationLibrary: ", lib_path, " err: ", err)
		
	knight_inst.queue_free()
	destined_inst.queue_free()
	weapon_inst.queue_free()
	quit(0)
