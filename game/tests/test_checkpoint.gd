extends "res://tests/base_test.gd"
## 찜기 + checkpoint + respawn, on fresh GameState instances.

const GameStateScript := preload("res://systems/game_state.gd")
const SteamerScript := preload("res://items/steamer.gd")


func _steamer(id: String, at: Vector3) -> SteamerScript:
	var s: SteamerScript = SteamerScript.new()
	s.steamer_id = id
	s.position = at
	s.spawn_offset = Vector3(1.0, 0.5, 0.0)
	return s


func test_using_a_steamer_sets_the_checkpoint_and_heals_fully() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var s: SteamerScript = _steamer("a", Vector3(10, 0, 0))
	gs.take_damage(9)
	check_eq(gs.hearts, 5, "hurt first")
	check_eq(s.activate(gs), true, "activate succeeds")
	check_eq(gs.hearts, 14, "full heal")
	check_eq(gs.checkpoint_id, "a", "checkpoint id set")
	check_eq(gs.checkpoint_position, Vector3(11, 0.5, 0), "checkpoint is the steamer's spawn point")
	s.free()
	gs.free()


func test_a_later_steamer_replaces_the_checkpoint() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var a: SteamerScript = _steamer("a", Vector3(0, 0, 0))
	var b: SteamerScript = _steamer("b", Vector3(30, 0, 0))
	a.activate(gs)
	b.activate(gs)
	check_eq(gs.checkpoint_id, "b", "last steamer wins")
	check_eq(gs.checkpoint_position, Vector3(31, 0.5, 0), "position follows")
	a.free()
	b.free()
	gs.free()


func test_respawn_goes_to_the_checkpoint_with_full_hearts() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var s: SteamerScript = _steamer("a", Vector3(5, 0, 0))
	s.activate(gs)
	gs.take_damage(14)
	check(gs.is_dead(), "dead")
	var at: Vector3 = gs.respawn()
	check_eq(at, Vector3(6, 0.5, 0), "respawn position is the checkpoint")
	check_eq(gs.hearts, 14, "full hearts after respawn")
	check(not gs.is_dead(), "no longer dead")
	s.free()
	gs.free()


func test_respawn_keeps_sauce_and_sodium() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.add_sauce(2)
	gs.add_sodium(3)
	gs.take_damage(14)
	gs.respawn()
	check_eq(gs.sauce, 5, "sauce kept")
	check_eq(gs.sodium, 3, "sodium kept")
	gs.free()


func test_a_dead_player_cannot_use_a_steamer() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var s: SteamerScript = _steamer("a", Vector3.ZERO)
	gs.take_damage(14)
	check_eq(s.activate(gs), false, "refused while dead")
	check_eq(gs.hearts, 0, "still dead")
	check_eq(gs.checkpoint_id, "", "checkpoint not set by a refused use")
	s.free()
	gs.free()


func test_died_signal_fires_again_after_a_respawn() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var deaths: Array[int] = []
	gs.died.connect(func() -> void: deaths.append(1))
	gs.take_damage(14)
	gs.respawn()
	gs.take_damage(14)
	check_eq(deaths.size(), 2, "died emitted for each death")
	gs.free()


func test_checkpoint_survives_a_json_round_trip() -> void:
	var a: GameStateScript = GameStateScript.new()
	a.set_checkpoint("steamer_far", Vector3(31.5, 0.5, 0.0))
	var data: Dictionary = JSON.parse_string(JSON.stringify(a.to_dict()))
	var b: GameStateScript = GameStateScript.new()
	b.from_dict(data)
	check_eq(b.checkpoint_id, "steamer_far", "id restored")
	check_eq(b.checkpoint_position, Vector3(31.5, 0.5, 0.0), "position restored")
	a.free()
	b.free()


func test_bad_checkpoint_data_is_ignored() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.from_dict({"checkpoint_id": 5, "checkpoint_position": ["x", 1, 2]})
	check_eq(gs.checkpoint_id, "", "bad id ignored")
	check_eq(gs.checkpoint_position, Vector3.ZERO, "bad position ignored")
	gs.from_dict({"checkpoint_position": [1, 2]})
	check_eq(gs.checkpoint_position, Vector3.ZERO, "short position ignored")
	gs.free()
