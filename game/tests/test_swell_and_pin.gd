extends "res://tests/base_test.gd"
## The new reaction-table cells, and the swell and pin reactions on fresh enemy instances
## that never enter the scene tree.

const ReactionTableScript := preload("res://systems/reaction_table.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const NoodleScript := preload("res://enemies/noodle_dummy.gd")
const StationaryScript := preload("res://enemies/stationary_dummy.gd")
const TubeScript := preload("res://enemies/tube_dummy.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const EnvSpecialDefScript := preload("res://systems/env_special_def.gd")

const TABLE_PATH: String = "res://data/reaction_table.tres"


func _table() -> ReactionTableScript:
	return load(TABLE_PATH) as ReactionTableScript


func _expect(attack: String, material: String, reaction: String) -> void:
	var r: Dictionary = _table().lookup(attack, material)
	check_eq(r["reaction"], reaction, "%s x %s" % [attack, material])
	check_eq(r["damage"], 0, "%s x %s damage" % [attack, material])


func _make(def_path: String, script: GDScript, gs: GameStateScript = null) -> EnemyBaseScript:
	var e: EnemyBaseScript = script.new()
	e.def = load(def_path) as EnemyDefScript
	e.reaction_table = _table()
	e.game_state = gs
	e.setup()
	return e


func _noodle(gs: GameStateScript = null) -> EnemyBaseScript:
	return _make("res://data/enemies/noodle_dummy.tres", NoodleScript, gs)


func test_every_new_table_cell() -> void:
	_expect("water", "noodle", "swell")
	_expect("heavy_object", "noodle", "pin")
	_expect("water", "fried", "deteriorate")
	_expect("heavy_object", "fried", "kill")
	for material: String in ["soft", "tall_rigid", "tube"]:
		_expect("water", material, "absorb")
		_expect("heavy_object", material, "kill")


func test_water_swells_a_noodle_and_it_dies_after_swell_time() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var e: EnemyBaseScript = _noodle(gs)
	var result: Dictionary = e.receive_attack("water", 1.0)
	check_eq(result["reaction"], "swell", "water swells it")
	check(e.swelling and e.alive, "swelling, still alive")
	e.tick_status(1.9)
	check(e.alive, "alive at 1.9 s")
	e.tick_status(0.2)
	check(not e.alive, "dead after swell_time_s (2 s)")
	check(not e.swelling, "swell is over")
	e.free()
	gs.free()


func test_swell_slows_the_noodle_to_a_stop() -> void:
	var e: EnemyBaseScript = _noodle()
	var target: Vector3 = Vector3(3.0, 0.0, 0.0)
	var full: float = e.creep_velocity_x(target)
	check(full > 0.0, "it creeps toward a target in range")
	e.receive_attack("water")
	check(is_equal_approx(e.creep_velocity_x(target), full), "at the start of the swell it is still full speed")
	e.tick_status(1.0)
	check(absf(e.creep_velocity_x(target) - full * 0.5) < 0.001, "half speed halfway")
	e.tick_status(0.99)
	check(e.creep_velocity_x(target) < full * 0.02, "almost stopped just before the end")
	e.free()


func test_swell_does_not_restart_when_hit_by_water_again() -> void:
	var e: EnemyBaseScript = _noodle()
	e.receive_attack("water")
	e.tick_status(1.5)
	e.receive_attack("water")
	check(absf(e.swell_left - 0.5) < 0.001, "the timer kept running: %.2f s left" % e.swell_left)
	e.free()


func test_a_swell_death_unlocks_the_flick_exactly_once() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var unlocks: Array[String] = []
	gs.skill_unlocked.connect(func(id: String) -> void: unlocks.append(id))
	var first: EnemyBaseScript = _noodle(gs)
	check(not gs.has_skill("sauce_flick"), "locked at the start")
	first.receive_attack("water")
	first.tick_status(0.5)
	check(not gs.has_skill("sauce_flick"), "not while it is still swelling")
	first.tick_status(2.0)
	check(gs.has_skill("sauce_flick"), "the first 라면 killed unlocked the flick")
	var second: EnemyBaseScript = _noodle(gs)
	second.receive_attack("water")
	second.tick_status(2.5)
	check_eq(unlocks, ["sauce_flick"] as Array[String], "only one unlock signal")
	check_eq(gs.defeated_enemies, ["noodle_dummy"] as Array[String], "recorded once")
	first.free()
	second.free()
	gs.free()


func test_heavy_object_pins_a_noodle_for_the_size_time() -> void:
	for pair: Array in [["pot_small", 3.0], ["pot_medium", 6.0], ["pot_large", 10.0]]:
		var def: EnvSpecialDefScript = load("res://data/env_specials/%s.tres" % pair[0]) as EnvSpecialDefScript
		var e: EnemyBaseScript = _noodle()
		var result: Dictionary = e.receive_attack("heavy_object", 1.0, {"pin_s": def.pin_s()})
		check_eq(result["reaction"], "pin", "heavy x noodle = pin")
		check(e.alive, "a pin does not kill")
		check_eq(e.pin_left, pair[1], "%s pins for %s s" % [pair[0], pair[1]])
		e.tick_status(pair[1] - 0.1)
		check(e.is_pinned(), "%s: still pinned just before the end" % pair[0])
		e.tick_status(0.2)
		check(not e.is_pinned(), "%s: free after the pin time" % pair[0])
		e.free()


func test_a_pinned_noodle_does_not_move_and_resumes_afterwards() -> void:
	var e: EnemyBaseScript = _noodle()
	e.receive_attack("heavy_object", 1.0, {"pin_s": 3.0})
	e.velocity.x = 5.0
	e.run_ai(0.1)
	check_eq(e.velocity.x, 0.0, "no movement while pinned")
	e.run_ai(3.0)
	check(not e.is_pinned(), "free again")
	var target: Vector3 = Vector3(3.0, 0.0, 0.0)
	check(e.creep_velocity_x(target) > 0.0, "and it can creep toward the 떡 again")
	e.free()


func test_a_pinned_tube_does_not_shoot() -> void:
	var tube: TubeScript = _make("res://data/enemies/tube_dummy.tres", TubeScript)
	tube.receive_attack("heavy_object", 1.0, {"pin_s": 3.0}) # tube + heavy_object = kill
	check(not tube.alive, "a heavy object kills a tube candy")
	var t2: TubeScript = _make("res://data/enemies/tube_dummy.tres", TubeScript)
	t2._start_pin(3.0)
	t2.run_ai(1.0)
	check_eq(t2._fire_timer, 0.0, "pinned: the fire timer never advances, so it never fires")
	t2.tick_status(3.0)
	t2.run_ai(0.5)
	check(t2._fire_timer > 0.0, "free again: the timer runs")
	tube.free()
	t2.free()


func test_contact_still_hurts_while_pinned() -> void:
	var e: EnemyBaseScript = _noodle()
	e.receive_attack("heavy_object", 1.0, {"pin_s": 3.0})
	check(e.is_pinned() and e.alive, "pinned")
	check_eq(e.contact_damage(), 2, "contact still hurts: 1 heart (2 half-hearts)")
	e.free()


func test_water_on_a_pinned_noodle_still_swells_it() -> void:
	var e: EnemyBaseScript = _noodle()
	e.receive_attack("heavy_object", 1.0, {"pin_s": 3.0})
	e.receive_attack("water")
	check(e.swelling, "it swells")
	check(e.is_pinned(), "and is still pinned")
	e.tick_status(2.1)
	check(not e.alive, "and dies of the swell while pinned (2 s < 3 s)")
	e.free()


func test_a_second_pin_keeps_the_longer_time() -> void:
	var e: EnemyBaseScript = _noodle()
	e.receive_attack("heavy_object", 1.0, {"pin_s": 6.0})
	e.receive_attack("heavy_object", 1.0, {"pin_s": 3.0})
	check_eq(e.pin_left, 6.0, "6 s wins over 3 s")
	e.free()


func test_a_heavy_object_kills_fried_food_of_every_size_in_one_hit() -> void:
	for file: String in ["fried_small", "fried_medium", "fried_large"]:
		var e: EnemyBaseScript = _make("res://data/enemies/%s.tres" % file, StationaryScript)
		var result: Dictionary = e.receive_attack("heavy_object", 1.0, {"pin_s": 3.0})
		check_eq(result["reaction"], "kill", file)
		check(not e.alive, file + " is dead after one hit")
		e.free()


func test_water_deteriorates_fried_food() -> void:
	var e: EnemyBaseScript = _make("res://data/enemies/fried_small.tres", StationaryScript)
	e.receive_attack("water")
	check_eq(e.stage, 1, "one water hit: broken (small = 1 hit per stage)")
	e.free()


func test_water_is_absorbed_by_soft_tall_and_tube() -> void:
	for file: String in ["soft_dummy", "tall_rigid_dummy", "tube_dummy"]:
		var e: EnemyBaseScript = _make("res://data/enemies/%s.tres" % file, StationaryScript)
		var result: Dictionary = e.receive_attack("water")
		check_eq(result["reaction"], "absorb", file)
		check(e.alive, file + " is fine")
		e.free()


func test_reset_clears_pin_and_swell() -> void:
	var e: EnemyBaseScript = _noodle()
	e.receive_attack("heavy_object", 1.0, {"pin_s": 6.0})
	e.receive_attack("water")
	e.reset()
	check(not e.is_pinned() and not e.swelling, "reset: free and not swelling")
	check(e.alive, "alive")
	e.free()
