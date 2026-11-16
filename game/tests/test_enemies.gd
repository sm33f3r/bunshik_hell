extends "res://tests/base_test.gd"
## Enemy damage and death through the reaction table. No physics: the hit functions
## are called directly on fresh instances that never enter the scene tree.

const SoftScript := preload("res://enemies/soft_dummy.gd")
const TallScript := preload("res://enemies/tall_rigid_dummy.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")


func _soft() -> SoftScript:
	var e: SoftScript = SoftScript.new()
	e.def = load("res://data/enemies/soft_dummy.tres") as EnemyDefScript
	e.reaction_table = load("res://data/reaction_table.tres")
	e.setup()
	return e


func _tall() -> TallScript:
	var e: TallScript = TallScript.new()
	e.def = load("res://data/enemies/tall_rigid_dummy.tres") as EnemyDefScript
	e.reaction_table = load("res://data/reaction_table.tres")
	e.setup()
	return e


func test_enemy_defs_load_with_the_requested_values() -> void:
	var soft: EnemyDefScript = load("res://data/enemies/soft_dummy.tres") as EnemyDefScript
	var tall: EnemyDefScript = load("res://data/enemies/tall_rigid_dummy.tres") as EnemyDefScript
	check_eq(soft.material, "soft", "soft material")
	check_eq(soft.max_hp, 2, "soft max_hp")
	check_eq(soft.contact_damage_half_hearts, 2, "soft contact damage")
	check_eq(tall.material, "tall_rigid", "tall material")
	check_eq(tall.max_hp, 3, "tall max_hp")
	check_eq(tall.contact_damage_half_hearts, 2, "tall contact damage")
	check(soft.id != "" and tall.id != "" and soft.id != tall.id, "distinct ids")


func test_soft_landing_damages_then_kills() -> void:
	var e: SoftScript = _soft()
	check_eq(e.hp, 2, "starts at max_hp")
	var r: Dictionary = e.receive_attack("landing")
	check_eq(r["reaction"], "damage", "landing reaction")
	check_eq(r["killed"], false, "first landing does not kill")
	check_eq(e.hp, 1, "hp 2 -> 1")
	check(e.alive, "still alive")
	r = e.receive_attack("landing")
	check_eq(r["killed"], true, "second landing kills")
	check_eq(e.hp, 0, "hp 0")
	check(not e.alive, "dead")
	e.free()


func test_soft_stomp_and_slam_kill_outright() -> void:
	for attack: String in ["stomp", "slam"]:
		var e: SoftScript = _soft()
		var r: Dictionary = e.receive_attack(attack)
		check_eq(r["reaction"], "kill", "%s reaction" % attack)
		check(not e.alive, "%s kills soft" % attack)
		e.free()


func test_soft_roll_damages_once() -> void:
	var e: SoftScript = _soft()
	e.receive_attack("roll")
	check_eq(e.hp, 1, "roll does 1 damage")
	check(e.alive, "alive after one roll")
	e.free()


func test_tall_landing_bounces_off_without_damage() -> void:
	var e: TallScript = _tall()
	var r: Dictionary = e.receive_attack("landing")
	check_eq(r["reaction"], "bounce_off", "landing reaction")
	check_eq(e.hp, 3, "no damage")
	check(e.alive, "alive")
	e.free()


func test_tall_stomp_damages() -> void:
	var e: TallScript = _tall()
	e.receive_attack("stomp")
	check_eq(e.hp, 2, "stomp does 1 damage")
	e.receive_attack("stomp")
	e.receive_attack("stomp")
	check(not e.alive, "three stomps kill it")
	e.free()


func test_tall_roll_knocks_over_and_kills() -> void:
	var e: TallScript = _tall()
	var r: Dictionary = e.receive_attack("roll")
	check_eq(r["reaction"], "knock_over", "roll reaction")
	check_eq(r["killed"], true, "knock_over kills")
	check(not e.alive, "dead")
	e.free()


func test_tall_slam_kills() -> void:
	var e: TallScript = _tall()
	e.receive_attack("slam")
	check(not e.alive, "slam kills tall")
	e.free()


func test_dead_enemies_ignore_further_hits() -> void:
	var e: SoftScript = _soft()
	e.receive_attack("stomp")
	var deaths: Array[int] = []
	e.died.connect(func() -> void: deaths.append(1))
	var r: Dictionary = e.receive_attack("stomp")
	check_eq(r["killed"], false, "no second kill")
	check_eq(deaths.size(), 0, "died not emitted twice")
	e.free()


func test_signals_fire() -> void:
	var e: SoftScript = _soft()
	var log: Array[String] = []
	e.hurt.connect(func(_hp: int) -> void: log.append("hurt"))
	e.died.connect(func() -> void: log.append("died"))
	e.receive_attack("landing")
	e.receive_attack("landing")
	check_eq(log, ["hurt", "died"] as Array[String], "hurt then died")
	e.free()


func test_an_enemy_with_an_unknown_material_absorbs_everything() -> void:
	var e: SoftScript = _soft()
	var odd: EnemyDefScript = EnemyDefScript.new()
	odd.material = "mystery"
	odd.max_hp = 4
	e.def = odd
	e.setup()
	for attack: String in ["landing", "stomp", "roll", "slam"]:
		var r: Dictionary = e.receive_attack(attack)
		check_eq(r["reaction"], "absorb", "%s absorbed" % attack)
	check_eq(e.hp, 4, "no damage")
	e.free()


func test_reset_restores_health() -> void:
	var e: SoftScript = _soft()
	e.receive_attack("slam")
	check(not e.alive, "dead")
	e.reset()
	check(e.alive, "alive again")
	check_eq(e.hp, 2, "full hp again")
	e.free()


func test_contact_damage_comes_from_the_def() -> void:
	var e: SoftScript = _soft()
	check_eq(e.contact_damage(), 2, "2 half-hearts")
	e.def = null
	check_eq(e.contact_damage(), 0, "no def, no damage")
	e.free()
