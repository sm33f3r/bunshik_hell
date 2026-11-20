extends "res://tests/base_test.gd"
## Enemy drops: the 25% chance, the bad-luck guarantee, the right item per material, and that
## the roll is deterministic for a seed. Defs built here are fresh copies, never the shared .tres.

const DropRollerScript := preload("res://systems/drop_roller.gd")
const DropEntryScript := preload("res://systems/drop_entry.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")
const StationaryScript := preload("res://enemies/stationary_dummy.gd")
const NoodleScript := preload("res://enemies/noodle_dummy.gd")


func _def(id: String, chance: float, kind: String = "natrium", amount: int = 2) -> EnemyDefScript:
	var d: EnemyDefScript = EnemyDefScript.new()
	d.id = id
	var entry: DropEntryScript = DropEntryScript.new()
	entry.kind = kind
	entry.amount = amount
	entry.chance = chance
	d.drops = [entry] as Array[DropEntryScript]
	return d


func _roller(seed_value: int) -> DropRollerScript:
	var r: DropRollerScript = DropRollerScript.new()
	r.rng.seed = seed_value
	return r


func test_the_chance_is_25_percent_with_a_fixed_seed() -> void:
	var d: EnemyDefScript = _def("chance_probe", 0.25)
	d.drop_guarantee_after = 100000 # measure the pure chance, without the protection
	var r: DropRollerScript = _roller(20261120)
	var drops: int = 0
	var kills: int = 8000
	for i: int in kills:
		if not r.roll(d).is_empty():
			drops += 1
	var rate: float = float(drops) / float(kills)
	check(rate > 0.23 and rate < 0.27, "about 25%% over %d kills, got %.3f" % [kills, rate])


func test_the_same_seed_gives_the_same_drops() -> void:
	var d: EnemyDefScript = _def("seed_probe", 0.25)
	var a: DropRollerScript = _roller(77)
	var b: DropRollerScript = _roller(77)
	var seq_a: Array[bool] = []
	var seq_b: Array[bool] = []
	for i: int in 60:
		seq_a.append(not a.roll(d).is_empty())
		seq_b.append(not b.roll(d).is_empty())
	check_eq(seq_a, seq_b, "identical sequences")
	var c: DropRollerScript = _roller(78)
	var seq_c: Array[bool] = []
	for i: int in 60:
		seq_c.append(not c.roll(d).is_empty())
	check(seq_a != seq_c, "a different seed gives a different sequence")


func test_a_drop_is_guaranteed_after_4_dry_kills_in_a_row() -> void:
	var d: EnemyDefScript = _def("never_lucky", 0.0) # the chance alone never drops
	check_eq(d.drop_guarantee_after, 4, "protection after 4 dry kills (data)")
	var r: DropRollerScript = _roller(1)
	for i: int in 4:
		check(r.roll(d).is_empty(), "kill %d: nothing" % (i + 1))
	check_eq(r.dry_kills("never_lucky"), 4, "four dry kills counted")
	var fifth: Array[Dictionary] = r.roll(d)
	check_eq(fifth.size(), 1, "the 5th kill is guaranteed to drop")
	check_eq(fifth[0]["kind"], "natrium", "the item")
	check_eq(r.dry_kills("never_lucky"), 0, "the streak starts over")
	for i: int in 4:
		check(r.roll(d).is_empty(), "again nothing for 4 kills (%d)" % (i + 1))
	check_eq(r.roll(d).size(), 1, "and the 10th kill drops")


func test_a_lucky_drop_also_resets_the_streak() -> void:
	var always: EnemyDefScript = _def("lucky", 1.0)
	var r: DropRollerScript = _roller(5)
	check_eq(r.roll(always).size(), 1, "chance 1.0 always drops")
	check_eq(r.dry_kills("lucky"), 0, "streak 0")
	var never: EnemyDefScript = _def("unlucky", 0.0)
	r.roll(never)
	r.roll(never)
	check_eq(r.dry_kills("unlucky"), 2, "two dry")
	always.id = "unlucky" # same type id, now lucky
	r.roll(always)
	check_eq(r.dry_kills("unlucky"), 0, "a natural drop resets the count")


