extends Node
## DEBUG-ONLY keys for the test room. Active only when OS.is_debug_build().
## Not in the input map on purpose.
## Number row: 1 unlock roll + slam, 2 relock them, 3 respawn all dummies, 4 take 1 heart.
## Matched by physical key position so it works on any keyboard layout.

const GameStateScript := preload("res://systems/game_state.gd")

var _game_state: GameStateScript


func _ready() -> void:
	set_process_unhandled_key_input(OS.is_debug_build())
	_game_state = get_node_or_null("/root/GameState") as GameStateScript


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build() or _game_state == null:
		return
	var key: InputEventKey = event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	match key.physical_keycode:
		KEY_1:
			_game_state.unlock_skill("roll")
			_game_state.unlock_skill("slam")
		KEY_2:
			_game_state.skills["roll"] = false
			_game_state.skills["slam"] = false
		KEY_3:
			get_tree().call_group("enemies", "reset")
		KEY_4:
			_game_state.take_damage(2)
