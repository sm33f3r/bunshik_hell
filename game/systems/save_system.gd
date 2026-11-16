extends Node
## Autoload "SaveSystem": versioned JSON saves. Never loads .tres/.res files.

const GameStateScript := preload("res://systems/game_state.gd")

const SAVE_VERSION: int = 1
const MAX_SAVE_BYTES: int = 1_048_576

var save_path: String = "user://saves/slot_1.json"
var last_error: String = ""


## Saves `state` (default: the GameState autoload). Returns true on success.
func save_game(state: GameStateScript = null) -> bool:
	var gs: GameStateScript = _resolve(state)
	if gs == null:
		return _fail("no game state available")
	var dir_path: String = save_path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(dir_path) != OK:
		return _fail("cannot create directory " + dir_path)
	var payload: Dictionary = {
		"save_version": SAVE_VERSION,
		"game": gs.to_dict(),
	}
	var tmp_path: String = save_path + ".tmp"
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if file == null:
		return _fail("cannot open " + tmp_path)
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	if DirAccess.rename_absolute(tmp_path, save_path) != OK:
		# Rename cannot overwrite on some platforms; remove the old file and retry.
		DirAccess.remove_absolute(save_path)
		if DirAccess.rename_absolute(tmp_path, save_path) != OK:
			return _fail("cannot replace " + save_path)
	last_error = ""
	return true


## Loads into `state` (default: the GameState autoload). Returns false, without
## touching `state`, on any missing, corrupt or too-new file.
func load_game(state: GameStateScript = null) -> bool:
	var gs: GameStateScript = _resolve(state)
	if gs == null:
		return _fail("no game state available")
	if not FileAccess.file_exists(save_path):
		return _fail("no save file")
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		return _fail("cannot open " + save_path)
	if file.get_length() > MAX_SAVE_BYTES:
		return _fail("save file too large")
	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		return _fail("save file is not valid JSON")
	var root: Variant = json.data
	if not root is Dictionary:
		return _fail("save file root is not an object")
	var version: Variant = root.get("save_version")
	if not (version is int or version is float):
		return _fail("missing save_version")
	if int(version) > SAVE_VERSION:
		return _fail("save_version %d is newer than supported %d" % [int(version), SAVE_VERSION])
	if int(version) < 1:
		return _fail("invalid save_version")
	var game: Variant = root.get("game")
	if not game is Dictionary:
		return _fail("missing game data")
	gs.from_dict(game)
	last_error = ""
	return true


func _resolve(state: GameStateScript) -> GameStateScript:
	if state != null:
		return state
	return get_node_or_null("/root/GameState") as GameStateScript


func _fail(message: String) -> bool:
	last_error = message
	return false
