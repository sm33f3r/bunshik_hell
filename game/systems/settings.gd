extends Node
## Autoload "Settings": user settings in user://settings.json, separate from saves.

## Off-chain only for now. Flip when a real ChainBridge exists.
const ON_CHAIN_AVAILABLE := false
const MAX_FILE_BYTES: int = 65_536

var settings_path: String = "user://settings.json"
var heal_default: String = "lowest"
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


func to_dict() -> Dictionary:
	return {"heal_default": heal_default, "on_chain": on_chain}


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
	if data.get("on_chain") is bool:
		set_on_chain(data["on_chain"])
	return true


func _ready() -> void:
	load_settings()
