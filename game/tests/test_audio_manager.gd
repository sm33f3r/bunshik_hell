extends "res://tests/base_test.gd"
## Task A1: AudioManager (fresh instances) and the M / N debug audition keys, with real key events.
## Streams are generated here: no asset is needed.

const AudioManagerScript := preload("res://systems/audio_manager.gd")
const DebugKeysScript := preload("res://maps/test/debug_keys.gd")
const SCENES: Array[String] = ["res://maps/ep01/map01_bunsikjip/map01.tscn", "res://maps/test/test_room.tscn"]

var _nodes: Array[Node] = []


func after_each() -> void:
	tree.paused = false
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


## A fresh manager whose fades only move when the test says so.
func _manager(manual: bool = true) -> AudioManagerScript:
	var manager: AudioManagerScript = AudioManagerScript.new()
	tree.root.add_child(manager)
	_nodes.append(manager)
	await tree.process_frame # the first suite can run before the tree has started
	manager.set_process(not manual)
	return manager


## Ten seconds of silence.
func _stream() -> AudioStreamWAV:
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	var data: PackedByteArray = PackedByteArray()
	data.resize(10 * 8000)
	wav.format = AudioStreamWAV.FORMAT_8_BITS
	wav.mix_rate = 8000
	wav.data = data
	return wav


func _players(manager: AudioManagerScript, bus: StringName) -> Array[AudioStreamPlayer]:
	var out: Array[AudioStreamPlayer] = []
	for node: Node in manager.get_children():
		var player: AudioStreamPlayer = node as AudioStreamPlayer
		if player != null and player.bus == bus:
			out.append(player)
	return out


func test_it_is_registered_right_after_settings_and_starts_empty() -> void:
	var names: Array[String] = []
	for property: Dictionary in ProjectSettings.get_property_list():
		if String(property["name"]).begins_with("autoload/"):
			names.append(String(property["name"]).trim_prefix("autoload/"))
	check_eq(names.find("AudioManager"), names.find("Settings") + 1, "after Settings: %s" % str(names))
	var manager: AudioManagerScript = await _manager()
	check_eq(manager.process_mode, Node.PROCESS_MODE_ALWAYS, "runs while paused")
	check(manager.current_stream() == null and not manager.is_music_playing(), "nothing loaded")
	check_eq(_players(manager, &"Music").size(), 1, "one music player on Music")
	check_eq(_players(manager, &"SFX").size(), AudioManagerScript.SFX_POOL_SIZE, "the pool is on SFX")
	for player: AudioStreamPlayer in _players(manager, &"SFX"):
		check(player.stream == null, "no stream at startup")


func test_play_and_stop_without_a_fade() -> void:
	var manager: AudioManagerScript = await _manager()
	var stream: AudioStreamWAV = _stream()
	manager.play_music(stream)
	check(manager.is_music_playing(), "playing")
	check(manager.current_stream() == stream, "and it is that stream")
	check_eq(manager.fade_state, AudioManagerScript.Fade.NONE, "no fade")
	check_eq(manager.music_gain, 1.0, "full")
	manager.stop_music()
	check(not manager.is_music_playing() and manager.current_stream() == null, "stopped")


func test_fade_in_and_fade_out_are_deterministic() -> void:
	var manager: AudioManagerScript = await _manager()
	var player: AudioStreamPlayer = _players(manager, &"Music")[0]
	manager.play_music(_stream(), 2.0)
	check_eq(manager.fade_state, AudioManagerScript.Fade.IN, "fading in")
	check_eq(manager.fade_duration, 2.0, "over 2 s")
	check_eq(manager.music_gain, 0.0, "from silence")
	check(is_equal_approx(player.volume_db, -80.0), "-80 dB")
	manager.advance_fade(0.5)
	check_eq(manager.fade_elapsed, 0.5, "elapsed")
	check(is_equal_approx(manager.music_gain, 0.25), "a quarter of the way")
	check(is_equal_approx(player.volume_db, linear_to_db(0.25)), "on the player")
	manager.advance_fade(5.0)
	check_eq(manager.fade_state, AudioManagerScript.Fade.NONE, "done")
	check_eq(manager.music_gain, 1.0, "full")
	manager.stop_music(1.0)
	check_eq(manager.fade_state, AudioManagerScript.Fade.OUT, "fading out")
	manager.advance_fade(0.5)
	check(is_equal_approx(manager.music_gain, 0.5), "half")
	check(manager.is_music_playing(), "still playing during the fade")
	manager.advance_fade(0.5)
	check(not manager.is_music_playing() and manager.current_stream() == null, "stopped at the end")
	check_eq(manager.fade_state, AudioManagerScript.Fade.NONE, "no fade left")


func test_a_fade_out_starts_from_where_a_fade_in_got_to() -> void:
	var manager: AudioManagerScript = await _manager()
	manager.play_music(_stream(), 1.0)
	manager.advance_fade(0.5)
	manager.stop_music(1.0)
	manager.advance_fade(0.5)
	check(is_equal_approx(manager.music_gain, 0.25), "half of a half")
	manager.play_music(_stream())
	check_eq(manager.fade_state, AudioManagerScript.Fade.NONE, "a new play cancels the fade")
	check_eq(manager.music_gain, 1.0, "at full")


