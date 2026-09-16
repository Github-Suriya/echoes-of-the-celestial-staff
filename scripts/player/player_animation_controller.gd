class_name PlayerAnimationController
extends Node

## PlayerAnimationController
## Decouples movement and combat state changes from visual presentation.
## Prepared to drive AnimatedSprite2D, AnimationPlayer, or procedural placeholder tweens.

signal animation_played(anim_name: StringName)

@export var visuals_root: Node2D
@export var animated_sprite: AnimatedSprite2D

var current_animation: StringName = &"idle"

func _ready() -> void:
	if visuals_root == null and owner != null and owner.has_node("Visuals"):
		visuals_root = owner.get_node("Visuals") as Node2D
	
	if animated_sprite == null and visuals_root != null and visuals_root.has_node("AnimatedSprite2D"):
		animated_sprite = visuals_root.get_node("AnimatedSprite2D") as AnimatedSprite2D
	
	_sync_sprite_visibility()
	
	# Connect to sibling StateMachine if present
	var sm: StateMachine = _get_state_machine()
	if sm != null:
		sm.state_changed.connect(_on_state_changed)

func _sync_sprite_visibility() -> void:
	if animated_sprite != null and animated_sprite.sprite_frames != null and visuals_root != null:
		for child in visuals_root.get_children():
			if child is ColorRect:
				child.visible = false

func play_animation(anim_name: StringName) -> void:
	current_animation = anim_name
	animation_played.emit(anim_name)
	
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		var anim_str: String = String(anim_name)
		if animated_sprite.sprite_frames.has_animation(anim_str):
			animated_sprite.play(anim_str)
	
	# Procedural placeholder visual feedback (squash/stretch)
	_apply_placeholder_feedback(anim_name)

func play_attack_animation(attack_id: StringName) -> void:
	play_animation(attack_id)

func play_dodge_animation() -> void:
	play_animation(&"dodge")

func play_perfect_dodge_feedback() -> void:
	play_animation(&"perfect_dodge")

func play_parry_animation() -> void:
	play_animation(&"parry")

func play_perfect_parry_feedback() -> void:
	play_animation(&"perfect_parry")

func play_air_attack_animation() -> void:
	play_animation(&"air_1")

func play_charge_animation() -> void:
	play_animation(&"charge_heavy")

func play_stance_change_feedback(stance: int) -> void:
	match stance:
		StanceData.StanceType.SWIFT:
			play_swift_feedback()
		StanceData.StanceType.MOUNTAIN:
			play_mountain_feedback()
		StanceData.StanceType.STORM:
			play_storm_feedback()

func play_swift_feedback() -> void:
	play_animation(&"stance_swift")

func play_mountain_feedback() -> void:
	play_animation(&"stance_mountain")

func play_storm_feedback() -> void:
	play_animation(&"stance_storm")

func play_hit_reaction() -> void:
	play_animation(&"hit_reaction")

func play_stagger() -> void:
	play_animation(&"stagger")

func play_celestial_arc() -> void:
	play_animation(&"ability_celestial_arc")

func play_heavenly_pulse() -> void:
	play_animation(&"ability_heavenly_pulse")

func play_cloud_step() -> void:
	play_animation(&"ability_cloud_step")

func play_spirit_fail_feedback() -> void:
	play_animation(&"ability_fail")

func play_transformation_activate() -> void:
	play_animation(&"transformation_activate")

func play_transformation_active() -> void:
	play_animation(&"transformation_active")

func play_transformation_end() -> void:
	play_animation(&"transformation_end")

func _on_state_changed(_old_state: StringName, new_state: StringName) -> void:
	match new_state:
		&"Idle":
			play_animation(&"idle")
		&"Run":
			play_animation(&"run")
		&"Jump":
			play_animation(&"jump")
		&"Fall":
			play_animation(&"fall")
		&"Land":
			play_animation(&"land")
		&"Dodge":
			play_dodge_animation()
		&"Parry":
			play_parry_animation()
		&"AirAttack":
			play_air_attack_animation()

func _apply_placeholder_feedback(anim_name: StringName) -> void:
	if visuals_root == null:
		return
	
	var facing_sign: float = 1.0
	if owner != null and owner.has_method("get_facing_direction"):
		facing_sign = float(owner.get_facing_direction())
	elif visuals_root.scale.x < 0.0:
		facing_sign = -1.0
	
	match anim_name:
		&"run", &"idle":
			visuals_root.scale = Vector2(facing_sign, 1.0)
		&"jump":
			# Stretch vertically
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 0.85, 1.15)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.15)
		&"land":
			# Squash vertically
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.2, 0.8)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.12)
		&"light_1", &"light_2", &"light_3":
			# Forward lean / lunge compression
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.2, 0.88)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.10)
		&"heavy_1":
			# Overhead windup stretch followed by impact compression
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 0.8, 1.25)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.18)
		&"hit_reaction":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 0.85, 0.85)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.12)
		&"stagger":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.15, 0.75)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.20)
		&"dodge":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.3, 0.7)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.25)
		&"perfect_dodge":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.45, 0.6)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.18)
		&"parry":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 0.9, 1.15)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.15)
		&"perfect_parry":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.3, 1.3)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.15)
		&"air_1":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 0.85, 1.25)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.16)
		&"charge_heavy":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 0.92, 1.1)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.12)
		&"stance_swift":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.10, 0.90)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.12)
		&"stance_mountain":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.18, 0.82)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.15)
		&"stance_storm":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 0.92, 1.12)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.12)
		&"ability_celestial_arc":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.25, 0.85)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.12)
		&"ability_heavenly_pulse":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.35, 0.70)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.15)
		&"ability_cloud_step":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.50, 0.65)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.18)
		&"ability_fail":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 0.92, 0.92)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.10)
		&"transformation_activate":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 1.35, 1.35)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.22)
		&"transformation_active":
			visuals_root.scale = Vector2(facing_sign, 1.0)
		&"transformation_end":
			var tween: Tween = create_tween()
			visuals_root.scale = Vector2(facing_sign * 0.90, 1.10)
			tween.tween_property(visuals_root, "scale", Vector2(facing_sign, 1.0), 0.15)

func _get_state_machine() -> StateMachine:
	if owner != null and owner.has_node("StateMachine"):
		return owner.get_node("StateMachine") as StateMachine
	return null
