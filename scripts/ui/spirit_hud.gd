class_name SpiritHUD
extends CanvasLayer

## SpiritHUD
## Development UI displaying real-time Spirit resource gauge and ability slot cards with live cooldowns.

@export var player: PlayerController = null

@onready var spirit_label: Label = $HUDPanel/MarginContainer/VBoxContainer/SpiritHeader/SpiritLabel
@onready var spirit_progress: ProgressBar = $HUDPanel/MarginContainer/VBoxContainer/SpiritBar
@onready var slot_1_status: Label = $HUDPanel/MarginContainer/VBoxContainer/AbilityContainer/Slot1/VBox/StatusLabel
@onready var slot_2_status: Label = $HUDPanel/MarginContainer/VBoxContainer/AbilityContainer/Slot2/VBox/StatusLabel
@onready var slot_3_status: Label = $HUDPanel/MarginContainer/VBoxContainer/AbilityContainer/Slot3/VBox/StatusLabel

var _spirit_comp: SpiritComponent = null
var _ability_ctrl: SpiritAbilityController = null

func _ready() -> void:
	if player != null:
		bind_player(player)

func bind_player(target_player: CharacterBody2D) -> void:
	if target_player == null:
		return
	
	if target_player.has_node("Components/SpiritComponent"):
		_spirit_comp = target_player.get_node("Components/SpiritComponent") as SpiritComponent
		if _spirit_comp != null:
			_spirit_comp.spirit_changed.connect(_on_spirit_changed)
			_update_spirit_display(_spirit_comp.get_spirit(), _spirit_comp.get_max_spirit())
	
	if target_player.has_node("Components/SpiritAbilityController"):
		_ability_ctrl = target_player.get_node("Components/SpiritAbilityController") as SpiritAbilityController

func _process(_delta: float) -> void:
	if _ability_ctrl == null:
		return
	
	# Update Slot 1: Celestial Arc
	_update_slot_status(slot_1_status, &"celestial_arc")
	# Update Slot 2: Heavenly Pulse
	_update_slot_status(slot_2_status, &"heavenly_pulse")
	# Update Slot 3: Cloud Step
	_update_slot_status(slot_3_status, &"cloud_step")

func _update_slot_status(label: Label, ability_id: StringName) -> void:
	if label == null or _ability_ctrl == null:
		return
	
	if _ability_ctrl.is_ability_ready(ability_id):
		label.text = "READY"
		label.modulate = Color(0.2, 1.0, 0.5)
	else:
		var rem: float = _ability_ctrl.get_cooldown_remaining(ability_id)
		label.text = "%.1fs" % rem
		label.modulate = Color(1.0, 0.4, 0.4)

func _on_spirit_changed(current: float, max_val: float) -> void:
	_update_spirit_display(current, max_val)

func _update_spirit_display(current: float, max_val: float) -> void:
	if spirit_label != null:
		spirit_label.text = "SPIRIT: %.0f / %.0f" % [current, max_val]
	if spirit_progress != null:
		spirit_progress.max_value = max_val
		spirit_progress.value = current
