extends "res://tests/base_test.gd"

const SettingsScript := preload("res://systems/settings.gd")
const TEMP_PATH := "user://test_settings_tmp.json"


func test_defaults() -> void:
	var s := SettingsScript.new()
	check_eq(s.heal_default, "lowest", "heal_default")
	check_eq(s.on_chain, false, "on_chain")
	check_eq(SettingsScript.ON_CHAIN_AVAILABLE, false, "on-chain unavailable")
	s.free()


func test_on_chain_refused() -> void:
	var s := SettingsScript.new()
	check_eq(s.set_on_chain(true), false, "set true refused")
	check_eq(s.on_chain, false, "stays false")
	check_eq(s.set_on_chain(false), true, "set false ok")
	s.free()


func test_file_round_trip_and_refusal_from_file() -> void:
	var s := SettingsScript.new()
	s.settings_path = TEMP_PATH
	s.set_heal_default("highest")
	check(s.save_settings(), "save")
	var t := SettingsScript.new()
	t.settings_path = TEMP_PATH
	check(t.load_settings(), "load")
	check_eq(t.heal_default, "highest", "heal_default restored")
	# A hand-edited file asking for on-chain must not turn it on.
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	f.store_string('{"on_chain": true, "unknown": 1}')
	f.close()
	t.load_settings()
	check_eq(t.on_chain, false, "on_chain from file refused")
	DirAccess.remove_absolute(TEMP_PATH)
	s.free()
	t.free()


func test_fullscreen_and_volume_defaults_and_clamping() -> void:
	var s := SettingsScript.new()
	check_eq(s.fullscreen, false, "windowed by default")
	check_eq(s.master_volume, 1.0, "full volume by default")
	s.set_master_volume(1.7)
	check_eq(s.master_volume, 1.0, "clamped to 1")
	s.set_master_volume(-3.0)
	check_eq(s.master_volume, 0.0, "clamped to 0")
	s.free()


func test_fullscreen_volume_and_heal_default_round_trip() -> void:
	var s := SettingsScript.new()
	s.settings_path = TEMP_PATH
	s.set_fullscreen(true)
	s.set_master_volume(0.4)
	s.set_heal_default("ggul")
	check(s.save_settings(), "save")
	var t := SettingsScript.new()
	t.settings_path = TEMP_PATH
	check(t.load_settings(), "load")
	check_eq(t.fullscreen, true, "fullscreen restored")
	check(absf(t.master_volume - 0.4) < 0.0001, "volume restored")
	check_eq(t.heal_default, "ggul", "heal default restored")
	DirAccess.remove_absolute(TEMP_PATH)
	s.free()
	t.free()


func test_a_bad_settings_file_keeps_the_defaults() -> void:
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	f.store_string('{"fullscreen": "yes", "master_volume": "loud"}')
	f.close()
	var t := SettingsScript.new()
	t.settings_path = TEMP_PATH
	t.load_settings()
	check_eq(t.fullscreen, false, "a non-bool fullscreen is ignored")
	check_eq(t.master_volume, 1.0, "a non-number volume is ignored")
	DirAccess.remove_absolute(TEMP_PATH)
	t.free()


func test_the_heal_default_cycles_through_lowest_and_every_item() -> void:
	var s := SettingsScript.new()
	var choices: Array[String] = s.heal_default_choices()
	check_eq(choices[0], "lowest", "lowest first")
	check(choices.size() >= 4 and choices.has("kongomul") and choices.has("jocheong") and choices.has("ggul"), "and the three items")
	for i: int in choices.size():
		check_eq(s.heal_default, choices[i], "step %d" % i)
		s.cycle_heal_default(1)
	check_eq(s.heal_default, "lowest", "wraps around")
	s.cycle_heal_default(-1)
	check_eq(s.heal_default, choices[choices.size() - 1], "and backwards")
	s.free()
