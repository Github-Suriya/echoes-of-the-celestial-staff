class_name BossAnimationController
extends Node

## BossAnimationController
## Procedural presentation controller for The Granite Abbot and boss encounters.
## Coordinates squash-and-stretch, color modulations, staff postures, hit flashes,
## deflection recoil, and Phase 2 stone resonance auras without sprite asset dependencies.

@export var visuals_root: Node2D = null
@export var animated_sprite: AnimatedSprite2D = null

var _body_rect: ColorRect = null
var _crest_rect: ColorRect = null
var _staff_rect: ColorRect = null
var _aura_rect: ColorRect = null

var _active_tween: Tween = null
var _base_body_color: Color = Color(0.32, 0.35, 0.38) # Heavy granite grey
var _base_crest_color: Color = Color(0.8, 0.88, 0.95) # Celestial monastic crest
var _base_staff_color: Color = Color(0.45, 0.42, 0.38) # Ceremonial granite staff

func _ready() -> void:
	if visuals_root == null and owner != null and owner.has_node("Visuals"):
		visuals_root = owner.get_node("Visuals") as Node2D
	
	_discover_visual_nodes()

func _discover_visual_nodes() -> void:
	if visuals_root == null:
		return
	
	if animated_sprite == null and visuals_root.has_node("AnimatedSprite2D"):
		animated_sprite = visuals_root.get_node("AnimatedSprite2D") as AnimatedSprite2D
	
	if visuals_root.has_node("Body"):
		_body_rect = visuals_root.get_node("Body") as ColorRect
		if _body_rect != null:
			_base_body_color = _body_rect.color
	if visuals_root.has_node("Crest"):
		_crest_rect = visuals_root.get_node("Crest") as ColorRect
		if _crest_rect != null:
			_base_crest_color = _crest_rect.color
	if visuals_root.has_node("Staff"):
		_staff_rect = visuals_root.get_node("Staff") as ColorRect
		if _staff_rect != null:
			_base_staff_color = _staff_rect.color
	if visuals_root.has_node("Aura"):
		_aura_rect = visuals_root.get_node("Aura") as ColorRect
		if _aura_rect != null:
			_aura_rect.visible = false
	
	_sync_sprite_visibility()

func _sync_sprite_visibility() -> void:
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if _body_rect != null:
			_body_rect.visible = false
		if _crest_rect != null:
			_crest_rect.visible = false
		if _staff_rect != null:
			_staff_rect.visible = false

func play_sprite_anim(anim_name: String) -> void:
	if animated_sprite != null and animated_sprite.sprite_frames != null:
		if animated_sprite.sprite_frames.has_animation(anim_name):
			animated_sprite.play(anim_name)

func update_facing(direction: int) -> void:
	if visuals_root == null:
		return
	var dir_sign: float = 1.0 if direction >= 0 else -1.0
	visuals_root.scale.x = absf(visuals_root.scale.x) * dir_sign

