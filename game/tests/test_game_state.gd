extends "res://tests/base_test.gd"

const GameStateScript := preload("res://systems/game_state.gd")


func _new() -> GameStateScript:
	return GameStateScript.new()


func test_starting_values() -> void:
	var gs := _new()
	check_eq(gs.hearts, 14, "start hearts")
	check_eq(gs.sauce, 3, "start sauce")
	check_eq(gs.sodium, 0, "start sodium")
	check_eq(gs.inventory_capacity, 0, "inventory capacity")
	check_eq(gs.items.size(), 0, "items empty")
	gs.free()


func test_caps_and_clamping() -> void:
	var gs := _new()
	gs.heal(100)
	check_eq(gs.hearts, 14, "hearts cap")
	gs.take_damage(100)
	check_eq(gs.hearts, 0, "hearts floor")
	gs.add_sauce(100)
	check_eq(gs.sauce, 7, "sauce cap")
	gs.add_sodium(100)
	check_eq(gs.sodium, 7, "sodium cap")
	gs.add_sauce(-5)
	gs.take_damage(-5)
	check_eq(gs.sauce, 7, "negative add ignored")
	check_eq(gs.hearts, 0, "negative damage ignored")
	gs.free()


func test_spend_failure_changes_nothing() -> void:
	var gs := _new()
	check_eq(gs.spend_sauce(4), false, "spend too much sauce")
	check_eq(gs.sauce, 3, "sauce unchanged")
	check_eq(gs.spend_sodium(1), false, "spend sodium with none")
	check_eq(gs.sodium, 0, "sodium unchanged")
	check_eq(gs.spend_sauce(-1), false, "negative spend refused")
	check_eq(gs.spend_sauce(3), true, "spend exact sauce")
	check_eq(gs.sauce, 0, "sauce spent")
	gs.add_sodium(2)
	check_eq(gs.spend_sodium(2), true, "spend sodium")
	check_eq(gs.sodium, 0, "sodium spent")
	gs.free()


func test_death_signal_at_zero_hearts() -> void:
	var gs := _new()
	var deaths: Array[int] = []
	gs.died.connect(func() -> void: deaths.append(1))
	gs.take_damage(13)
	check_eq(deaths.size(), 0, "no death at 1 half-heart")
	gs.take_damage(1)
	check_eq(gs.hearts, 0, "hearts at 0")
	check_eq(deaths.size(), 1, "death emitted once")
	gs.take_damage(5)
	check_eq(deaths.size(), 1, "no second death signal")
	gs.free()


func test_change_signals() -> void:
	var gs := _new()
	var log: Array[String] = []
	gs.hearts_changed.connect(func(_h: int, _m: int) -> void: log.append("hearts"))
	gs.sauce_changed.connect(func(_s: int, _m: int) -> void: log.append("sauce"))
	gs.sodium_changed.connect(func(_s: int, _m: int) -> void: log.append("sodium"))
	gs.take_damage(2)
	gs.add_sauce(1)
	gs.add_sodium(1)
	gs.spend_sauce(1)
	gs.spend_sodium(1)
	check_eq(log, ["hearts", "sauce", "sodium", "sauce", "sodium"] as Array[String], "signal sequence")
	var before: int = log.size()
	gs.heal(0)
	gs.spend_sauce(99)
	check_eq(log.size(), before, "no signal without change")
	gs.free()


func test_starting_skills() -> void:
	var gs := _new()
	for id: String in ["move", "jump", "landing", "stomp"]:
		check(gs.has_skill(id), "%s unlocked at start" % id)
	for id: String in ["roll", "slam", "sauce_flick", "double_jump", "sauce_spin", "sauce_sniper"]:
		check(not gs.has_skill(id), "%s locked at start" % id)
	check(gs.unlock_skill("roll"), "unlock roll")
	check(gs.has_skill("roll"), "roll now unlocked")
	check(not gs.unlock_skill("nonsense"), "unknown skill refused")
	check(not gs.has_skill("nonsense"), "unknown skill not present")
	gs.free()


func test_dict_round_trip() -> void:
	var a := _new()
	a.take_damage(5)
	a.add_sauce(2)
	a.add_sodium(4)
	a.unlock_skill("double_jump")
	a.items.append("pick_01")
	var data: Dictionary = JSON.parse_string(JSON.stringify(a.to_dict()))  # via real JSON
	var b := _new()
	b.from_dict(data)
	check_eq(b.hearts, 9, "hearts restored")
	check_eq(b.sauce, 5, "sauce restored")
	check_eq(b.sodium, 4, "sodium restored")
	check(b.has_skill("double_jump"), "skill restored")
	check(not b.has_skill("slam"), "locked skill still locked")
	check_eq(b.items.size(), 1, "items restored")
	a.free()
	b.free()


func test_from_dict_is_tolerant() -> void:
	var gs := _new()
	gs.from_dict({
		"hearts": 999,
		"sauce": "lots",
		"skills": {"roll": true, "made_up": true, "slam": "yes"},
		"items": ["ok", 5, null],
		"extra_key": 1,
	})
	check_eq(gs.hearts, 14, "hearts clamped")
	check_eq(gs.sauce, 3, "bad sauce falls back")
	check(gs.has_skill("roll"), "valid skill applied")
	check(not gs.has_skill("slam"), "bad skill type ignored")
	check(not gs.skills.has("made_up"), "unknown skill ignored")
	check_eq(gs.items.size(), 1, "only string items kept")
	gs.free()
