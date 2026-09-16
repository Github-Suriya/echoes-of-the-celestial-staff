class_name EnemyAnimationController
extends Node

## EnemyAnimationController
## Procedural visual and animation feedback controller for enemies.
## Drives facing direction, squash/stretch, color flashes, and telegraph indicators.

@export var visuals_root: Node2D = null
@export var animated_sprite: AnimatedSprite2D = null
@export var body_rect: ColorRect = null
@export var eye_rect: ColorRect = null
@export var arm_rect: ColorRect = null
@export var indicator_rect: ColorRect = null

var base_color: Color = Color(0.82, 0.45, 0.18, 1.0) # Copper / Rust automaton
var eye_color: Color = Color(0.1, 0.1, 0.15, 1.0)

var _tween: Tween = null

func _ready() -> void:
	if visuals_root == null and owner != null and owner.has_node("Visuals"):
		visuals_root = owner.get_node("Visuals") as Node2D
	
	if visuals_root != null:
		if animated_sprite == null and visuals_root.has_node("AnimatedSprite2D"):
			animated_sprite = visuals_root.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if body_rect == null and visuals_root.has_node("Body"):
			body_rect = visuals_root.get_node("Body") as ColorRect
		if eye_rect == null and visuals_root.has_node("Eye"):
			eye_rect = visuals_root.get_node("Eye") as ColorRect
		if arm_rect == null and visuals_root.has_node("Arm"):
			arm_rect = visuals_root.get_node("Arm") as ColorRect
		if indicator_rect == null and visuals_root.has_node("Indicator"):
			indicator_rect = visuals_root.get_node("Indicator") as ColorRect
	
	if indicator_rect != null:
		indicator_rect.visible = false
	
	_sync_sprite_visibility()

func _sync_sprite_visibility() -> void:
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if body_rect != null:
			body_rect.visible = false
		if eye_rect != null:
			eye_rect.visible = false
		if arm_rect != null:
			arm_rect.visible = false

func _play_sprite_anim(anim_name: String) -> void:
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)

func set_base_color(color: Color) -> void:
	base_color = color
	if body_rect != null:
		body_rect.color = base_color

func update_facing(direction: int) -> void:
	if visuals_root == null:
		return
	
	# Flip visuals root scale on X without affecting collision
	var target_scale_x: float = 1.0 if direction >= 0 else -1.0
	visuals_root.scale.x = target_scale_x

func play_idle() -> void:
	_play_sprite_anim("idle")
	if indicator_rect != null:
		indicator_rect.visible = false
	if body_rect != null:
		body_rect.color = base_color

func play_walk() -> void:
	_play_sprite_anim("move")
	if indicator_rect != null:
		indicator_rect.visible = false
	if body_rect != null:
		body_rect.color = base_color

func play_alert() -> void:
	if indicator_rect != null:
		indicator_rect.visible = true
		indicator_rect.color = Color(1.0, 0.85, 0.0, 1.0) # Yellow exclamation/alert
	
	_kill_tween()
	if visuals_root != null:
		_tween = visuals_root.create_tween()
		_tween.tween_property(visuals_root, "scale:y", 1.15, 0.1)
		_tween.tween_property(visuals_root, "scale:y", 1.0, 0.1)

func play_attack_telegraph() -> void:
	if indicator_rect != null:
		indicator_rect.visible = true
		indicator_rect.color = Color(1.0, 0.6, 0.1, 1.0) # Orange windup
	if body_rect != null:
		body_rect.color = Color(1.0, 0.55, 0.2, 1.0)

func play_attack_active() -> void:
	_play_sprite_anim("attack")
	if indicator_rect != null:
		indicator_rect.visible = true
		indicator_rect.color = Color(1.0, 0.1, 0.1, 1.0) # Bright red strike
	if body_rect != null:
		body_rect.color = Color(0.95, 0.2, 0.15, 1.0)

func play_attack_recovery() -> void:
	_play_sprite_anim("idle")
	if indicator_rect != null:
		indicator_rect.visible = false
	if body_rect != null:
		body_rect.color = base_color

func play_attack_interrupted() -> void:
	_play_sprite_anim("stagger")
	if indicator_rect != null:
		indicator_rect.visible = false
	
	_kill_tween()
	if body_rect != null:
		body_rect.color = Color(0.3, 0.7, 1.0, 1.0) # Electric cyan deflection
		_tween = body_rect.create_tween()
		_tween.tween_property(body_rect, "color", base_color, 0.60)

func play_hit() -> void:
	_play_sprite_anim("hit")
	_kill_tween()
	if body_rect != null:
		body_rect.color = Color(1.0, 1.0, 1.0, 1.0) # Hit flash
		_tween = body_rect.create_tween()
		_tween.tween_property(body_rect, "color", base_color, 0.12)
	
	if visuals_root != null:
		var current_scale_x: float = visuals_root.scale.x
		var squash_tween: Tween = visuals_root.create_tween()
		squash_tween.tween_property(visuals_root, "scale", Vector2(current_scale_x * 0.9, 1.1), 0.06)
		squash_tween.tween_property(visuals_root, "scale", Vector2(current_scale_x, 1.0), 0.08)

func play_stagger() -> void:
	_play_sprite_anim("stagger")
	if indicator_rect != null:
		indicator_rect.visible = false
	
	_kill_tween()
	if body_rect != null:
		body_rect.color = Color(1.0, 0.8, 0.1, 1.0) # Golden stagger

func play_stagger_end() -> void:
	_play_sprite_anim("idle")
	if body_rect != null:
		body_rect.color = base_color

func play_death() -> void:
	_play_sprite_anim("death")
	if indicator_rect != null:
		indicator_rect.visible = false
	
	_kill_tween()
	if visuals_root != null:
		_tween = visuals_root.create_tween()
		_tween.tween_property(visuals_root, "modulate:a", 0.0, 0.45)

func reset_visuals() -> void:
	_kill_tween()
	if visuals_root != null:
		visuals_root.modulate.a = 1.0
		visuals_root.scale = Vector2.ONE
	if indicator_rect != null:
		indicator_rect.visible = false
	if body_rect != null:
		body_rect.color = base_color

func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
		_tween = null
