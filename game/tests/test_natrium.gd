extends "res://tests/base_test.gd"
## 나트륨 and the environment special, as isolated units (no scene, no autoloads).

const GameStateScript := preload("res://systems/game_state.gd")
const UsableScript := preload("res://items/usable_object.gd")
const EnvSpecialDefScript := preload("res://systems/env_special_def.gd")
const NatriumPickupScript := preload("res://items/natrium_pickup.gd")
const NatriumPickupDefScript := preload("res://items/natrium_pickup_def.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")

const DEFS_DIR: String = "res://data/env_specials/"


func _def(file: String) -> EnvSpecialDefScript:
	return load(DEFS_DIR + file + ".tres") as EnvSpecialDefScript


func _usable(file: String) -> UsableScript:
	var o: UsableScript = UsableScript.new()
	o.def = _def(file)
	return o


func test_natrium_starts_at_0_and_is_capped_at_7() -> void:
	var gs: GameStateScript = GameStateScript.new()
	check_eq(gs.sodium, 0, "starts at 0")
	check_eq(GameStateScript.MAX_SODIUM, 7, "cap is 7")
	gs.add_sodium(3)
	check_eq(gs.sodium, 3, "+3")
	gs.add_sodium(100)
	check_eq(gs.sodium, 7, "capped at 7")
	gs.add_sodium(-2)
	gs.add_sodium(0)
	check_eq(gs.sodium, 7, "negative and zero adds do nothing")
	check(not gs.spend_sodium(8), "cannot spend more than held")
	check_eq(gs.sodium, 7, "a refused spend changes nothing")
	check(gs.spend_sodium(7), "can spend all of it")
	check_eq(gs.sodium, 0, "floor is 0")
	check(not gs.spend_sodium(1), "nothing left to spend")
	gs.free()


func test_the_special_costs_one_natrium_and_it_is_data() -> void:
	for file: String in ["water_bottle", "pot_small", "pot_medium", "pot_large"]:
		var d: EnvSpecialDefScript = _def(file)
		check(d != null, file + " loads")
		check_eq(d.natrium_cost, 1, file + " costs 1 natrium")
	check_eq(_def("water_bottle").kind, "pour_water", "bottle kind")
	check_eq(_def("pot_small").kind, "heavy_object", "pot kind")
	check_eq(_def("water_bottle").reach_m, 3.0, "water reach 3 m")


func test_the_special_is_refused_below_the_cost_and_spends_nothing() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var o: UsableScript = _usable("water_bottle")
	check_eq(o.try_use(gs, 1.0), false, "refused with 0 natrium")
	check_eq(o.used, false, "still unused")
	check_eq(gs.sodium, 0, "nothing spent")
	o.free()
	gs.free()


func test_the_cost_is_spent_once_per_use_and_the_object_is_single_use() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.add_sodium(3)
	var o: UsableScript = _usable("pot_small")
	check_eq(o.try_use(gs, -1.0), true, "used")
	check_eq(gs.sodium, 2, "exactly one natrium spent")
	check_eq(o.try_use(gs, -1.0), false, "single use: a second press does nothing")
	check_eq(gs.sodium, 2, "and costs nothing")
	o.reset()
	check_eq(o.used, false, "reset (debug key 3) makes it usable again")
	check_eq(o.try_use(gs, 1.0), true, "usable again")
	check_eq(gs.sodium, 1, "one more natrium spent")
	o.free()
	gs.free()


func test_range_and_nearest_use_the_game_plane_distance() -> void:
	var o: UsableScript = _usable("water_bottle")
	o.position = Vector3(10.0, 0.0, 0.0)
	check(o.in_range_of(Vector3(11.0, 0.3, 0.0)), "1 m away: in range")
	check(not o.in_range_of(Vector3(13.0, 0.3, 0.0)), "3 m away: out of range")
	check(not o.in_range_of(Vector3(10.0, 2.5, 0.0)), "2.5 m above: out of range")
	var near: float = o.distance_to(Vector3(10.5, 0.25, 0.0))
	var far: float = o.distance_to(Vector3(11.5, 0.25, 0.0))
	check(near < far, "distance grows with the gap")
	o.free()


func test_the_pickup_gives_one_natrium_from_data_and_a_drop_can_override() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var p: NatriumPickupScript = NatriumPickupScript.new()
	p.game_state = gs
	var d: NatriumPickupDefScript = load("res://data/natrium_pickup.tres") as NatriumPickupDefScript
	check_eq(d.amount, 1, "data: +1")
	check_eq(p.effective_amount(), 1, "no override: uses the data")
	check_eq(p.try_collect(), true, "collected")
	check_eq(gs.sodium, 1, "+1")
	check_eq(p.consumed, true, "gone")
	var big: NatriumPickupScript = NatriumPickupScript.new()
	big.game_state = gs
	big.amount = 2
	big.try_collect()
	check_eq(gs.sodium, 3, "a drop of 2 gives 2")
	p.free()
	big.free()
	gs.free()


func test_the_pickup_stays_when_natrium_is_full() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.add_sodium(7)
	var p: NatriumPickupScript = NatriumPickupScript.new()
	p.game_state = gs
	check_eq(p.try_collect(), false, "full: not taken")
	check_eq(p.consumed, false, "still there")
	gs.spend_sodium(1)
	check_eq(p.try_collect(), true, "taken once there is room")
	p.free()
	gs.free()


func test_heavy_pin_times_by_size_are_3_6_10() -> void:
	check_eq(_def("pot_small").pin_s(), 3.0, "small 3 s")
	check_eq(_def("pot_medium").pin_s(), 6.0, "medium 6 s")
	check_eq(_def("pot_large").pin_s(), 10.0, "large 10 s")
	check_eq(_def("water_bottle").pin_s(), 0.0, "water does not pin")
	check(_def("pot_large").body_size().x > _def("pot_small").body_size().x, "a bigger pot is a bigger box")


func test_enemy_data_for_swell_and_creep() -> void:
	var noodle: EnemyDefScript = load("res://data/enemies/noodle_dummy.tres") as EnemyDefScript
	check_eq(noodle.swell_time_s, 2.0, "swell time 2 s")
	check_eq(noodle.creep_range_m, 6.0, "creeps within 6 m")
	check(noodle.creep_speed_mps > 0.0 and noodle.creep_speed_mps < 2.0, "slow creep, speed in data")
	var fried: EnemyDefScript = load("res://data/enemies/fried_medium.tres") as EnemyDefScript
	check_eq(fried.creep_speed_mps, 0.0, "a fried dummy does not creep")
