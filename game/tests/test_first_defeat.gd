extends "res://tests/base_test.gd"
## Skills unlocked by an enemy's first defeat, and what is saved (sauce, sauce type, defeats).

const GameStateScript := preload("res://systems/game_state.gd")
const SaveSystemScript := preload("res://systems/save_system.gd")
const StationaryScript := preload("res://enemies/stationary_dummy.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")

const TEMP_DIR := "user://test_tmp"


func _noodle(gs: GameStateScript) -> StationaryScript:
	var e: StationaryScript = StationaryScript.new()
	e.def = load("res://data/enemies/noodle_dummy.tres") as EnemyDefScript
	e.game_state = gs
	e.setup()
	return e


func _new_save() -> SaveSystemScript:
	var s: SaveSystemScript = SaveSystemScript.new()
	s.save_path = TEMP_DIR + "/slot_sauce_test.json"
	return s


func _cleanup(s: SaveSystemScript) -> void:
	DirAccess.remove_absolute(s.save_path)
	DirAccess.remove_absolute(TEMP_DIR)
	s.free()


func test_the_noodle_def_unlocks_the_flick() -> void:
	var def: EnemyDefScript = load("res://data/enemies/noodle_dummy.tres") as EnemyDefScript
	check_eq(def.unlocks_skill_on_first_defeat, &"sauce_flick", "field set in data")
	var soft: EnemyDefScript = load("res://data/enemies/soft_dummy.tres") as EnemyDefScript
	check_eq(soft.unlocks_skill_on_first_defeat, &"", "other enemies unlock nothing")


func test_first_defeat_unlocks_the_skill_once_only() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var unlocks: Array[String] = []
	gs.skill_unlocked.connect(func(id: String) -> void: unlocks.append(id))
	check(not gs.has_skill("sauce_flick"), "locked at the start")
	var first: StationaryScript = _noodle(gs)
	first.debug_defeat()
	check(gs.has_skill("sauce_flick"), "unlocked by the first defeat")
	check_eq(unlocks, ["sauce_flick"] as Array[String], "one unlock signal")
	check_eq(gs.defeated_enemies, ["noodle_dummy"] as Array[String], "defeat recorded")

	# Later defeats do nothing extra, even if the skill were locked again.
	gs.skills["sauce_flick"] = false
	var second: StationaryScript = _noodle(gs)
	second.debug_defeat()
	check(not gs.has_skill("sauce_flick"), "the second defeat does not unlock again")
	check_eq(unlocks.size(), 1, "still one unlock signal")
	check_eq(gs.defeated_enemies.size(), 1, "recorded once")
	first.free()
	second.free()
	gs.free()


func test_a_hit_that_does_not_kill_unlocks_nothing() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var e: StationaryScript = _noodle(gs)
	e.reaction_table = load("res://data/reaction_table.tres")
	for attack: String in ["roll", "slam", "sauce"]:
		e.receive_attack(attack)
	check(e.alive, "the noodle dummy survives everything in this task")
	check(not gs.has_skill("sauce_flick"), "so the flick stays locked")
	e.free()
	gs.free()


func test_an_enemy_with_no_unlock_field_is_still_recorded_and_unlocks_nothing() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var e: StationaryScript = StationaryScript.new()
	e.def = load("res://data/enemies/soft_dummy.tres") as EnemyDefScript
	e.game_state = gs
	e.setup()
	e.debug_defeat()
	check_eq(gs.defeated_enemies, ["soft_dummy"] as Array[String], "recorded")
	check(not gs.has_skill("sauce_flick"), "nothing unlocked")
	e.free()
	gs.free()


func test_unlock_and_defeats_survive_save_and_load() -> void:
	var s: SaveSystemScript = _new_save()
	var a: GameStateScript = GameStateScript.new()
	var e: StationaryScript = _noodle(a)
	e.debug_defeat()
	check(s.save_game(a), "save ok")
	var b: GameStateScript = GameStateScript.new()
	check(s.load_game(b), "load ok: " + s.last_error)
	check(b.has_skill("sauce_flick"), "the unlock was saved and loaded")
	check_eq(b.defeated_enemies, ["noodle_dummy"] as Array[String], "defeats saved and loaded")
	# ...and a second noodle after loading still does nothing extra.
	b.skills["sauce_flick"] = false
	var e2: StationaryScript = _noodle(b)
	e2.debug_defeat()
	check(not b.has_skill("sauce_flick"), "no second unlock after loading")
	e.free()
	e2.free()
	a.free()
	b.free()
	_cleanup(s)


func test_sauce_amount_and_type_survive_save_and_load() -> void:
	var s: SaveSystemScript = _new_save()
	var a: GameStateScript = GameStateScript.new()
	a.add_sauce(2)
	check_eq(a.sauce, 5, "5 sauce")
	check(s.save_game(a), "save ok")
	var b: GameStateScript = GameStateScript.new()
	b.sauce = 0
	b.sauce_type_id = "not_a_type"
	check(s.load_game(b), "load ok: " + s.last_error)
	check_eq(b.sauce, 5, "sauce amount restored")
	check_eq(b.sauce_type_id, "gochujang", "sauce type restored")
	a.free()
	b.free()
	_cleanup(s)


func test_save_version_is_unchanged_because_only_keys_were_added() -> void:
	check_eq(SaveSystemScript.SAVE_VERSION, 1, "still version 1")


func test_a_version_1_save_from_before_this_task_still_loads_with_defaults() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.from_dict({"hearts": 6, "sauce": 4, "skills": {"roll": true}})
	check_eq(gs.sauce, 4, "old keys still read")
	check_eq(gs.sauce_type_id, "gochujang", "missing sauce_type -> default")
	check_eq(gs.defeated_enemies.size(), 0, "missing defeated_enemies -> none")
	gs.from_dict({"sauce_type": 5, "defeated_enemies": ["a", 3, "", "a", null, "b"]})
	check_eq(gs.sauce_type_id, "gochujang", "wrong-typed sauce_type -> default")
	check_eq(gs.defeated_enemies, ["a", "b"] as Array[String], "bad entries dropped, duplicates merged")
	gs.from_dict({"sauce_type": "no_such_sauce"})
	check_eq(gs.sauce_type_id, "gochujang", "unknown sauce_type -> default")
	gs.free()
