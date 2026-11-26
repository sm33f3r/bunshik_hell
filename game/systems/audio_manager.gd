extends Node
## Autoload "AudioManager": one music player on the Music bus and a small pool of one-shot players on
## the SFX bus. Runs while the tree is paused (process_mode ALWAYS). Loads nothing by itself; the
## caller hands it streams. Bus volume and mute belong to Settings, not to this node: fades only
## change the music player's own volume.

enum Fade { NONE, IN, OUT }

const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
## How many sound effects can play at once. One more takes over the oldest.
const SFX_POOL_SIZE: int = 8
const SILENT_DB: float = -80.0

## The running fade, readable by tests and tools.
var fade_state: Fade = Fade.NONE
var fade_elapsed: float = 0.0
var fade_duration: float = 0.0
## The music player's own level, linear: 0.0 (silent) to 1.0 (full).
var music_gain: float = 1.0

var _fade_from: float = 1.0
var _music: AudioStreamPlayer
var _sfx: Array[AudioStreamPlayer] = []
## Pool indices, oldest start first.
var _sfx_order: Array[int] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	_music.finished.connect(_on_music_finished)
	add_child(_music)
	for i: int in SFX_POOL_SIZE:
		var player: AudioStreamPlayer = AudioStreamPlayer.new()
		player.bus = SFX_BUS
		add_child(player)
		_sfx.append(player)
		_sfx_order.append(i)


## Starts `stream` from the beginning, replacing whatever music was playing. A null stream does nothing.
func play_music(stream: AudioStream, fade_in_s: float = 0.0) -> void:
	if stream == null or _music == null:
		return
	_music.stop()
	_music.stream = stream
	if fade_in_s > 0.0:
		_set_gain(0.0)
		_start_fade(Fade.IN, fade_in_s)
	else:
		_end_fade()
		_set_gain(1.0)
	_music.play()


## Stops the music, now or after fading from its current level. Does nothing if none is playing.
func stop_music(fade_out_s: float = 0.0) -> void:
	if current_stream() == null:
		return
	if fade_out_s > 0.0:
		_start_fade(Fade.OUT, fade_out_s)
	else:
		_stop_now()


## True while music is audible, including during a fade-out.
func is_music_playing() -> bool:
	return _music != null and _music.playing


## The music stream being played, or null.
func current_stream() -> AudioStream:
	return _music.stream if _music != null else null


## Moves the running fade on by `delta` seconds. _process() calls it; tests may call it directly.
func advance_fade(delta: float) -> void:
	if fade_state == Fade.NONE:
		return
	fade_elapsed = minf(fade_elapsed + delta, fade_duration)
	var target: float = 1.0 if fade_state == Fade.IN else 0.0
	_set_gain(lerpf(_fade_from, target, fade_elapsed / fade_duration))
	if fade_elapsed >= fade_duration:
		if fade_state == Fade.OUT:
			_stop_now()
		else:
			_end_fade()


## Plays a one-shot and returns the player used, or null for a null stream.
func play_sfx(stream: AudioStream, volume_db: float = 0.0) -> AudioStreamPlayer:
	if stream == null or _sfx.is_empty():
		return null
	var slot: int = _sfx_order[0] # the oldest: taken over if none is free
	for i: int in _sfx_order:
		if not _sfx[i].playing:
			slot = i
			break
	_sfx_order.erase(slot)
	_sfx_order.append(slot)
	var player: AudioStreamPlayer = _sfx[slot]
	player.stop()
	player.stream = stream
	player.volume_db = volume_db
	player.play()
	return player


func _process(delta: float) -> void:
	advance_fade(delta)


func _start_fade(state: Fade, duration: float) -> void:
	fade_state = state
	fade_duration = duration
	fade_elapsed = 0.0
	_fade_from = music_gain


func _end_fade() -> void:
	fade_state = Fade.NONE
	fade_elapsed = 0.0
	fade_duration = 0.0


func _set_gain(gain: float) -> void:
	music_gain = clampf(gain, 0.0, 1.0)
	_music.volume_db = SILENT_DB if music_gain <= 0.0 else linear_to_db(music_gain)


func _stop_now() -> void:
	_end_fade()
	_music.stop()
	_music.stream = null
	_set_gain(1.0)


func _on_music_finished() -> void:
	_stop_now()
