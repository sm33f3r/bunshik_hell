extends Node
## DEBUG-ONLY keys for the test room. Active only when OS.is_debug_build().
## Not in the input map on purpose.
## Number row: 1 unlock roll + slam, 2 relock them and the flick, 3 respawn all dummies,
## 4 take 1 heart, 5 unlock the sauce flick, 6 defeat the noodle (라면) dummy,
## 7 give the starter container. 2 also clears the container, items and coat; 3 also
## respawns item pickups and 참기름 smudges.
## Matched by physical key position so it works on any keyboard layout.

const GameStateScript := preload("res://systems/game_state.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")

const NOODLE_DUMMY_ID: String = "noodle_dummy"
const STARTER_CONTAINER_ID: String = "starter_container"

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
			_game_state.skills["sauce_flick"] = false
			# Forget past defeats too, so key 6 can exercise the first-defeat unlock again.
			_game_state.defeated_enemies.clear()
			_game_state.clear_inventory()
		KEY_3:
			get_tree().call_group("enemies", "reset")
			get_tree().call_group("item_pickups", "reset")
			get_tree().call_group("oil_smudges", "reset")
		KEY_4:
			_game_state.take_damage(2)
		KEY_5:
			_game_state.unlock_skill("sauce_flick")
		KEY_7:
			_game_state.try_equip_container(STARTER_CONTAINER_ID)
		KEY_6:
			for node: Node in get_tree().get_nodes_in_group("enemies"):
				var enemy: EnemyBaseScript = node as EnemyBaseScript
				if enemy != null and enemy.def != null and enemy.def.id == NOODLE_DUMMY_ID:
					enemy.debug_defeat()
