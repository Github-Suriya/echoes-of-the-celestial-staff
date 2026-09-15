class_name PlayerAnimationController
extends Node

## PlayerAnimationController
## Decouples movement state machine changes from visual presentation.
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
	if current_animation == anim_name:
		return
	
	current_animation = anim_name
	animation_played.emit(anim_name)
	
	# Procedural placeholder visual feedback (squash/stretch)
	_apply_placeholder_feedback(anim_name)

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
	
	var tween: Tween = create_tween()
	match anim_name:
		&"jump":
			# Stretch vertically
			visuals_root.scale = Vector2(0.85, 1.15)
			tween.tween_property(visuals_root, "scale", Vector2.ONE, 0.15)
		&"land":
			# Squash vertically
			visuals_root.scale = Vector2(1.2, 0.8)
			tween.tween_property(visuals_root, "scale", Vector2.ONE, 0.12)
		&"run":
			visuals_root.scale = Vector2.ONE
		&"idle":
			visuals_root.scale = Vector2.ONE

func _get_state_machine() -> StateMachine:
	if owner != null and owner.has_node("StateMachine"):
		return owner.get_node("StateMachine") as StateMachine
	return null
