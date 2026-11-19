extends "res://tests/base_test.gd"
## The Task 2a table rows and the reactions behind them (absorb, deteriorate, jam), on fresh
## enemy instances that never enter the scene tree.

const ReactionTableScript := preload("res://systems/reaction_table.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const StationaryScript := preload("res://enemies/stationary_dummy.gd")
const TubeScript := preload("res://enemies/tube_dummy.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")

const TABLE_PATH: String = "res://data/reaction_table.tres"


func _table() -> ReactionTableScript:
	return load(TABLE_PATH) as ReactionTableScript


func _expect(attack: String, material: String, reaction: String, damage: int = 0) -> void:
	var r: Dictionary = _table().lookup(attack, material)
	check_eq(r["reaction"], reaction, "%s x %s reaction" % [attack, material])
	check_eq(r["damage"], damage, "%s x %s damage" % [attack, material])


func _make(def_path: String, script: GDScript = StationaryScript) -> EnemyBaseScript:
	var e: EnemyBaseScript = script.new()
	e.def = load(def_path) as EnemyDefScript
	e.reaction_table = _table()
	e.setup()
	return e


func test_noodle_row() -> void:
	_expect("landing", "noodle", "hurt_player")
	_expect("stomp", "noodle", "hurt_player")
	_expect("roll", "noodle", "absorb")
	_expect("slam", "noodle", "absorb")
	_expect("sauce", "noodle", "absorb")


func test_fried_row_including_the_two_reaction_cell() -> void:
	var landing: Array[Dictionary] = _table().lookup_all("landing", "fried")
	check_eq(landing.size(), 2, "landing has two reactions")
	check_eq(landing[0]["reaction"], "bounce_off", "first: bounce_off")
	check_eq(landing[1]["reaction"], "deteriorate", "second: deteriorate")
	_expect("landing", "fried", "bounce_off") # lookup() still answers with the first
	for attack: String in ["stomp", "roll", "slam", "sauce"]:
		var cell: Array[Dictionary] = _table().lookup_all(attack, "fried")
		check_eq(cell.size(), 1, "%s has one reaction" % attack)
		check_eq(cell[0]["reaction"], "deteriorate", "%s deteriorates" % attack)


func test_tube_row() -> void:
	_expect("landing", "tube", "bounce_off")
	_expect("stomp", "tube", "damage", 1)
	_expect("roll", "tube", "knock_over")
	_expect("slam", "tube", "kill")
	_expect("sauce", "tube", "jam")


func test_sauce_column_for_the_older_materials() -> void:
	_expect("sauce", "soft", "damage", 1)
	_expect("sauce", "tall_rigid", "damage", 1)


func test_single_and_list_cells_both_work_and_bad_list_items_are_skipped() -> void:
	var table: ReactionTableScript = ReactionTableScript.new()
	table.entries = {"m": {
		"one": {"reaction": "kill", "damage": 0},
		"two": [{"reaction": "bounce_off", "damage": 0}, "junk", {"reaction": 5}, {"reaction": "damage", "damage": 2}],
		"empty": [],
	}}
	check_eq(table.lookup_all("one", "m").size(), 1, "single dictionary cell")
	var two: Array[Dictionary] = table.lookup_all("two", "m")
	check_eq(two.size(), 2, "junk items skipped")
	check_eq(two[1]["damage"], 2, "second item kept in order")
	check_eq(table.lookup_all("empty", "m")[0]["reaction"], "absorb", "empty list falls back")


func test_absorb_leaves_health_unchanged() -> void:
	var e: EnemyBaseScript = _make("res://data/enemies/noodle_dummy.tres")
	var hp: int = e.hp
	for attack: String in ["roll", "slam", "sauce"]:
		var r: Dictionary = e.receive_attack(attack)
		check_eq(r["reaction"], "absorb", "%s absorbed" % attack)
		check_eq(r["killed"], false, "%s did not kill" % attack)
	check_eq(e.hp, hp, "hp unchanged")
	check(e.alive, "still alive")
	e.free()


func test_hurt_player_is_reported_and_costs_the_enemy_nothing() -> void:
	var e: EnemyBaseScript = _make("res://data/enemies/noodle_dummy.tres")
	var r: Dictionary = e.receive_attack("landing")
	check_eq(r["reaction"], "hurt_player", "reaction")
	check_eq((r["reactions"] as Array).has("hurt_player"), true, "listed for the 떡 to act on")
	check_eq(e.hp, 3, "enemy unharmed")
	e.free()


func test_deteriorate_walks_the_stages_in_order() -> void:
	var e: EnemyBaseScript = _make("res://data/enemies/fried_small.tres")
	check_eq(e.stage_name(), "fresh", "starts fresh")
	e.receive_attack("sauce")
	check_eq(e.stage_name(), "broken", "1 hit: broken")
	check(e.alive, "alive while broken")
	e.receive_attack("stomp")
	check_eq(e.stage_name(), "crumbling", "2 hits: crumbling")
	check(e.alive, "alive while crumbling")
	e.receive_attack("roll")
	check_eq(e.stage_name(), "soggy", "3 hits: soggy")
	check(not e.alive, "soggy is dead")
	e.free()


## Hits to reach soggy = 3 steps x hits_per_stage (see DETERIORATE_STEPS in enemy_base.gd).
func test_hits_needed_to_reach_soggy_scale_with_size() -> void:
	var expected: Dictionary = {"fried_small": 3, "fried_medium": 6, "fried_large": 9}
	for id: String in expected:
		var e: EnemyBaseScript = _make("res://data/enemies/%s.tres" % id)
		var needed: int = expected[id]
		check_eq(needed, StationaryScript.DETERIORATE_STEPS * e.def.hits_per_stage, id + ": formula")
		for i: int in needed - 1:
			e.receive_attack("sauce")
		check(e.alive, "%s alive after %d hits" % [id, needed - 1])
		e.receive_attack("sauce")
		check(not e.alive, "%s dead after %d hits" % [id, needed])
		check_eq(e.stage, 3, id + " ends soggy")
		e.free()
	check_eq((load("res://data/enemies/fried_small.tres") as EnemyDefScript).hits_per_stage, 1, "small 1")
	check_eq((load("res://data/enemies/fried_medium.tres") as EnemyDefScript).hits_per_stage, 2, "medium 2")
	check_eq((load("res://data/enemies/fried_large.tres") as EnemyDefScript).hits_per_stage, 3, "large 3")


func test_a_landing_on_fried_deteriorates_it_too() -> void:
	var e: EnemyBaseScript = _make("res://data/enemies/fried_small.tres")
	var r: Dictionary = e.receive_attack("landing")
	check_eq(r["reactions"], ["bounce_off", "deteriorate"] as Array[String], "both reactions reported")
	check_eq(e.stage_name(), "broken", "and the stage advanced")
	e.free()


func test_reset_returns_a_deteriorated_enemy_to_fresh() -> void:
	var e: EnemyBaseScript = _make("res://data/enemies/fried_medium.tres")
	e.receive_attack("sauce")
	e.receive_attack("sauce")
	check_eq(e.stage_name(), "broken", "broken after 2 hits")
	e.reset()
	check_eq(e.stage_name(), "fresh", "fresh again")
	e.receive_attack("sauce")
	check_eq(e.stage_name(), "fresh", "the half-finished stage count was cleared too")
	e.free()


func test_jam_stops_the_tube_dummy_firing() -> void:
	var e: TubeScript = _make("res://data/enemies/tube_dummy.tres", TubeScript) as TubeScript
	check_eq(e.fire_interval, 2.0, "fires every 2 s")
	check_eq(e.advance_fire_timer(1.9), false, "not yet")
	check_eq(e.advance_fire_timer(0.2), true, "fires at 2 s")
	check_eq(e.advance_fire_timer(2.1), true, "and again")
	var r: Dictionary = e.receive_attack("sauce")
	check_eq(r["reaction"], "jam", "sauce jams it")
	check(e.jammed, "jammed")
	check(e.alive, "jam does not kill")
	for i: int in 10:
		check_eq(e.advance_fire_timer(2.5), false, "jammed: no shot %d" % i)
	e.reset()
	check_eq(e.jammed, false, "reset un-jams it (test room only)")
	check_eq(e.advance_fire_timer(2.1), true, "fires again after a reset")
	e.free()