func play_intro(duration: float = 1.5) -> void:
	play_sprite_anim("idle")
	if visuals_root == null:
		return
	
	_kill_active_tween()
	visuals_root.scale = Vector2(0.9, 0.6)
	visuals_root.modulate = Color(0.5, 0.5, 0.6, 0.8)
	
	_active_tween = visuals_root.create_tween()
	if _active_tween != null:
		_active_tween.set_parallel(true)
		_active_tween.tween_property(visuals_root, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
		_active_tween.tween_property(visuals_root, "modulate", Color.WHITE, duration)

func play_attack_telegraph(duration: float = 0.5) -> void:
	play_sprite_anim("idle")
	if visuals_root == null:
		return
	
	_kill_active_tween()
	_active_tween = visuals_root.create_tween()
	if _active_tween != null:
		_active_tween.set_parallel(true)
		# Anticipation windup: lean back slightly and raise staff
		_active_tween.tween_property(visuals_root, "scale", Vector2(0.9, 1.1), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		if _staff_rect != null:
			_active_tween.tween_property(_staff_rect, "rotation_degrees", -25.0, duration)

func play_attack_active(duration: float = 0.15) -> void:
	play_sprite_anim("attack")
	if visuals_root == null:
		return
	
	_kill_active_tween()
	_active_tween = visuals_root.create_tween()
	if _active_tween != null:
		_active_tween.set_parallel(true)
		# Forward strike thrust: squash horizontally and swing staff forward
		_active_tween.tween_property(visuals_root, "scale", Vector2(1.2, 0.85), duration).set_trans(Tween.TRANS_CIRC).set_ease(Tween.EASE_OUT)
		if _staff_rect != null:
			_active_tween.tween_property(_staff_rect, "rotation_degrees", 45.0, duration)

func play_attack_recovery(duration: float = 0.45) -> void:
	play_sprite_anim("idle")
	if visuals_root == null:
		return
	
	_kill_active_tween()
	_active_tween = visuals_root.create_tween()
	if _active_tween != null:
		_active_tween.set_parallel(true)
		_active_tween.tween_property(visuals_root, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		if _staff_rect != null:
			_active_tween.tween_property(_staff_rect, "rotation_degrees", 0.0, duration)

func play_attack_interrupted(duration: float = 0.45) -> void:
	play_sprite_anim("stagger")
	if visuals_root == null:
		return
	
	_kill_active_tween()
	visuals_root.modulate = Color(2.5, 2.5, 2.5, 1.0) # Deflection flash
	
	_active_tween = visuals_root.create_tween()
	if _active_tween != null:
		_active_tween.set_parallel(true)
		# Strong recoil back
		_active_tween.tween_property(visuals_root, "scale", Vector2(0.8, 1.25), 0.15).set_trans(Tween.TRANS_BOUNCE)
		_active_tween.tween_property(visuals_root, "modulate", Color.WHITE, duration).set_trans(Tween.TRANS_SINE)
		if _staff_rect != null:
			_active_tween.tween_property(_staff_rect, "rotation_degrees", -40.0, 0.15)

func play_hit_flash(duration: float = 0.15) -> void:
	play_sprite_anim("hit")
	if visuals_root == null:
		return
	
	_kill_active_tween()
	visuals_root.modulate = Color(1.8, 1.0, 1.0, 1.0) # Red hit flash
	_active_tween = visuals_root.create_tween()
	if _active_tween != null:
		_active_tween.tween_property(visuals_root, "modulate", Color.WHITE, duration)

func play_stagger(duration: float = 1.8) -> void:
	play_sprite_anim("stagger")
	if visuals_root == null:
		return
	
	_kill_active_tween()
	visuals_root.modulate = Color(1.0, 0.8, 0.4, 1.0) # Posture broken flash
	
	_active_tween = visuals_root.create_tween()
	if _active_tween != null:
		_active_tween.set_parallel(true)
		_active_tween.tween_property(visuals_root, "scale", Vector2(1.15, 0.7), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_active_tween.tween_property(visuals_root, "modulate", Color.WHITE, duration)
		if _staff_rect != null:
			_active_tween.tween_property(_staff_rect, "rotation_degrees", 80.0, 0.3)

func play_phase_transition(aura_color: Color, duration: float = 1.8) -> void:
	play_sprite_anim("transition")
	if visuals_root == null:
		return
	
	_kill_active_tween()
	if _aura_rect != null:
		_aura_rect.visible = true
		_aura_rect.color = aura_color
	
	visuals_root.modulate = Color(2.0, 2.0, 1.5, 1.0) # Radiant surge
	
	_active_tween = visuals_root.create_tween()
	if _active_tween != null:
		_active_tween.set_parallel(true)
		_active_tween.tween_property(visuals_root, "scale", Vector2(1.1, 1.1), duration * 0.5)
		_active_tween.tween_property(visuals_root, "modulate", Color.WHITE, duration)

func play_defeat(duration: float = 2.0) -> void:
	play_sprite_anim("death")
	if visuals_root == null:
		return
	
	_kill_active_tween()
	if _aura_rect != null:
		_aura_rect.visible = false
	
	_active_tween = visuals_root.create_tween()
	if _active_tween != null:
		_active_tween.set_parallel(true)
		_active_tween.tween_property(visuals_root, "scale", Vector2(1.2, 0.4), duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_active_tween.tween_property(visuals_root, "modulate:a", 0.3, duration)
		if _staff_rect != null:
			_active_tween.tween_property(_staff_rect, "rotation_degrees", 90.0, duration * 0.5)

func reset_visuals() -> void:
	_kill_active_tween()
	if visuals_root != null:
		visuals_root.scale = Vector2.ONE
		visuals_root.modulate = Color.WHITE
	
	if _body_rect != null:
		_body_rect.color = _base_body_color
	if _crest_rect != null:
		_crest_rect.color = _base_crest_color
	if _staff_rect != null:
		_staff_rect.color = _base_staff_color
		_staff_rect.rotation_degrees = 0.0
	if _aura_rect != null:
		_aura_rect.visible = false

func _kill_active_tween() -> void:
	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
		_active_tween = null
