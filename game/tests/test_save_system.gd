extends "res://tests/base_test.gd"

const GameStateScript := preload("res://systems/game_state.gd")
const SaveSystemScript := preload("res://systems/save_system.gd")
const TEMP_DIR := "user://test_tmp"


func _new_save() -> SaveSystemScript:
	var s := SaveSystemScript.new()
	s.save_path = TEMP_DIR + "/slot_test.json"
	return s


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _cleanup(s: SaveSystemScript) -> void:
	DirAccess.remove_absolute(s.save_path)
	DirAccess.remove_absolute(TEMP_DIR)
	s.free()


func test_file_round_trip() -> void:
	var s := _new_save()
	var a := GameStateScript.new()
	a.take_damage(6)
	a.add_sodium(3)
	a.unlock_skill("sauce_spin")
	check(s.save_game(a), "save ok")
	var b := GameStateScript.new()
	check(s.load_game(b), "load ok: " + s.last_error)
	check_eq(b.hearts, 8, "hearts")
	check_eq(b.sodium, 3, "sodium")
	check(b.has_skill("sauce_spin"), "skill")
	a.free()
	b.free()
	_cleanup(s)


func test_rejects_higher_save_version() -> void:
	var s := _new_save()
	_write(s.save_path, JSON.stringify({"save_version": 2, "game": {"hearts": 2}}))
	var gs := GameStateScript.new()
	check(not s.load_game(gs), "higher version refused")
	check_eq(gs.hearts, 14, "state untouched")
	gs.free()
	_cleanup(s)


func test_bad_files_never_crash() -> void:
	var s := _new_save()
	var gs := GameStateScript.new()
	check(not s.load_game(gs), "missing file")
	var bad_files: Array[String] = [
		"",
		"not json {",
		"[1,2,3]",
		"{}",
		'{"save_version": "x"}',
		'{"save_version": 1}',
		'{"save_version": 0, "game": {}}',
	]
	for text: String in bad_files:
		_write(s.save_path, text)
		check(not s.load_game(gs), "bad file refused: " + text)
	check_eq(gs.hearts, 14, "state untouched by bad files")
	gs.free()
	_cleanup(s)


func test_unknown_keys_ignored() -> void:
	var s := _new_save()
	_write(s.save_path, JSON.stringify({"save_version": 1, "future": true, "game": {"hearts": 4, "zzz": 1}}))
	var gs := GameStateScript.new()
	check(s.load_game(gs), "load ok")
	check_eq(gs.hearts, 4, "hearts loaded")
	gs.free()
	_cleanup(s)
