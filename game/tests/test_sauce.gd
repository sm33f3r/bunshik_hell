extends "res://tests/base_test.gd"
## Sauce resource, the flick request, pool and drip. Fresh instances only: no scene tree,
## no physics, no autoloads (the GameState is injected).

const DdeokScript := preload("res://player/ddeok.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const SauceTuningScript := preload("res://systems/sauce_tuning.gd")
const SaucePoolScript := preload("res://items/sauce_pool.gd")
const SauceDripScript := preload("res://items/sauce_drip.gd")
const SauceTypeListScript := preload("res://systems/sauce_type_list.gd")

const TUNING_PATH: String = "res://data/sauce_tuning.tres"


func _player(gs: GameStateScript) -> DdeokScript:
	var p: DdeokScript = DdeokScript.new()
	p.game_state = gs
	return p


func test_tuning_starting_values() -> void:
	var t: SauceTuningScript = load(TUNING_PATH) as SauceTuningScript
	check(t != null, "sauce_tuning.tres loads")
	check_eq(t.flick_cost, 1, "flick_cost")
	check_eq(t.flick_range_m, 8.0, "flick_range_m")
	check_eq(t.flick_cooldown_s, 0.3, "flick_cooldown_s")
	check_eq(t.flick_speed_mps, 18.0, "flick_speed_mps")
	check_eq(t.pool_refill_interval_s, 0.5, "pool_refill_interval_s")
	check_eq(t.drip_amount, 1, "drip_amount")


func test_sauce_starts_at_3_and_is_capped_at_7_and_floored_at_0() -> void:
	var gs: GameStateScript = GameStateScript.new()
	check_eq(gs.sauce, 3, "start value")
	check_eq(GameStateScript.MAX_SAUCE, 7, "cap")
	gs.add_sauce(99)
	check_eq(gs.sauce, 7, "add stops at the cap")
	check_eq(gs.spend_sauce(7), true, "spend everything")
	check_eq(gs.sauce, 0, "floor")
	check_eq(gs.spend_sauce(1), false, "cannot spend from 0")
	check_eq(gs.sauce, 0, "still 0")
	gs.add_sauce(0)
	check_eq(gs.sauce, 0, "adding 0 changes nothing")
	gs.free()


func test_flick_is_refused_while_locked_and_gives_no_feedback() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var p: DdeokScript = _player(gs)
	var cues: Array[int] = []
	p.sauce_refused.connect(func() -> void: cues.append(1))
	p.sauce_fired.connect(func() -> void: cues.append(2))
	check_eq(p.request_sauce_attack(), false, "locked: nothing fires")
	check_eq(gs.sauce, 3, "locked: no sauce spent")
	gs.sauce = 0
	check_eq(p.request_sauce_attack(), false, "locked and empty: still nothing")
	check_eq(cues.size(), 0, "locked: no signal of any kind (no hint the skill exists)")
	p.free()
	gs.free()


func test_flick_fires_spends_the_cost_and_starts_the_cooldown() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.unlock_skill("sauce_flick")
	var p: DdeokScript = _player(gs)
	check_eq(p.request_sauce_attack(), true, "fires")
	check_eq(gs.sauce, 2, "cost 1 spent")
	check_eq(p.sauce_cooldown_left(), 0.3, "cooldown started")
	p.free()
	gs.free()


func test_flick_is_refused_without_enough_sauce_and_says_so() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.unlock_skill("sauce_flick")
	gs.sauce = 0
	var p: DdeokScript = _player(gs)
	var refused: Array[int] = []
	p.sauce_refused.connect(func() -> void: refused.append(1))
	check_eq(p.request_sauce_attack(), false, "no sauce, no shot")
	check_eq(refused.size(), 1, "the HUD cue signal fired")
	check_eq(gs.sauce, 0, "nothing spent")
	p.free()
	gs.free()


func test_flick_is_refused_during_the_cooldown_and_works_after() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.unlock_skill("sauce_flick")
	var p: DdeokScript = _player(gs)
	check_eq(p.request_sauce_attack(), true, "first shot")
	check_eq(p.request_sauce_attack(), false, "second shot during the cooldown")
	check_eq(gs.sauce, 2, "the refused shot cost nothing")
	p._tick_timers(0.29)
	check_eq(p.request_sauce_attack(), false, "still cooling at 0.29 s")
	p._tick_timers(0.02)
	check_eq(p.request_sauce_attack(), true, "ready after 0.3 s")
	check_eq(gs.sauce, 1, "two shots spent two sauce")
	p.free()
	gs.free()


func test_sauce_types_are_data_and_cycling_with_one_type_is_a_no_op() -> void:
	var list: SauceTypeListScript = load("res://data/sauce_types.tres") as SauceTypeListScript
	check_eq(list.ids(), ["gochujang"] as Array[String], "one type for now")
	check_eq(list.find("gochujang").display_name, "Gochujang", "display name")
	var gs: GameStateScript = GameStateScript.new()
	var changes: Array[String] = []
	gs.sauce_type_changed.connect(func(id: String) -> void: changes.append(id))
	check_eq(gs.sauce_type_id, "gochujang", "default type")
	gs.cycle_sauce_type(1)
	gs.cycle_sauce_type(-1)
	check_eq(gs.sauce_type_id, "gochujang", "still gochujang")
	check_eq(changes.size(), 0, "no change signal")
	gs.free()


func test_pool_refills_at_the_interval_and_stops_at_the_cap() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.sauce = 0
	var pool: SaucePoolScript = SaucePoolScript.new()
	pool.game_state = gs
	check_eq(pool.step(0.25, true), 0, "0.25 s: nothing yet")
	check_eq(pool.step(0.25, true), 1, "0.5 s: +1")
	check_eq(gs.sauce, 1, "sauce 1")
	check_eq(pool.step(0.25, false), 0, "left the pool")
	check_eq(pool.step(0.25, true), 0, "the timer restarted when he left")
	check_eq(pool.step(0.25, true), 1, "+1 again after a full interval")
	check_eq(gs.sauce, 2, "sauce 2")
	for i: int in 40:
		pool.step(0.5, true)
	check_eq(gs.sauce, 7, "stops at the cap")
	check_eq(pool.step(0.5, true), 0, "nothing added at the cap")
	check_eq(gs.sauce, 7, "still 7")
	pool.free()
	gs.free()


func test_drip_adds_once_and_is_not_consumed_at_the_cap() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var drip: SauceDripScript = SauceDripScript.new()
	drip.game_state = gs
	gs.sauce = 7
	check_eq(drip.try_collect(), false, "full: not taken")
	check_eq(drip.consumed, false, "full: not consumed")
	check_eq(gs.sauce, 7, "full: unchanged")
	gs.sauce = 6
	check_eq(drip.try_collect(), true, "room: taken")
	check_eq(gs.sauce, 7, "+1")
	check_eq(drip.consumed, true, "consumed")
	check_eq(drip.try_collect(), false, "cannot be taken twice")
	check_eq(gs.sauce, 7, "no double count")
	drip.free()
	gs.free()
