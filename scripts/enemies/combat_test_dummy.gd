class_name CombatTestDummy
extends CharacterBody2D

## CombatTestDummy
## Dedicated stationary/reactive combat dummy for testing hit detection, damage, poise, and knockback.

@onready var health_component: HealthComponent = $Components/HealthComponent
@onready var poise_component: PoiseComponent = $Components/PoiseComponent
@onready var hurtbox: Hurtbox = $Hurtbox
@onready var visual_rect: ColorRect = $Visuals/Body
@onready var status_label: Label = $StatusLabel

var initial_position: Vector2 = Vector2.ZERO
var base_color: Color = Color(0.75, 0.22, 0.22, 1.0) # Crimson dummy
var flash_tween: Tween = null

func _ready() -> void:
	initial_position = global_position
	
	if hurtbox != null:
		hurtbox.hit_received.connect(_on_hit_received)
	
	if poise_component != null:
		poise_component.stagger_started.connect(_on_stagger_started)
		poise_component.stagger_ended.connect(_on_stagger_ended)
	
	_update_status_display()

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y += 980.0 * delta
	
	# Apply ground friction to knockback velocity
	velocity.x = move_toward(velocity.x, 0.0, 700.0 * delta)
	move_and_slide()
	
	_update_status_display()

func _on_hit_received(_damage_info: DamageInfo) -> void:
	if visual_rect == null:
		return
	
	if flash_tween != null and flash_tween.is_valid():
		flash_tween.kill()
	
	flash_tween = create_tween()
	# Hit flash: bright flash, return to current state color
	visual_rect.color = Color(1.0, 0.9, 0.9)
	var target_color: Color = Color(0.95, 0.8, 0.1) if (poise_component != null and poise_component.is_staggered) else base_color
	flash_tween.tween_property(visual_rect, "color", target_color, 0.12)

func _on_stagger_started(_duration: float) -> void:
	if visual_rect != null:
		visual_rect.color = Color(0.95, 0.8, 0.1) # Celestial Gold outline / color

func _on_stagger_ended() -> void:
	if visual_rect != null:
		visual_rect.color = base_color

func reset_dummy() -> void:
	global_position = initial_position
	velocity = Vector2.ZERO
	
	if health_component != null:
		health_component.reset()
	if poise_component != null:
		poise_component.reset()
	
	if visual_rect != null:
		visual_rect.color = base_color
	
	_update_status_display()

func _update_status_display() -> void:
	if status_label == null:
		return
	
	var hp_str: String = "HP: %.0f/%.0f" % [
		health_component.current_health if health_component != null else 0.0,
		health_component.max_health if health_component != null else 0.0
	]
	
	var poise_str: String = "Poise: %.0f/%.0f" % [
		poise_component.current_poise if poise_component != null else 0.0,
		poise_component.max_poise if poise_component != null else 0.0
	]
	
	var state_str: String = "STAGGERED!" if (poise_component != null and poise_component.is_staggered) else "READY"
	status_label.text = "%s\n%s\n[%s]" % [hp_str, poise_str, state_str]
