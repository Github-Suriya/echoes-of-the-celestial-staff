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
	
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("AudioManager initialized with 6 audio buses.", "AUDIO")

func play_music(stream: AudioStream) -> void:
	if stream == null:
		if _debug_manager != null and _debug_manager.has_method("log_warn"):
			_debug_manager.log_warn("play_music called with null AudioStream.", "AUDIO")
		return
	
	_music_player.stream = stream
	_music_player.play()
	if _debug_manager != null and _debug_manager.has_method("log_info"):
		_debug_manager.log_info("Playing music: %s" % stream.resource_path, "AUDIO")

func stop_music() -> void:
	if _music_player.is_playing():
		_music_player.stop()

func play_ambience(stream: AudioStream) -> void:
	if stream == null:
		if _debug_manager != null and _debug_manager.has_method("log_warn"):
			_debug_manager.log_warn("play_ambience called with null AudioStream.", "AUDIO")
		return
	
	_ambience_player.stream = stream
	_ambience_player.play()

func stop_ambience() -> void:
	if _ambience_player.is_playing():
		_ambience_player.stop()

func play_sfx(stream: AudioStream, pitch_scale: float = 1.0) -> void:
	if stream == null:
		if _debug_manager != null and _debug_manager.has_method("log_warn"):
			_debug_manager.log_warn("play_sfx called with null AudioStream.", "AUDIO")
		return
	
	var player: AudioStreamPlayer = _sfx_pool[_sfx_pool_index]
	_sfx_pool_index = (_sfx_pool_index + 1) % SFX_POOL_SIZE
	
	player.stream = stream
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.play()

func play_ui_sound(stream: AudioStream) -> void:
	if stream == null:
		if _debug_manager != null and _debug_manager.has_method("log_warn"):
			_debug_manager.log_warn("play_ui_sound called with null AudioStream.", "AUDIO")
		return
	
	_ui_player.stream = stream
	_ui_player.play()

func set_bus_volume_db(bus_name: StringName, volume_db: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus_name)
	if bus_index >= 0:
		AudioServer.set_bus_volume_db(bus_index, volume_db)

func is_bus_available(bus_name: StringName) -> bool:
	return AudioServer.get_bus_index(bus_name) >= 0

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
