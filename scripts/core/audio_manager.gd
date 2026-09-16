extends Node

## AudioManager
## Manages game audio playback across dedicated mixing buses.
## Registered as global Autoload singleton "AudioManager".

const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"
const BUS_AMBIENCE: StringName = &"Ambience"
const BUS_UI: StringName = &"UI"
const BUS_VOICE: StringName = &"Voice"

const ALL_BUSES: Array[StringName] = [
	BUS_MASTER,
	BUS_MUSIC,
	BUS_SFX,
	BUS_AMBIENCE,
	BUS_UI,
	BUS_VOICE
]

const SFX_POOL_SIZE: int = 8

const AudioLibrary = preload("res://scripts/core/audio_library.gd")

var _music_player: AudioStreamPlayer
var _ambience_player: AudioStreamPlayer
var _ui_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_index: int = 0

var _debug_manager: Node

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if is_inside_tree() and has_node("/root/DebugManager"):
		_debug_manager = get_node("/root/DebugManager")
	
	_create_audio_players()
	_verify_audio_buses()
	_connect_event_bus()
	
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("AudioManager initialized with 6 audio buses.", "AUDIO")

func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	
	_music_player.stream = stream
	_music_player.play()
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("Playing music: %s" % stream.resource_path, "AUDIO")

func play_music_by_name(state_name: StringName) -> void:
	var stream: AudioStream = AudioLibrary.get_music_stream(state_name)
	if stream != null:
		play_music(stream)

func stop_music() -> void:
	if _music_player.is_playing():
		_music_player.stop()

func play_ambience(stream: AudioStream) -> void:
	if stream == null:
		return
	
	_ambience_player.stream = stream
	_ambience_player.play()

func play_ambience_by_name(ambience_name: StringName) -> void:
	var stream: AudioStream = AudioLibrary.get_ambience_stream(ambience_name)
	if stream != null:
		play_ambience(stream)

func stop_ambience() -> void:
	if _ambience_player.is_playing():
		_ambience_player.stop()

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	if stream == null:
		return
	
	var player: AudioStreamPlayer = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	
	player.stream = stream
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.play()

func play_sfx_by_name(sfx_name: StringName, pitch_scale: float = 1.0) -> void:
	var stream: AudioStream = AudioLibrary.get_sfx_stream(sfx_name)
	if stream != null:
		play_sfx(stream, pitch_scale)

func play_ui_sound(stream: AudioStream) -> void:
	if stream == null:
		return
	
	_ui_player.stream = stream
	_ui_player.play()

func play_ui_by_name(ui_sfx_name: StringName) -> void:
	var stream: AudioStream = AudioLibrary.get_sfx_stream(ui_sfx_name)
	if stream != null:
		play_ui_sound(stream)

func set_bus_volume_db(bus_name: StringName, volume_db: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, volume_db)

func is_bus_available(bus_name: StringName) -> bool:
	return AudioServer.get_bus_index(bus_name) >= 0

func _connect_event_bus() -> void:
	if not has_node("/root/EventBus"):
		return
	var bus: Node = get_node("/root/EventBus")
	if bus == null:
		return
	
	if bus.has_signal("damage_dealt") and not bus.damage_dealt.is_connected(_on_damage_dealt):
		bus.damage_dealt.connect(_on_damage_dealt)
	if bus.has_signal("perfect_parry") and not bus.perfect_parry.is_connected(_on_perfect_parry):
		bus.perfect_parry.connect(_on_perfect_parry)
	elif bus.has_signal("parry_success") and not bus.parry_success.is_connected(_on_parry_success):
		bus.parry_success.connect(_on_parry_success)
	if bus.has_signal("dodge_started") and not bus.dodge_started.is_connected(_on_dodge_started):
		bus.dodge_started.connect(_on_dodge_started)
	if bus.has_signal("enemy_died") and not bus.enemy_died.is_connected(_on_enemy_died):
		bus.enemy_died.connect(_on_enemy_died)
	if bus.has_signal("checkpoint_activated") and not bus.checkpoint_activated.is_connected(_on_checkpoint_activated):
		bus.checkpoint_activated.connect(_on_checkpoint_activated)
	if bus.has_signal("transformation_started") and not bus.transformation_started.is_connected(_on_transformation_started):
		bus.transformation_started.connect(_on_transformation_started)
	if bus.has_signal("transformation_ended") and not bus.transformation_ended.is_connected(_on_transformation_ended):
		bus.transformation_ended.connect(_on_transformation_ended)
	if bus.has_signal("player_died") and not bus.player_died.is_connected(_on_player_died):
		bus.player_died.connect(_on_player_died)

func _on_damage_dealt(_target: Node2D, amount: float, is_critical: bool) -> void:
	if is_critical or amount >= 25.0:
		play_sfx_by_name(&"hit_heavy", randf_range(0.95, 1.05))
	else:
		play_sfx_by_name(&"hit_light", randf_range(0.98, 1.05))

func _on_perfect_parry(_defender: Node2D, _attacker: Node2D) -> void:
	play_sfx_by_name(&"perfect_parry", 1.0)

func _on_parry_success(_defender: Node2D, _attacker: Node2D) -> void:
	play_sfx_by_name(&"parry", 1.0)

func _on_dodge_started(_entity: Node2D, _direction: int) -> void:
	play_sfx_by_name(&"dodge", randf_range(0.95, 1.05))

func _on_enemy_died(_enemy: Node2D, _bounty: int) -> void:
	play_sfx_by_name(&"enemy_death", 1.0)

func _on_checkpoint_activated(_cp_id: String) -> void:
	play_ui_by_name(&"checkpoint")

func _on_transformation_started() -> void:
	play_sfx_by_name(&"awakening_start", 1.0)

func _on_transformation_ended() -> void:
	play_sfx_by_name(&"awakening_end", 1.0)

func _on_player_died() -> void:
	play_sfx_by_name(&"player_death", 1.0)

func _create_audio_players() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = BUS_MUSIC
	add_child(_music_player)
	
	_ambience_player = AudioStreamPlayer.new()
	_ambience_player.name = "AmbiencePlayer"
	_ambience_player.bus = BUS_AMBIENCE
	add_child(_ambience_player)
	
	_ui_player = AudioStreamPlayer.new()
	_ui_player.name = "UIPlayer"
	_ui_player.bus = BUS_UI
	add_child(_ui_player)
	
	for i in range(SFX_POOL_SIZE):
		var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer_%d" % i
		sfx_player.bus = BUS_SFX
		add_child(sfx_player)
		_sfx_pool.append(sfx_player)

func _verify_audio_buses() -> void:
	for bus in ALL_BUSES:
		if not is_bus_available(bus) and _debug_manager != null and _debug_manager.has_method("log_warn"):
			_debug_manager.log_warn("Audio bus not found in layout: %s" % bus, "AUDIO")
