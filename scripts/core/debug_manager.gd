extends Node

## DebugManager
## Development-only diagnostic and logging utility for Echoes of the Celestial Staff.
## Registered as global Autoload singleton "DebugManager".

var is_debug_enabled: bool = true

func _ready() -> void:
	# Automatically disable verbose debug logging in export/release builds unless forced
	is_debug_enabled = OS.is_debug_build()
	log_info("DebugManager initialized. Mode: " + ("DEBUG" if is_debug_enabled else "RELEASE"))

func log_info(message: String, category: String = "CORE") -> void:
	if not is_debug_enabled:
		return
	print("[INFO][%s] %s" % [category, message])

func log_warn(message: String, category: String = "CORE") -> void:
	if not is_debug_enabled:
		return
	push_warning("[WARN][%s] %s" % [category, message])

func log_error(message: String, category: String = "CORE") -> void:
	# Errors are always pushed even in non-debug mode for diagnostics
	push_error("[ERROR][%s] %s" % [category, message])

func log_debug(message: String, category: String = "CORE") -> void:
	if not is_debug_enabled:
		return
	print_rich("[color=cyan][DEBUG][%s] %s[/color]" % [category, message])

func get_fps() -> float:
	return Performance.get_monitor(Performance.TIME_FPS)

func get_static_memory_mb() -> float:
	var bytes: float = Performance.get_monitor(Performance.MEMORY_STATIC)
	return bytes / (1024.0 * 1024.0)

func get_draw_calls() -> int:
	return int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
