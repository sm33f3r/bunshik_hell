extends "res://tests/base_test.gd"
## 참기름: drops, puddles, smudges and the source's drip timing. No scene tree needed
## (the GameState is injected).

const GameStateScript := preload("res://systems/game_state.gd")
const DropScript := preload("res://items/sesame_oil_drop.gd")
const SmudgeScript := preload("res://items/sesame_oil_smudge.gd")
const SourceScript := preload("res://items/sesame_oil_source.gd")
const TuningScript := preload("res://items/sesame_oil_tuning.gd")


func _drop(gs: GameStateScript) -> DropScript:
	var d: DropScript = DropScript.new()
	d.game_state = gs
	d.tuning = load("res://data/sesame_oil.tres") as TuningScript
	return d


func test_the_heal_amount_is_data_and_is_half_a_heart() -> void:
	var t: TuningScript = load("res://data/sesame_oil.tres") as TuningScript
	check(t != null, "sesame_oil.tres loads")
	check_eq(t.heal_half_hearts, 1, "½ heart")


func test_a_drop_heals_half_a_heart_when_hurt_and_is_used_up() -> void:
	var gs := GameStateScript.new()
	gs.take_damage(4)
	var d := _drop(gs)
	check_eq(d.step(0.016, true), true, "healed")
	check_eq(gs.hearts, 11, "+1 half-heart")
	check_eq(d.gone, true, "used up")
	check_eq(d.step(0.016, true), false, "a used-up drop does nothing more")
	check_eq(gs.hearts, 11, "no second heal")
	d.free()
	gs.free()


func test_a_drop_is_not_used_up_at_full_hearts() -> void:
	var gs := GameStateScript.new()
	var d := _drop(gs)
	check_eq(d.step(0.016, true), false, "nothing to heal")
	check_eq(d.gone, false, "still there")
	gs.take_damage(2)
	check_eq(d.step(0.016, true), true, "heals once he is hurt")
	d.free()
	gs.free()


func test_a_puddle_lasts_its_lifetime_then_soaks_away() -> void:
	var gs := GameStateScript.new()
	var d := _drop(gs)
	check_eq(d.puddle_lifetime_s, 8.0, "default lifetime 8 s")
	d.land()
	d.step(7.9, false)
	check_eq(d.gone, false, "still there after 7.9 s")
	d.step(0.2, false)
	check_eq(d.gone, true, "gone after 8.1 s")
	d.free()
	gs.free()


func test_a_puddle_heals_too_and_the_lifetime_is_editable() -> void:
	var gs := GameStateScript.new()
	gs.take_damage(2)
	var d := _drop(gs)
	d.puddle_lifetime_s = 2.0
	d.land()
	d.step(1.0, false)
	check_eq(d.gone, false, "2 s lifetime: alive at 1 s")
	check_eq(d.step(0.1, true), true, "the puddle heals")
	check_eq(gs.hearts, 13, "+½ heart")
	d.free()
	gs.free()


func test_a_smudge_heals_once_and_does_not_come_back() -> void:
	var gs := GameStateScript.new()
	var m: SmudgeScript = SmudgeScript.new()
	m.game_state = gs
	m.tuning = load("res://data/sesame_oil.tres") as TuningScript
	check_eq(m.try_use(), false, "full hearts: not used up")
	check_eq(m.used, false, "still there")
	gs.take_damage(4)
	check_eq(m.try_use(), true, "heals when hurt")
	check_eq(gs.hearts, 11, "+½ heart")
	check_eq(m.used, true, "used")
	check_eq(m.try_use(), false, "used once")
	check_eq(gs.hearts, 11, "no second heal")
	m.reset() # debug key 3 only
	check_eq(m.used, false, "reset brings it back")
	m.free()
	gs.free()


func test_the_source_drips_between_its_min_and_max_and_defaults_are_10_and_30() -> void:
	var src: SourceScript = SourceScript.new()
	check_eq(src.drip_min_s, 10.0, "default min")
	check_eq(src.drip_max_s, 30.0, "default max")
	check_eq(src.puddle_lifetime_s, 8.0, "default puddle lifetime")
	src.drip_min_s = 3.0
	src.drip_max_s = 6.0
	src.rng.seed = 1234
	var lo: float = 99.0
	var hi: float = 0.0
	for i: int in 300:
		var w: float = src.roll_interval()
		lo = minf(lo, w)
		hi = maxf(hi, w)
	check(lo >= 3.0 and hi <= 6.0, "all waits within 3-6 s (%.2f..%.2f)" % [lo, hi])
	check(hi - lo > 2.0, "and they are random, not constant")
	src.free()


func test_the_source_drips_when_the_countdown_runs_out() -> void:
	var src: SourceScript = SourceScript.new()
	src.drip_min_s = 3.0
	src.drip_max_s = 3.0
	src._countdown = src.roll_interval()
	var count: Array[int] = [0]
	src.dripped.connect(func(_d: Node3D) -> void: count[0] += 1)
	check_eq(src.step(2.9), false, "not yet")
	check_eq(src.step(0.2), true, "now")
	check_eq(count[0], 1, "one drip signalled")
	check_eq(src.step(2.9), false, "the timer restarted")
	src.free()
