extends Node
## Autoload "SaveSystem": versioned JSON saves. Never loads .tres/.res files.
##
## save_version stays 1: every key added since is additive (older files simply lack it and load with
## its default). Bump it only if a key changes meaning.
##
## Writing is safe: the text goes to "<save>.tmp" first, which then replaces the real file. A missing
## or corrupt save never crashes: it is logged (push_warning, last_error) and treated as no save.

## A save was written (the HUD flashes its save icon).
signal saved

const GameStateScript := preload("res://systems/game_state.gd")
const MapCatalogScript := preload("res://systems/map_catalog.gd")

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
	var written: bool = file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if not written or write_error != OK:
		DirAccess.remove_absolute(tmp_path)
		return _fail("cannot write " + tmp_path)
	if not _replace(tmp_path, save_path):
		DirAccess.remove_absolute(tmp_path)
		return _fail("cannot replace " + save_path)
	last_error = ""
	saved.emit()
	return true


## Loads into `state` (default: the GameState autoload). Returns false, without
## touching `state`, on any missing, corrupt or too-new file.
func load_game(state: GameStateScript = null) -> bool:
	var gs: GameStateScript = _resolve(state)
	if gs == null:
		return _fail("no game state available")
	var game: Variant = _read_game()
	if game == null:
		return false
	gs.from_dict(game)
	last_error = ""
	return true


## Restores `state` from the save and returns the scene path of the map it was saved in; the map puts
## him at the saved respawn point. "" (state untouched) when there is no usable save or it names a map
## that does not exist. A save without a map id (an old one) means the default map.
func load_for_play(state: GameStateScript = null) -> String:
	var gs: GameStateScript = _resolve(state)
	if gs == null:
		_fail("no game state available")
		return ""
	var game: Variant = _read_game()
	if game == null:
		return ""
	var map_id: String = game["current_map"] if game.get("current_map") is String and game["current_map"] != "" \
		else MapCatalogScript.DEFAULT_MAP
	var path: String = MapCatalogScript.scene_path(map_id)
	if path == "":
		_fail("the save names an unknown map")
		return ""
	gs.from_dict(game)
	if gs.current_map == "":
		gs.current_map = map_id
	last_error = ""
	return path


## Loads the save and switches to its map (the debug key 0 does this; a main-menu button will).
## False, and nothing changes, when there is no usable save.
func continue_game() -> bool:
	var path: String = load_for_play()
	if path == "":
		return false
	get_tree().change_scene_to_file(path)
	return true


func has_save() -> bool:
	return FileAccess.file_exists(save_path)


## The "game" dictionary of the save file; null (last_error set) when it cannot be used.
func _read_game() -> Variant:
	if not FileAccess.file_exists(save_path):
		_fail("no save file")
		return null
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		_fail("cannot open " + save_path)
		return null
	if file.get_length() > MAX_SAVE_BYTES:
		file.close()
		_fail("save file too large")
		return null
	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		_fail("save file is not valid JSON")
		return null
	var root: Variant = json.data
	if not root is Dictionary:
		_fail("save file root is not an object")
		return null
	var version: Variant = root.get("save_version")
	if not (version is int or version is float):
		_fail("missing save_version")
		return null
	if int(version) > SAVE_VERSION:
		_fail("save_version %d is newer than supported %d" % [int(version), SAVE_VERSION])
		return null
	if int(version) < 1:
		_fail("invalid save_version")
		return null
	var game: Variant = root.get("game")
	if not game is Dictionary:
		_fail("missing game data")
		return null
	return game


## Moves `from` over `to`. Where a plain rename will not overwrite (Windows), the old file is moved
## aside first and put back if the new one cannot be moved in, so a failure never loses the old save.
func _replace(from: String, to: String) -> bool:
	if DirAccess.rename_absolute(from, to) == OK:
		return true
	if not FileAccess.file_exists(to):
		return false
	var backup: String = to + ".bak"
	DirAccess.remove_absolute(backup)
	if DirAccess.rename_absolute(to, backup) != OK:
		return false
	if DirAccess.rename_absolute(from, to) != OK:
		DirAccess.rename_absolute(backup, to)
		return false
	DirAccess.remove_absolute(backup)
	return true


func _resolve(state: GameStateScript) -> GameStateScript:
	if state != null:
		return state
	return get_node_or_null("/root/GameState") as GameStateScript


func _fail(message: String) -> bool:
	last_error = message
	push_warning("SaveSystem: " + message)
	return false
