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
