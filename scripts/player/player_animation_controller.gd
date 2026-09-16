class_name PlayerAnimationController
extends Node

## PlayerAnimationController
## Decouples movement and combat state changes from visual presentation.
## Prepared to drive AnimatedSprite2D, AnimationPlayer, or procedural placeholder tweens.

signal animation_played(anim_name: StringName)

@export var visuals_root: Node2D

var current_animation: StringName = &"idle"

func _ready() -> void:
	if visuals_root == null and owner != null and owner.has_node("Visuals"):
		visuals_root = owner.get_node("Visuals") as Node2D
	
	# Connect to sibling StateMachine if present
	var sm: StateMachine = _get_state_machine()
	if sm != null:
		sm.state_changed.connect(_on_state_changed)

func play_animation(anim_name: StringName) -> void:
	current_animation = anim_name
	animation_played.emit(anim_name)
	
	# Procedural placeholder visual feedback (squash/stretch)
	_apply_placeholder_feedback(anim_name)

func play_attack_animation(attack_id: StringName) -> void:
	play_animation(attack_id)

func play_hit_reaction() -> void:
	play_animation(&"hit_reaction")

func play_stagger() -> void:
	play_animation(&"stagger")

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

func _get_state_machine() -> StateMachine:
	if owner != null and owner.has_node("StateMachine"):
		return owner.get_node("StateMachine") as StateMachine
	return null
