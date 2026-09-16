class_name VFXAutoFree
extends Node2D

## VFXAutoFree
## Automatically frees temporary VFX entities after their animation/particle lifecycle completes.

@export var duration: float = 0.55

func _ready() -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(duration)
	timer.timeout.connect(queue_free)
