extends Node
## DEBUG-ONLY keys for the test room. Active only when OS.is_debug_build().
## Not in the input map on purpose.
## Number row: 1 unlock roll + slam, 2 relock them and the flick, 3 respawn all dummies,
## 4 take 1 heart, 5 unlock the sauce flick, 6 defeat the noodle (라면) dummy,
## 7 give the starter container, 0 load the save and go to its map, 9 show / hide the debug HUD text, 8 finish the Map 1 prologue (Map 1 only). 2 also clears the container, items and coat; 3 also
## respawns item pickups, 나트륨 pickups, usable objects and 참기름 smudges, and removes
## dropped loot and water sheets. 6 defeats every 라면 dummy.
## Audio audition: M starts / stops the lunch playlist on the Music bus, N plays a short generated beep
## on the SFX bus. These two also work while the game is paused (to hear the Audio page's sliders);
## every other key here does nothing then.
## Matched by physical key position so it works on any keyboard layout.

const GameStateScript := preload("res://systems/game_state.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const AudioManagerScript := preload("res://systems/audio_manager.gd")

const NOODLE_DUMMY_ID: String = "noodle_dummy"
const STARTER_CONTAINER_ID: String = "starter_container"
const PLAYLIST_PATH: String = "res://audio/music/ep1-lunch-playlist.tres"
const BEEP_MIX_RATE: int = 22050
const BEEP_SECONDS: float = 0.2
const BEEP_HZ: float = 880.0

## Injected by tests; fall back to the autoload / PLAYLIST_PATH.
var audio_manager: AudioManagerScript
var playlist_path: String = PLAYLIST_PATH

var _game_state: GameStateScript


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_unhandled_key_input(OS.is_debug_build())
	_game_state = get_node_or_null("/root/GameState") as GameStateScript
	if audio_manager == null:
		audio_manager = get_node_or_null("/root/AudioManager") as AudioManagerScript


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or _game_state == null:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_M:
			_toggle_music()
			return
		KEY_N:
			if audio_manager != null:
				audio_manager.play_sfx(make_beep())
			return
	if is_inside_tree() and get_tree().paused:
		return
	match key.physical_keycode:
		KEY_1:
			_game_state.unlock_skill("roll")
			_game_state.unlock_skill("slam")
		KEY_2:
			_game_state.skills["roll"] = false
			_game_state.skills["slam"] = false
			_game_state.skills["sauce_flick"] = false
			# Forget past defeats too, so key 6 can exercise the first-defeat unlock again.
			_game_state.defeated_enemies.clear()
			_game_state.clear_inventory()
		KEY_3:
			get_tree().call_group("enemies", "reset")
			get_tree().call_group("item_pickups", "reset")
			get_tree().call_group("oil_smudges", "reset")
			get_tree().call_group("natrium_pickups", "reset")
			get_tree().call_group("usable_objects", "reset")
			get_tree().call_group("dropped_loot", "queue_free")
			get_tree().call_group("water_sheets", "queue_free")
		KEY_4:
			_game_state.take_damage(2)
		KEY_5:
			_game_state.unlock_skill("sauce_flick")
		KEY_7:
			_game_state.try_equip_container(STARTER_CONTAINER_ID)
		KEY_8:
			# Map 1 only: finish the prologue instantly. Nothing happens in the test room.
			get_tree().call_group("prologue_map", "debug_finish")
		KEY_9:
			get_tree().call_group("debug_hud", "toggle_visible")
		KEY_0:
			# Load the save: its state, its map, the saved respawn point. Nothing happens without a save.
			var saves: Node = get_node_or_null("/root/SaveSystem")
			if saves != null:
				saves.call_deferred("continue_game")
		KEY_6:
			for node: Node in get_tree().get_nodes_in_group("enemies"):
				var enemy: EnemyBaseScript = node as EnemyBaseScript
				if enemy != null and enemy.def != null and enemy.def.id == NOODLE_DUMMY_ID:
					enemy.debug_defeat()


func _toggle_music() -> void:
	if audio_manager == null:
		return
	if audio_manager.is_music_playing():
		audio_manager.stop_music()
		print("Debug audio: music stopped.")
		return
	if not ResourceLoader.exists(playlist_path):
		print("Debug audio: no playlist at %s" % playlist_path)
		return
	var playlist: AudioStreamPlaylist = load(playlist_path) as AudioStreamPlaylist
	if playlist == null:
		print("Debug audio: %s is not an AudioStreamPlaylist" % playlist_path)
		return
	audio_manager.play_music(playlist)
	print("Debug audio: playing %s  stream_count=%d  loop=%s  fade_time=%s" % [
		playlist_path.get_file(), playlist.stream_count, playlist.loop, playlist.fade_time])


## A short sine tone built from 16-bit mono PCM, with 10 ms ramps so it does not click.
static func make_beep() -> AudioStreamWAV:
	var count: int = int(BEEP_MIX_RATE * BEEP_SECONDS)
	var ramp: float = BEEP_MIX_RATE * 0.01
	var data: PackedByteArray = PackedByteArray()
	data.resize(count * 2)
	for i: int in count:
		var envelope: float = minf(1.0, minf(i, count - 1 - i) / ramp)
		var sample: float = sin(TAU * BEEP_HZ * i / BEEP_MIX_RATE) * 0.4 * envelope
		data.encode_s16(i * 2, int(sample * 32767.0))
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = BEEP_MIX_RATE
	wav.data = data
	return wav