func test_the_protection_is_counted_per_enemy_type() -> void:
	var a: EnemyDefScript = _def("type_a", 0.0)
	var b: EnemyDefScript = _def("type_b", 0.0)
	var r: DropRollerScript = _roller(3)
	for i: int in 4:
		r.roll(a)
	check_eq(r.dry_kills("type_a"), 4, "type A is due")
	check_eq(r.dry_kills("type_b"), 0, "type B is not")
	check(r.roll(b).is_empty(), "so B's first kill drops nothing")
	check_eq(r.roll(a).size(), 1, "while A's next kill does drop")


func test_reset_forgets_the_streaks() -> void:
	var a: EnemyDefScript = _def("forget_me", 0.0)
	var r: DropRollerScript = _roller(3)
	for i: int in 4:
		r.roll(a)
	r.reset()
	check_eq(r.dry_kills("forget_me"), 0, "forgotten")
	check(r.roll(a).is_empty(), "no longer guaranteed")


func test_an_enemy_with_an_empty_table_never_drops_even_after_many_kills() -> void:
	var d: EnemyDefScript = EnemyDefScript.new()
	d.id = "nothing"
	var r: DropRollerScript = _roller(9)
	for i: int in 30:
		check(r.roll(d).is_empty(), "kill %d: nothing" % i)
	check(r.roll(null).is_empty(), "a null def is safe")


func test_the_right_item_per_material() -> void:
	var expected: Dictionary[String, Array] = {
		"noodle_dummy": ["natrium", 2],
		"fried_small": ["sauce_drip", 1],
		"fried_medium": ["sauce_drip", 1],
		"fried_large": ["sauce_drip", 1],
		"soft_dummy": ["sauce_drip", 1],
	}
	for id: String in expected:
		var def: EnemyDefScript = load("res://data/enemies/%s.tres" % id) as EnemyDefScript
		check_eq(def.drops.size(), 1, id + " has one drop entry")
		check_eq(def.drops[0].kind, expected[id][0], id + " drops " + str(expected[id][0]))
		check_eq(def.drops[0].amount, expected[id][1], id + " amount")
		check_eq(def.drops[0].chance, 0.25, id + " chance is 25%")
		check_eq(def.drop_guarantee_after, 4, id + " protection after 4")
	for id: String in ["tube_dummy", "tall_rigid_dummy"]:
		var def: EnemyDefScript = load("res://data/enemies/%s.tres" % id) as EnemyDefScript
		check(def.drops.is_empty(), id + " drops nothing")


func test_each_dummy_rolls_through_its_own_table_when_it_dies() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.drops.rng.seed = 11
	# Prime the streak so the next kill is guaranteed whatever the dice say.
	for id: String in ["noodle_dummy", "fried_medium", "soft_dummy", "tube_dummy"]:
		var script: GDScript = NoodleScript if id == "noodle_dummy" else StationaryScript
		var e: Node3D = script.new()
		e.def = load("res://data/enemies/%s.tres" % id) as EnemyDefScript
		e.game_state = gs
		e.setup()
		gs.drops._dry_kills[id] = 4
		e.debug_defeat()
		var got: Array[Dictionary] = e.last_drops
		match id:
			"noodle_dummy":
				check_eq(got, [{"kind": "natrium", "amount": 2}] as Array[Dictionary], "the 라면 drops its 스프: 나트륨 x2")
			"fried_medium", "soft_dummy":
				check_eq(got, [{"kind": "sauce_drip", "amount": 1}] as Array[Dictionary], id + " drops a sauce drip")
			"tube_dummy":
				check(got.is_empty(), "tube candy drops nothing")
		e.free()
	gs.free()


func test_game_state_reset_clears_the_streaks() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.drops._dry_kills["noodle_dummy"] = 4
	gs.reset()
	check_eq(gs.drops.dry_kills("noodle_dummy"), 0, "reset clears it")
	gs.free()