func test_null_streams_are_safe() -> void:
	var manager: AudioManagerScript = await _manager()
	manager.play_music(null, 1.0)
	manager.stop_music(1.0)
	manager.stop_music()
	check(not manager.is_music_playing(), "nothing plays")
	check_eq(manager.fade_state, AudioManagerScript.Fade.NONE, "no fade")
	check(manager.play_sfx(null) == null, "no sfx")
	var stream: AudioStreamWAV = _stream()
	manager.play_music(stream)
	manager.play_music(null)
	check(manager.current_stream() == stream, "null leaves the music alone")


func test_the_sfx_pool_is_capped_and_reuses_the_oldest() -> void:
	var manager: AudioManagerScript = await _manager()
	var used: Array[AudioStreamPlayer] = []
	for i: int in AudioManagerScript.SFX_POOL_SIZE:
		var player: AudioStreamPlayer = manager.play_sfx(_stream(), -6.0)
		check(player != null and player not in used, "player %d is a new one" % i)
		check(player.playing and player.bus == &"SFX" and is_equal_approx(player.volume_db, -6.0), "playing on SFX")
		used.append(player)
	check(manager.play_sfx(_stream()) == used[0], "the ninth takes the oldest")
	check(manager.play_sfx(_stream()) == used[1], "then the next oldest")
	check_eq(_players(manager, &"SFX").size(), AudioManagerScript.SFX_POOL_SIZE, "the pool did not grow")


func test_it_keeps_working_while_the_tree_is_paused() -> void:
	var manager: AudioManagerScript = await _manager(false)
	tree.paused = true
	manager.play_music(_stream(), 30.0)
	for i: int in 10:
		await tree.process_frame
	check(manager.fade_elapsed > 0.0, "the fade moves while paused")
	check(manager.is_music_playing(), "music plays")
	check(manager.can_process(), "can process")
	check(manager.play_sfx(_stream()) != null, "sfx plays")


# --- Debug audition keys ---------------------------------------------------------------------------

func _tap(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event: InputEventKey = InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await tree.process_frame


## A playlist made here, so the test does not depend on the untracked music files.
func _temp_playlist() -> String:
	var path: String = "user://test_playlist_tmp.tres"
	var playlist: AudioStreamPlaylist = AudioStreamPlaylist.new()
	playlist.stream_count = 1
	playlist.set_list_stream(0, _stream())
	ResourceSaver.save(playlist, path)
	return path


func test_the_beep_is_generated_pcm() -> void:
	var beep: AudioStreamWAV = DebugKeysScript.make_beep()
	check_eq(beep.format, AudioStreamWAV.FORMAT_16_BITS, "16 bit")
	check(absf(beep.get_length() - DebugKeysScript.BEEP_SECONDS) < 0.001, "short")
	var peak: int = 0
	for i: int in range(0, beep.data.size(), 2):
		peak = maxi(peak, absi(beep.data.decode_s16(i)))
	check(peak > 10000 and peak < 16000, "audible and not clipping: %d" % peak)


func test_m_and_n_work_in_map_1_and_the_test_room_also_while_paused() -> void:
	var path: String = _temp_playlist()
	for scene_path: String in SCENES:
		var manager: AudioManagerScript = await _manager()
		var scene: Node = (load(scene_path) as PackedScene).instantiate()
		var keys: Node = scene.get_node("DebugKeys")
		keys.set("audio_manager", manager)
		keys.set("playlist_path", path) # our own file in user://, written just above
		tree.root.add_child(scene)
		_nodes.append(scene)
		await tree.process_frame
		await _tap(KEY_M)
		check(manager.is_music_playing(), "M starts the music: " + scene_path)
		check(manager.current_stream() is AudioStreamPlaylist, "the playlist")
		await _tap(KEY_M)
		check(not manager.is_music_playing(), "M stops it")
		tree.paused = true
		await _tap(KEY_N)
		var beeping: int = 0
		for player: AudioStreamPlayer in _players(manager, &"SFX"):
			if player.stream is AudioStreamWAV:
				beeping += 1
		check_eq(beeping, 1, "N beeps on SFX while paused")
		await _tap(KEY_M)
		check(manager.is_music_playing(), "M works while paused")
		var gs: Node = tree.root.get_node("GameState")
		var hearts: int = gs.hearts
		await _tap(KEY_4)
		check_eq(gs.hearts, hearts, "the other debug keys still do nothing while paused")
		tree.paused = false
		gs.call("reset")
		scene.free()
		manager.free()
	DirAccess.remove_absolute(path)


func test_a_missing_playlist_does_nothing() -> void:
	var manager: AudioManagerScript = await _manager()
	var keys: Node = DebugKeysScript.new()
	keys.set("audio_manager", manager)
	keys.set("playlist_path", "res://audio/music/no_such_playlist.tres")
	tree.root.add_child(keys)
	_nodes.append(keys)
	await _tap(KEY_M)
	check(not manager.is_music_playing() and manager.current_stream() == null, "nothing happens")


func test_the_default_playlist_path() -> void:
	check_eq(DebugKeysScript.PLAYLIST_PATH, "res://audio/music/ep1-lunch-playlist.tres", "path")
