extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var anim_label: Label = $CanvasLayer/UI/VBox/AnimLabel
@onready var frame_label: Label = $CanvasLayer/UI/VBox/FrameLabel
@onready var fps_label: Label = $CanvasLayer/UI/VBox/FPSLabel
@onready var buttons_container: HBoxContainer = $CanvasLayer/UI/VBox/ButtonsHBox

const ANIMATIONS: Array[String] = ["idle", "run", "light_01", "heavy", "dodge"]

func _ready() -> void:
	var sf_path = "res://assets/characters/destined_one/spriteframes/destined_one_retarget_512_spriteframes.tres"
	if ResourceLoader.exists(sf_path):
		sprite.sprite_frames = load(sf_path)
		print("[2D PREVIEW] Loaded SpriteFrames successfully.")
	else:
		printerr("[2D PREVIEW] SpriteFrames missing at: ", sf_path)
		
	_create_buttons()
	play_anim("idle")

func _process(_delta: float) -> void:
	if fps_label:
		var fps = Engine.get_frames_per_second()
		var mem_mb = float(OS.get_static_memory_usage()) / (1024.0 * 1024.0)
		fps_label.text = "FPS: %d | Memory: %.1f MB" % [fps, mem_mb]
		
	if anim_label and sprite:
		anim_label.text = "Animation: %s | Playing: %s" % [sprite.animation, str(sprite.is_playing())]
		
	if frame_label and sprite:
		frame_label.text = "Frame: %d / %d" % [sprite.frame + 1, sprite.sprite_frames.get_frame_count(sprite.animation)]

func play_anim(anim_name: String) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)
		print("[2D PREVIEW] Playing animation: ", anim_name)

func _create_buttons() -> void:
	if not buttons_container:
		return
	for c in buttons_container.get_children():
		c.queue_free()
		
	for a in ANIMATIONS:
		var btn = Button.new()
		btn.text = a.capitalize()
		btn.pressed.connect(func(): play_anim(a))
		buttons_container.add_child(btn)
