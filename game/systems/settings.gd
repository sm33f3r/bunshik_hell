extends Node
## Autoload "Settings": user settings in user://settings.json, separate from saves.

const ItemCatalogScript := preload("res://systems/item_catalog.gd")

## Off-chain only for now. Flip when a real ChainBridge exists.
const ON_CHAIN_AVAILABLE := false
const MAX_FILE_BYTES: int = 65_536

var settings_path: String = "user://settings.json"
var heal_default: String = "lowest"
var fullscreen: bool = false
## Master volume, 0.0 (silent) to 1.0 (full).
var master_volume: float = 1.0
## Music and SFX bus volumes, 0.0 to 1.0, and their on/off switches (off = the bus is muted).
var music_volume: float = 1.0
var sfx_volume: float = 1.0
var music_enabled: bool = true
var sfx_enabled: bool = true
var on_chain: bool = false
var last_error: String = ""


## Returns false (and leaves on_chain unchanged) when on-chain play is not available.
func set_on_chain(value: bool) -> bool:
	if value and not ON_CHAIN_AVAILABLE:
		last_error = "on-chain play is not available in this build"
		return false
	on_chain = value
	return true


func set_heal_default(value: String) -> bool:
	if value.is_empty():
		return false
	heal_default = value
	return true


## The heal-default choices in menu order: "lowest" first, then each health item.
func heal_default_choices() -> Array[String]:
	var out: Array[String] = ["lowest"]
	var ids: Array = ItemCatalogScript.HEALTH_ITEM_PATHS.keys()
	ids.sort()
	for id: Variant in ids:
		out.append(String(id))
	return out


## Moves heal_default to the next (+1) or previous (-1) choice, wrapping around.
func cycle_heal_default(step: int) -> void:
	var choices: Array[String] = heal_default_choices()
	var index: int = choices.find(heal_default)
	if index < 0:
		index = 0
	set_heal_default(choices[posmod(index + step, choices.size())])


func set_fullscreen(value: bool) -> void:
	fullscreen = value


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)


func set_music_enabled(value: bool) -> void:
	music_enabled = value


func set_sfx_enabled(value: bool) -> void:
	sfx_enabled = value


## Pushes fullscreen and volumes to the window and the audio buses. Not called by the setters, so
## tests (and a settings file read at start-up) can change values without touching the system.
func apply_to_system() -> void:
	var mode: DisplayServer.WindowMode = DisplayServer.WINDOW_MODE_WINDOWED
	if fullscreen:
		mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	DisplayServer.window_set_mode(mode)
	_apply_bus_volume("Master", master_volume)
	_apply_bus_volume("Music", music_volume)
	_apply_bus_volume("SFX", sfx_volume)
	_apply_bus_enabled("Music", music_enabled)
	_apply_bus_enabled("SFX", sfx_enabled)


func _apply_bus_volume(bus_name: String, volume: float) -> void:
	var bus: int = AudioServer.get_bus_index(bus_name)
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, -80.0 if volume <= 0.0 else linear_to_db(volume))


func _apply_bus_enabled(bus_name: String, enabled: bool) -> void:
	var bus: int = AudioServer.get_bus_index(bus_name)
	if bus >= 0:
		AudioServer.set_bus_mute(bus, not enabled)


func to_dict() -> Dictionary:
	return {"heal_default": heal_default, "on_chain": on_chain, "fullscreen": fullscreen,
		"master_volume": master_volume, "music_volume": music_volume, "sfx_volume": sfx_volume,
		"music_enabled": music_enabled, "sfx_enabled": sfx_enabled}


func save_settings() -> bool:
	if DirAccess.make_dir_recursive_absolute(settings_path.get_base_dir()) != OK:
		return false
	var file: FileAccess = FileAccess.open(settings_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(to_dict(), "\t"))
	return true


## Never crashes on a bad file; unknown keys are ignored.
func load_settings() -> bool:
	if not FileAccess.file_exists(settings_path):
		return false
	var file: FileAccess = FileAccess.open(settings_path, FileAccess.READ)
	if file == null or file.get_length() > MAX_FILE_BYTES:
		return false
	var json: JSON = JSON.new()
	if json.parse(file.get_as_text()) != OK or not json.data is Dictionary:
		return false
	var data: Dictionary = json.data
	if data.get("heal_default") is String:
		set_heal_default(data["heal_default"])
	if data.get("fullscreen") is bool:
		set_fullscreen(data["fullscreen"])
	if data.get("master_volume") is float or data.get("master_volume") is int:
		set_master_volume(float(data["master_volume"]))
	if data.get("music_volume") is float or data.get("music_volume") is int:
		set_music_volume(float(data["music_volume"]))
	if data.get("sfx_volume") is float or data.get("sfx_volume") is int:
		set_sfx_volume(float(data["sfx_volume"]))
	if data.get("music_enabled") is bool:
		set_music_enabled(data["music_enabled"])
	if data.get("sfx_enabled") is bool:
		set_sfx_enabled(data["sfx_enabled"])
	if data.get("on_chain") is bool:
		set_on_chain(data["on_chain"])
	return true


func _ready() -> void:
	load_settings()
	apply_to_system()
