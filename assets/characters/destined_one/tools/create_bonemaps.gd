@tool
extends SceneTree

func _init() -> void:
	print("--- CREATING HUMANOD BONEMAP RESOURCES ---")
	
	var profile = SkeletonProfileHumanoid.new()
	
	# 1. Create Destined One BoneMap
	var d_bmap = BoneMap.new()
	d_bmap.profile = profile
	
	var destined_mappings: Dictionary = {
		"Root": "root",
		"Hips": "pelvis",
		"Spine": "spine_01",
		"Chest": "spine_02",
		"UpperChest": "spine_03",
		"Neck": "neck_01",
		"Head": "head",
		"LeftShoulder": "clavicle_l",
		"LeftUpperArm": "upperarm_l",
		"LeftLowerArm": "lowerarm_l",
		"LeftHand": "hand_l",
		"RightShoulder": "clavicle_r",
		"RightUpperArm": "upperarm_r",
		"RightLowerArm": "lowerarm_r",
		"RightHand": "hand_r",
		"LeftUpperLeg": "thigh_l",
		"LeftLowerLeg": "calf_l",
		"LeftFoot": "foot_l",
		"LeftToes": "ball_l_01",
		"RightUpperLeg": "thigh_r",
		"RightLowerLeg": "calf_r",
		"RightFoot": "foot_r",
		"RightToes": "ball_r_01",
		# Fingers
		"LeftThumbMetacarpal": "thumb_01_l",
		"LeftThumbProximal": "thumb_02_l",
		"LeftThumbDistal": "thumb_03_l",
		"LeftIndexProximal": "index_01_l",
		"LeftIndexIntermediate": "index_02_l",
		"LeftIndexDistal": "index_03_l",
		"LeftMiddleProximal": "middle_01_l",
		"LeftMiddleIntermediate": "middle_02_l",
		"LeftMiddleDistal": "middle_03_l",
		"LeftRingProximal": "ring_01_l",
		"LeftRingIntermediate": "ring_02_l",
		"LeftRingDistal": "ring_03_l",
		"LeftLittleProximal": "pinky_01_l",
		"LeftLittleIntermediate": "pinky_02_l",
		"LeftLittleDistal": "pinky_03_l",
		"RightThumbMetacarpal": "thumb_01_r",
		"RightThumbProximal": "thumb_02_r",
		"RightThumbDistal": "thumb_03_r",
		"RightIndexProximal": "index_01_r",
		"RightIndexIntermediate": "index_02_r",
		"RightIndexDistal": "index_03_r",
		"RightMiddleProximal": "middle_01_r",
		"RightMiddleIntermediate": "middle_02_r",
		"RightMiddleDistal": "middle_03_r",
		"RightRingProximal": "ring_01_r",
		"RightRingIntermediate": "ring_02_r",
		"RightRingDistal": "ring_03_r",
		"RightLittleProximal": "pinky_01_r",
		"RightLittleIntermediate": "pinky_02_r",
		"RightLittleDistal": "pinky_03_r"
	}
	
	for profile_bone in destined_mappings:
		d_bmap.set_skeleton_bone_name(profile_bone, destined_mappings[profile_bone])
		
	var d_path = "res://assets/characters/destined_one/animations/destined_one_bonemap.tres"
	var err = ResourceSaver.save(d_bmap, d_path)
	if err == OK:
		print("Saved Destined One BoneMap to: ", d_path)
	else:
		printerr("Failed to save Destined One BoneMap: ", err)
		
	# 2. Create Source Knight BoneMap
	var k_bmap = BoneMap.new()
	k_bmap.profile = profile
	
	var knight_mappings: Dictionary = {
		"Root": "Bone",
		"Hips": "Hips",
		"Spine": "Abdomen",
		"Chest": "Torso",
		"Neck": "Neck",
		"Head": "Head",
		"LeftShoulder": "Shoulder.L",
		"LeftUpperArm": "UpperArm.L",
		"LeftLowerArm": "LowerArm.L",
		"LeftHand": "Palm.L",
		"RightShoulder": "Shoulder.R",
		"RightUpperArm": "UpperArm.R",
		"RightLowerArm": "LowerArm.R",
		"RightHand": "Palm.R",
		"LeftUpperLeg": "UpperLeg.L",
		"LeftLowerLeg": "LowerLeg.L",
		"LeftFoot": "Foot.L",
		"RightUpperLeg": "UpperLeg.R",
		"RightLowerLeg": "LowerLeg.R",
		"RightFoot": "Foot.R",
		"LeftThumbMetacarpal": "Thumb.L",
		"LeftThumbProximal": "Thumb2.L",
		"RightThumbMetacarpal": "Thumb.R",
		"RightThumbProximal": "Thumb2.R",
		"LeftIndexProximal": "MiddleHand.L",
		"LeftIndexIntermediate": "Fingers.L",
		"RightIndexProximal": "MiddleHand.R",
		"RightIndexIntermediate": "Fingers.R"
	}
	
	for profile_bone in knight_mappings:
		k_bmap.set_skeleton_bone_name(profile_bone, knight_mappings[profile_bone])
		
	var k_path = "res://assets/characters/destined_one/animations/source_knight_bonemap.tres"
	err = ResourceSaver.save(k_bmap, k_path)
	if err == OK:
		print("Saved Knight Source BoneMap to: ", k_path)
	else:
		printerr("Failed to save Knight Source BoneMap: ", err)
		
	quit(0)
