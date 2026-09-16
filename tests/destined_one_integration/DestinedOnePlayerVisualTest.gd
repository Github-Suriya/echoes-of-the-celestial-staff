extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var state_label: Label = $CanvasLayer/UI/VBox/StateLabel
@onready var anim_label: Label = $CanvasLayer/UI/VBox/AnimLabel
@onready var facing_label: Label = $CanvasLayer/UI/VBox/FacingLabel
@onready var fps_label: Label = $CanvasLayer/UI/VBox/FPSLabel

const DESTINED_SPRITEFRAMES_PATH: String = "res://assets/characters/destined_one/spriteframes/destined_one_512_spriteframes.tres"
const CANONICAL_SPRITE_SCALE: Vector2 = Vector2(0.14, 0.14)
const CANONICAL_SPRITE_POS: Vector2 = Vector2(0, -23)

func _ready() -> void:
	_integrate_destined_one_visuals()

func _integrate_destined_one_visuals() -> void:
	if player == null:
		printerr("ERROR: Player node not found")
		return
		
	var visuals_root: Node2D = player.get_node_or_null("Visuals")
	if visuals_root == null:
		printerr("ERROR: Visuals node not found on Player")
		return
		
	var sprite: AnimatedSprite2D = visuals_root.get_node_or_null("AnimatedSprite2D")
	if sprite == null:
		printerr("ERROR: AnimatedSprite2D not found under Visuals")
		return
		
	# Load Destined One SpriteFrames
	if ResourceLoader.exists(DESTINED_SPRITEFRAMES_PATH):
		var sf = load(DESTINED_SPRITEFRAMES_PATH)
		sprite.sprite_frames = sf
		sprite.scale = CANONICAL_SPRITE_SCALE
		sprite.position = CANONICAL_SPRITE_POS
		sprite.play("idle")
		print("[INTEGRATION] Destined One SpriteFrames bound to Player/Visuals/AnimatedSprite2D successfully")
	else:
		printerr("ERROR: Destined One SpriteFrames not found at: ", DESTINED_SPRITEFRAMES_PATH)
		
	# Synchronize visibility so placeholder ColorRects are hidden
	var anim_ctrl = player.get_node_or_null("PlayerAnimationController")
	if anim_ctrl and anim_ctrl.has_method("_sync_sprite_visibility"):
		anim_ctrl._sync_sprite_visibility()

func _process(_delta: float) -> void:
	if fps_label:
		var fps = Engine.get_frames_per_second()
		var mem_mb = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
		fps_label.text = "FPS: %d | Memory: %.1f MB" % [fps, mem_mb]
		
	if player:
		if state_label and player.has_node("StateMachine"):
			var sm = player.get_node("StateMachine")
			state_label.text = "Gameplay State: %s" % (sm.current_state.name if sm.current_state else "None")
			
		if anim_label and player.has_node("PlayerAnimationController"):
			var anim_ctrl = player.get_node("PlayerAnimationController")
			anim_label.text = "Animation: %s" % String(anim_ctrl.current_animation)
			
		if facing_label and player.has_method("get_facing_direction"):
			facing_label.text = "Facing Direction: %s" % ("RIGHT (+1)" if player.get_facing_direction() > 0 else "LEFT (-1)")
