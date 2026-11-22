extends "res://tests/base_test.gd"
## Task 3a-fix: the 만두 enemy (data, reactions) and the 만두 break aiming at a live 만두.

const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")
const DirectorScript := preload("res://prologue/prologue_director.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const DataScript := preload("res://prologue/prologue_data.gd")

const DT: float = 1.0 / 60.0

var _nodes: Array[Object] = []


func after_each() -> void:
	for node: Object in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _mandu() -> EnemyBaseScript:
	var node: EnemyBaseScript = (load("res://enemies/mandu.tscn") as PackedScene).instantiate() as EnemyBaseScript
	node.setup()
	_nodes.append(node)
	return node


func test_the_mandu_is_data_soft_and_costs_one_heart_on_contact() -> void:
	var def: EnemyDefScript = load("res://data/enemies/mandu.tres") as EnemyDefScript
	check_eq(def.id, "mandu", "id")
	check_eq(def.material, "soft", "a soft enemy")
	check_eq(def.contact_damage_half_hearts, 2, "contact: 1 heart (2 half-hearts)")
	check_eq(def.max_hp, 1, "a weak one: one hit")
	check(def.walk_speed_mps > 0.0, "it waddles")
	check(def.hop_range_m > 0.0 and def.hop_velocity_mps > 0.0, "and hops short when he is close")
	var kinds: Array[String] = []
	for entry in def.drops:
		kinds.append(entry.kind)
	check(kinds.has("sauce_drip"), "sometimes a small sauce drip")


func test_the_soft_row_decides_how_it_dies() -> void:
	var killers: Array[String] = [ReactionTableScript.ATTACK_STOMP, ReactionTableScript.ATTACK_SLAM,
		ReactionTableScript.ATTACK_HEAVY_OBJECT, ReactionTableScript.ATTACK_LANDING,
		ReactionTableScript.ATTACK_ROLL, ReactionTableScript.ATTACK_SAUCE]
	for attack: String in killers:
		var mandu: EnemyBaseScript = _mandu()
		var result: Dictionary = mandu.receive_attack(attack, 1.0)
		check(result["killed"], "%s kills a (weak) 만두" % attack)
		check(not mandu.alive, "and it is dead after %s" % attack)
	var wet: EnemyBaseScript = _mandu()
	wet.receive_attack(ReactionTableScript.ATTACK_WATER, 1.0)
	check(wet.alive, "water is absorbed: nothing happens")


func test_a_mandu_break_aims_at_a_live_mandu_and_eats_it() -> void:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	var d: DirectorScript = DirectorScript.new(load("res://data/prologue/prologue.tres") as DataScript, gs)
	d.rng.seed = 7
	gs.prologue_intro_seen = true
	d.begin()
	d.player_x = 2.0
	d.player_bottom_y = 13.0
	d.debug_free()
	for i: int in 600:
		if d.state == DirectorScript.State.STAB:
			break
		d.step(DT)
	d.mandu_xs = [8.0, 10.5] as Array[float]
	var eaten: Array[float] = []
	var lines: Array[String] = []
	d.mandu_eaten.connect(func(x: float) -> void: eaten.append(x))
	d.line_shown.connect(func(key: String, _t: String) -> void: lines.append(key))
	var targets: Array[float] = []
	d.telegraph_started.connect(func(s: DirectorScript.Stab) -> void: targets.append(s.target_x))
	d.force_next_pattern(d.find_pattern("mandu_break"))
	for i: int in 900:
		d.step(DT)
		if not eaten.is_empty():
			break
	check_eq(eaten.size(), 1, "she ate one")
	check(absf(eaten[0] - 8.0) < 0.001 or absf(eaten[0] - 10.5) < 0.001, "at a live 만두 (x = %.2f)" % eaten[0])
	check(lines.has("mandu_break"), "and said her line")
	check_eq(d.count, 0, "a 만두 break does not count as a stab")
	check(d.stab != null and d.stab.pause_s >= 1.5, "and she pauses to chew")


func test_a_mandu_that_walked_away_is_not_eaten() -> void:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	var d: DirectorScript = DirectorScript.new(load("res://data/prologue/prologue.tres") as DataScript, gs)
	gs.prologue_intro_seen = true
	d.begin()
	d.player_x = 2.0
	d.player_bottom_y = 13.0
	d.debug_free()
	for i: int in 600:
		if d.state == DirectorScript.State.STAB:
			break
		d.step(DT)
	d.mandu_xs = [9.0] as Array[float]
	var eaten: Array[float] = []
	d.mandu_eaten.connect(func(x: float) -> void: eaten.append(x))
	d.force_next_pattern(d.find_pattern("mandu_break"))
	for i: int in 30:
		d.step(DT)
	d.mandu_xs = [] as Array[float] # the player stomped it during the telegraph
	for i: int in 400:
		d.step(DT)
	check(eaten.is_empty(), "nothing left under the pick: no meal, no line")
	check(d.stab == null or d.stab.pause_s == 0.0, "and no chewing pause")


func test_no_live_mandu_means_no_mandu_breaks() -> void:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	var d: DirectorScript = DirectorScript.new(load("res://data/prologue/prologue.tres") as DataScript, gs)
	d.mandu_xs = [] as Array[float]
	for stage: int in 4:
		for p in d.eligible_patterns(stage, 29):
			check(p.kind != "mandu", "stage %d: no 만두 break without a 만두" % stage)
	d.mandu_xs = [5.0] as Array[float]
	var has_break: bool = false
	for p in d.eligible_patterns(0, 29):
		has_break = has_break or p.kind == "mandu"
	check(has_break, "with a live 만두 the break is possible again")


func test_her_plate_starts_with_three_live_mandu() -> void:
	var data: DataScript = load("res://data/prologue/prologue.tres") as DataScript
	check_eq(data.plate_mandu_count, 3, "three on the plate")


# --- Task 3a-oil: every 3rd 만두 the 떡 kills drops 참기름 ----------------------------------

func _killed_mandu(gs: GameStateScript, attack: String = ReactionTableScript.ATTACK_STOMP, params: Dictionary = {}) -> EnemyBaseScript:
	var mandu: EnemyBaseScript = _mandu()
	mandu.game_state = gs
	mandu.def = load("res://data/enemies/mandu.tres") as EnemyDefScript
	mandu.setup()
	mandu.receive_attack(attack, 1.0, params)
	return mandu


func _kinds(mandu: EnemyBaseScript) -> Array[String]:
	var out: Array[String] = []
	for drop: Dictionary in mandu.last_drops:
		out.append(drop["kind"])
	return out


func _oil_count(mandu: EnemyBaseScript) -> int:
	return _kinds(mandu).count("sesame_oil")


func test_the_mandu_data_says_every_3rd_kill_drops_sesame_oil() -> void:
	var def: EnemyDefScript = load("res://data/enemies/mandu.tres") as EnemyDefScript
	check_eq(def.every_nth_kill, 3, "every 3rd kill")
	check_eq(def.every_nth_drop, "sesame_oil", "drops 참기름")
	check(ResourceLoader.exists("res://items/sesame_oil_drop.tscn"), "the drop scene exists")
	check(EnemyBaseScript.DROP_SCENES.has("sesame_oil"), "enemies can spawn it")
	var other: EnemyDefScript = load("res://data/enemies/soft_dummy.tres") as EnemyDefScript
	check_eq(other.every_nth_kill, 0, "off for other enemies")


func test_kills_1_and_2_drop_no_oil_and_3_and_6_do() -> void:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	gs.drops.rng.seed = 11
	var oil: Array[int] = []
	for i: int in 6:
		oil.append(_oil_count(_killed_mandu(gs)))
	check_eq(oil, [0, 0, 1, 0, 0, 1] as Array[int], "oil on kills 3 and 6 only")
	check_eq(gs.kill_counts.get("mandu", 0), 6, "six kills counted")


func test_her_eating_a_mandu_does_not_count() -> void:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	_killed_mandu(gs)
	_killed_mandu(gs)
	var eaten: EnemyBaseScript = _killed_mandu(gs, ReactionTableScript.ATTACK_HEAVY_OBJECT, {"by_ddeok": false})
	check(not eaten.alive, "the pick killed it")
	check_eq(_oil_count(eaten), 0, "no oil from her kill")
	check_eq(gs.kill_counts.get("mandu", 0), 2, "and it was not counted")
	check_eq(_oil_count(_killed_mandu(gs)), 1, "his next kill is the 3rd")


func test_the_counter_survives_his_death_and_resets_on_a_new_game() -> void:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	_killed_mandu(gs)
	_killed_mandu(gs)
	gs.take_damage(GameStateScript.MAX_HEARTS) # he dies
	gs.respawn()
	check_eq(gs.kill_counts.get("mandu", 0), 2, "dying keeps the count")
	check_eq(_oil_count(_killed_mandu(gs)), 1, "so the next kill is still the 3rd")
	_killed_mandu(gs)
	gs.reset() # new game
	check(gs.kill_counts.is_empty(), "a new game clears it")
	check_eq(_oil_count(_killed_mandu(gs)), 0, "kill 1 again")
	check(not gs.to_dict().has("kill_counts"), "and it is not saved")


func test_the_sauce_drip_roll_is_unaffected_by_the_counter() -> void:
	var with_counter: GameStateScript = GameStateScript.new()
	var plain: GameStateScript = GameStateScript.new()
	_nodes.append(with_counter)
	_nodes.append(plain)
	with_counter.drops.rng.seed = 5
	plain.drops.rng.seed = 5
	var def: EnemyDefScript = load("res://data/enemies/mandu.tres") as EnemyDefScript
	for i: int in 12:
		var a: Array[Dictionary] = with_counter.drops.roll(def)
		with_counter.periodic_drop(def)
		var b: Array[Dictionary] = plain.drops.roll(def)
		check_eq(a, b, "same roll on kill %d" % (i + 1))
	check_eq(with_counter.drops.dry_kills("mandu"), plain.drops.dry_kills("mandu"), "same bad-luck count")
