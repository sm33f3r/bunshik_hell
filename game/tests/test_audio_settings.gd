extends "res://tests/base_test.gd"
## Task A1: the Music / SFX settings, the bus layout and apply_to_system().

const SettingsScript := preload("res://systems/settings.gd")
const TEMP_PATH := "user://test_audio_settings_tmp.json"
const BUSES: Array[String] = ["Master", "Music", "SFX"]

var _buses: AudioBusLayout


func after_each() -> void:
	if _buses != null:
		AudioServer.set_bus_layout(_buses)
		_buses = null
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(TEMP_PATH)


func _write(text: String) -> void:
	var f := FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _loaded() -> SettingsScript:
	var s := SettingsScript.new()
	s.settings_path = TEMP_PATH
	s.load_settings()
	return s


func test_defaults_and_clamping() -> void:
	var s := SettingsScript.new()
	check_eq(s.music_volume, 1.0, "music full by default")
	check_eq(s.sfx_volume, 1.0, "sfx full by default")
	check_eq(s.music_enabled, true, "music on by default")
	check_eq(s.sfx_enabled, true, "sfx on by default")
	s.set_music_volume(1.5)
	s.set_sfx_volume(-1.0)
	check_eq(s.music_volume, 1.0, "clamped to 1")
	check_eq(s.sfx_volume, 0.0, "clamped to 0")
	s.set_music_volume(-0.2)
	s.set_sfx_volume(9.0)
	check_eq(s.music_volume, 0.0, "music clamped to 0")
	check_eq(s.sfx_volume, 1.0, "sfx clamped to 1")
	s.free()


func test_round_trip() -> void:
	var s := SettingsScript.new()
	s.settings_path = TEMP_PATH
	s.set_music_volume(0.3)
	s.set_sfx_volume(0.7)
	s.set_music_enabled(false)
	s.set_sfx_enabled(false)
	check(s.save_settings(), "save")
	var t: SettingsScript = _loaded()
	check(absf(t.music_volume - 0.3) < 0.0001, "music volume")
	check(absf(t.sfx_volume - 0.7) < 0.0001, "sfx volume")
	check_eq(t.music_enabled, false, "music off")
	check_eq(t.sfx_enabled, false, "sfx off")
	s.free()
	t.free()


func test_bad_types_and_unknown_keys_are_ignored_and_numbers_are_clamped() -> void:
	_write('{"music_volume": "loud", "sfx_volume": true, "music_enabled": "no", "sfx_enabled": 0, "voice_volume": 0.1}')
	var t: SettingsScript = _loaded()
	check_eq(t.music_volume, 1.0, "string volume ignored")
	check_eq(t.sfx_volume, 1.0, "bool volume ignored")
	check_eq(t.music_enabled, true, "string flag ignored")
	check_eq(t.sfx_enabled, true, "number flag ignored")
	check(not t.to_dict().has("voice_volume"), "unknown key not kept")
	t.free()
	_write('{"music_volume": 5, "sfx_volume": -2}')
	t = _loaded()
	check_eq(t.music_volume, 1.0, "int clamped high")
	check_eq(t.sfx_volume, 0.0, "int clamped low")
	t.free()


func test_an_oversized_file_is_refused() -> void:
	_write('{"music_enabled": false, "pad": "%s"}' % "x".repeat(SettingsScript.MAX_FILE_BYTES))
	var t := SettingsScript.new()
	t.settings_path = TEMP_PATH
	check_eq(t.load_settings(), false, "refused")
	check_eq(t.music_enabled, true, "unchanged")
	t.free()


func test_the_bus_layout_has_master_music_and_sfx() -> void:
	for bus_name: String in BUSES:
		check(AudioServer.get_bus_index(bus_name) >= 0, bus_name + " exists")
	check_eq(AudioServer.bus_count, 3, "and no other bus")
	for bus_name: String in ["Music", "SFX"]:
		check_eq(String(AudioServer.get_bus_send(AudioServer.get_bus_index(bus_name))), "Master", bus_name + " sends to Master")


func test_apply_to_system_sets_volume_and_mute_on_the_right_buses() -> void:
	_buses = AudioServer.generate_bus_layout()
	var s := SettingsScript.new()
	s.set_master_volume(0.5)
	s.set_music_volume(0.25)
	s.set_sfx_volume(0.0)
	s.set_music_enabled(false)
	s.apply_to_system()
	var master: int = AudioServer.get_bus_index("Master")
	var music: int = AudioServer.get_bus_index("Music")
	var sfx: int = AudioServer.get_bus_index("SFX")
	check(is_equal_approx(AudioServer.get_bus_volume_db(master), linear_to_db(0.5)), "master volume")
	check(is_equal_approx(AudioServer.get_bus_volume_db(music), linear_to_db(0.25)), "music volume")
	check(is_equal_approx(AudioServer.get_bus_volume_db(sfx), -80.0), "0 is -80 dB")
	check(AudioServer.is_bus_mute(music), "music muted")
	check(not AudioServer.is_bus_mute(sfx), "sfx not muted")
	s.set_music_enabled(true)
	s.set_sfx_enabled(false)
	s.apply_to_system()
	check(not AudioServer.is_bus_mute(music), "music unmuted")
	check(AudioServer.is_bus_mute(sfx), "sfx muted")
	s.free()


func test_apply_to_system_survives_missing_buses() -> void:
	_buses = AudioServer.generate_bus_layout()
	AudioServer.remove_bus(AudioServer.get_bus_index("SFX"))
	AudioServer.remove_bus(AudioServer.get_bus_index("Music"))
	var s := SettingsScript.new()
	s.set_master_volume(0.5)
	s.set_music_enabled(false)
	s.apply_to_system()
	check_eq(AudioServer.bus_count, 1, "only Master left")
	check(is_equal_approx(AudioServer.get_bus_volume_db(0), linear_to_db(0.5)), "Master still applied")
	check(not AudioServer.is_bus_mute(0), "a missing bus never mutes another")
	s.free()
