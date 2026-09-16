extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var info_label: Label = $UI/Panel/VBox/InfoLabel
@onready var fps_label: Label = $UI/Panel/VBox/FPSLabel

func _ready() -> void:
	print("[WUKONG_2D] Initializing Wukong 2D SpriteFrames Preview...")
	if sprite:
		sprite.play("idle")
	
	$UI/Panel/VBox/HBox/IdleBtn.pressed.connect(func(): sprite.play("idle"))
	$UI/Panel/VBox/HBox/WalkBtn.pressed.connect(func(): sprite.play("walk"))
	$UI/Panel/VBox/HBox/RunBtn.pressed.connect(func(): sprite.play("run"))

func _process(_delta: float) -> void:
	if sprite:
		fps_label.text = "FPS: %d | Frame: %d / %d" % [
			Engine.get_frames_per_second(),
			sprite.frame + 1,
			sprite.sprite_frames.get_frame_count(sprite.animation) if sprite.sprite_frames else 0
		]
		info_label.text = "Animation: %s | Speed: %.1f FPS" % [
			sprite.animation,
			sprite.sprite_frames.get_animation_speed(sprite.animation) if sprite.sprite_frames else 0.0
		]
