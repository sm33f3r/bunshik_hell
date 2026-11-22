extends "res://tests/base_test.gd"
## Task 3b-i: the 단무지 wheel as data. danmuji.tres, its reaction row for every attack, what knock_over
## and bounce_boost do, its death and its drops. Fresh instances; they never rely on autoload state.

const DanmujiScript := preload("res://enemies/danmuji.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const DdeokScript := preload("res://player/ddeok.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const Layers := preload("res://systems/layers.gd")

const DT: float = 1.0 / 60.0

var _nodes: Array[Object] = []


func after_each() -> void:
	for node: Object in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _wheel(gs: GameStateScript = null) -> DanmujiScript:
	var node: DanmujiScript = (load("res://enemies/danmuji.tscn") as PackedScene).instantiate() as DanmujiScript
	node.game_state = gs
	node.setup()
	node.configure() # sizes the body (it never enters the tree here)
	_nodes.append(node)
	return node


func _state() -> GameStateScript:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	return gs


func test_danmuji_tres_holds_every_number() -> void:
	var def: EnemyDefScript = load("res://data/enemies/danmuji.tres") as EnemyDefScript
	check_eq(def.id, "danmuji", "id")
	check_eq(def.material, "crunchy", "its own material row in the reaction table")
	check(def.max_hp > 0, "health")
	check_eq(def.contact_damage_half_hearts, 2, "contact: 1 heart")
	check(def.walk_speed_mps > 0.0, "rolling speed")
	check(def.size_cm > 0.0 and def.thickness_cm > 0.0 and def.flat_height_cm > 0.0, "size, thickness, flat height")
	check(def.bounce_multiplier > 0.0, "bounce multiplier")
	check(def.platform_duration_s > 0.0, "platform time")
	check(def.knock_slide_m > 0.0 and def.knock_slide_speed_mps > 0.0, "how far and fast a knocked-over wheel slides")
	var kinds: Array[String] = []
	for entry in def.drops:
		kinds.append(entry.kind)
	check(kinds.has("natrium"), "sometimes 나트륨")
	check(def.unlocks_skill_on_first_defeat == &"", "defeating one unlocks nothing")


func test_the_bounce_boost_value_is_in_the_tuning_data() -> void:
	var t: MovementTuningScript = load("res://data/movement_tuning.tres") as MovementTuningScript
	check(t.bounce_boost_multiplier > 1.0, "a boost is more than the plain bounce")
	check(t.unset_fields().is_empty(), "no tuning field is left unset: " + str(t.unset_fields()))


func test_the_reaction_row_for_every_attack() -> void:
	var table: ReactionTableScript = load("res://data/reaction_table.tres") as ReactionTableScript
	var expect: Dictionary = {
		"landing": "bounce_boost", "stomp": "bounce_boost", "roll": "knock_over", "slam": "damage",
		"sauce": "absorb", "heavy_object": "damage", "water": "absorb",
	}
	for attack: String in expect:
		var cell: Array[Dictionary] = table.lookup_all(attack, "crunchy")
		check_eq(cell.size(), 1, "%s: one reaction" % attack)
		check_eq(cell[0]["reaction"], expect[attack], "%s x crunchy" % attack)
	check(table.lookup("slam", "crunchy")["damage"] > 0, "a slam hurts it")
	check(table.lookup("heavy_object", "crunchy")["damage"] > 0, "a heavy object hurts it")
	check_eq(ReactionTableScript.REACTION_BOUNCE_BOOST, "bounce_boost", "the new reaction's name")


func test_sauce_is_absorbed_and_nothing_changes() -> void:
	var wheel: DanmujiScript = _wheel(_state())
	var hp: int = wheel.hp
	var result: Dictionary = wheel.receive_attack(ReactionTableScript.ATTACK_SAUCE, 1.0)
	check_eq(result["reaction"], "absorb", "absorb")
	check(wheel.alive and wheel.hp == hp, "unhurt")


func test_landing_and_stomp_do_nothing_to_it_the_player_bounces() -> void:
	for attack: String in [ReactionTableScript.ATTACK_LANDING, ReactionTableScript.ATTACK_STOMP]:
		var wheel: DanmujiScript = _wheel(_state())
		var result: Dictionary = wheel.receive_attack(attack, 1.0)
		check_eq(result["reaction"], "bounce_boost", "%s: bounce_boost" % attack)
		check(wheel.alive and not wheel.flat and wheel.hp == wheel.def.max_hp, "%s: the wheel is untouched" % attack)


func test_the_player_is_thrown_higher_by_a_wheel_than_by_a_plain_bounce() -> void:
	var gs: GameStateScript = _state()
	var player: DdeokScript = DdeokScript.new()
	player.game_state = gs
	player.tuning = load("res://data/movement_tuning.tres") as MovementTuningScript
	_nodes.append(player)
	tree.root.add_child(player) # _hit_enemy reads global positions
	var wheel: DanmujiScript = _wheel(gs)
	tree.root.add_child(wheel)
	player._hit_enemy(wheel, ReactionTableScript.ATTACK_LANDING)
	var expected: float = player.tuning.bounce_velocity * player.tuning.bounce_boost_multiplier * wheel.def.bounce_multiplier
	check(absf(player.velocity.y - expected) < 0.0001, "landing: %.2f m/s (expected %.2f)" % [player.velocity.y, expected])
	check(player.velocity.y > player.tuning.bounce_velocity, "higher than the plain bounce")
	player.velocity = Vector3.ZERO
	player._hit_enemy(wheel, ReactionTableScript.ATTACK_STOMP)
	check(absf(player.velocity.y - expected) < 0.0001, "stomp: the same")
	# A 만두 still gives the plain bounce.
	var mandu: EnemyBaseScript = (load("res://enemies/mandu.tscn") as PackedScene).instantiate() as EnemyBaseScript
	mandu.setup()
	_nodes.append(mandu)
	tree.root.add_child(mandu)
	player.velocity = Vector3.ZERO
	player._hit_enemy(mandu, ReactionTableScript.ATTACK_LANDING)
	check_eq(player.velocity.y, player.tuning.bounce_velocity, "a 만두 gives the plain bounce")


func test_the_wheels_own_multiplier_scales_the_bounce() -> void:
	var gs: GameStateScript = _state()
	var player: DdeokScript = DdeokScript.new()
	player.game_state = gs
	player.tuning = load("res://data/movement_tuning.tres") as MovementTuningScript
	_nodes.append(player)
	tree.root.add_child(player)
	var wheel: DanmujiScript = _wheel(gs)
	tree.root.add_child(wheel)
	wheel.def = wheel.def.duplicate() as EnemyDefScript
	wheel.def.bounce_multiplier = 1.5
	player._hit_enemy(wheel, ReactionTableScript.ATTACK_LANDING)
	var expected: float = player.tuning.bounce_velocity * player.tuning.bounce_boost_multiplier * 1.5
	check(absf(player.velocity.y - expected) < 0.0001, "the enemy's multiplier counts")


func test_a_roll_knocks_it_over_it_stops_hurting_and_becomes_a_platform() -> void:
	var gs: GameStateScript = _state()
	var wheel: DanmujiScript = _wheel(gs)
	wheel.collision_layer = Layers.ENEMY # (set by _ready in the tree)
	var tall: float = wheel.body_height
	var result: Dictionary = wheel.receive_attack(ReactionTableScript.ATTACK_ROLL, 1.0)
	check_eq(result["reaction"], "knock_over", "knock_over")
	check(wheel.flat, "it lies flat")
	check(not wheel.alive, "it is no longer an enemy: nothing more hurts it and it hurts nobody")
	check_eq(wheel.collision_layer, Layers.WORLD, "it is solid world now, so he can stand on it")
	check(wheel.body_height < tall * 0.7, "and it is low now (%.2f m, was %.2f m)" % [wheel.body_height, tall])
	check(absf(wheel.flat_height_m - wheel.def.flat_height_cm * (wheel.diameter_m / wheel.def.size_cm)) < 0.001, "flat height from the data")
	check_eq(wheel.hp, wheel.def.max_hp, "it is not hurt: knocked over is not killed")
	check(wheel.last_drops.is_empty() and gs.defeated_enemies.is_empty(), "no drops and no defeat recorded")
	var again: Dictionary = wheel.receive_attack(ReactionTableScript.ATTACK_SLAM, 1.0)
	check_eq(again["reaction"], "absorb", "a flat wheel takes no more hits")


func test_a_knocked_over_wheel_stays_a_static_platform_after_its_time() -> void:
	var wheel: DanmujiScript = _wheel(_state())
	wheel.receive_attack(ReactionTableScript.ATTACK_ROLL, -1.0)
	check(not wheel.is_static, "loose at first")
	# Without a scene tree move_and_slide cannot run, so drive the clock and pretend it is settled.
	wheel.flat_time = wheel.def.platform_duration_s + 0.1
	wheel.set("_slide_left", 0.0)
	wheel._become_static()
	check(wheel.is_static and wheel.flat, "static and flat")
	check(not wheel.is_physics_processing(), "it no longer moves")
	wheel.reset()
	check(not wheel.flat and not wheel.is_static and wheel.alive, "a section reset stands it up again")


func test_a_slam_hurts_it_and_it_snaps_in_half_when_it_runs_out_of_health() -> void:
	var gs: GameStateScript = _state()
	gs.drops.rng.seed = 1
	var wheel: DanmujiScript = _wheel(gs)
	var died: Array[bool] = []
	wheel.died.connect(func() -> void: died.append(true))
	var first: Dictionary = wheel.receive_attack(ReactionTableScript.ATTACK_SLAM, 1.0)
	check_eq(first["reaction"], "damage", "slam: damage")
	check(wheel.alive and wheel.hp < wheel.def.max_hp, "hurt, not dead yet")
	for i: int in 3:
		wheel.receive_attack(ReactionTableScript.ATTACK_SLAM, 1.0)
	check(not wheel.alive, "dead after enough slams")
	check_eq(died.size(), 1, "died once")
	check(not wheel.flat, "dying is not falling flat")
	check(gs.defeated_enemies.has("danmuji"), "recorded as defeated")


func test_a_heavy_object_damages_it() -> void:
	var wheel: DanmujiScript = _wheel(_state())
	var hp: int = wheel.hp
	wheel.receive_attack(ReactionTableScript.ATTACK_HEAVY_OBJECT, 1.0)
	check(wheel.hp < hp or not wheel.alive, "heavy object: damage")


func test_it_sometimes_drops_natrium_through_the_drop_system() -> void:
	var gs: GameStateScript = _state()
	gs.drops.rng.seed = 7
	var natrium: int = 0
	for i: int in 12:
		var wheel: DanmujiScript = _wheel(gs)
		wheel.receive_attack(ReactionTableScript.ATTACK_HEAVY_OBJECT, 1.0)
		for drop: Dictionary in wheel.last_drops:
			if drop["kind"] == "natrium":
				natrium += 1
	check(natrium > 0, "some kills drop 나트륨")
	check(natrium < 12, "but not every kill: 'sometimes' (%d of 12)" % natrium)
	# The bad-luck protection of the shared roller applies to it like to the others.
	var gs2: GameStateScript = _state()
	gs2.drops.rng.seed = 3
	var dry: int = 0
	var worst: int = 0
	for i: int in 30:
		var w: DanmujiScript = _wheel(gs2)
		w.receive_attack(ReactionTableScript.ATTACK_HEAVY_OBJECT, 1.0)
		if w.last_drops.is_empty():
			dry += 1
			worst = maxi(worst, dry)
		else:
			dry = 0
	check(worst <= w_limit(), "never more than %d dry kills in a row (saw %d)" % [w_limit(), worst])


func w_limit() -> int:
	return (load("res://data/enemies/danmuji.tres") as EnemyDefScript).drop_guarantee_after


func test_it_rolls_and_turns_at_a_wall_in_its_own_logic() -> void:
	var wheel: DanmujiScript = _wheel(_state())
	wheel.start_dir = 1.0
	wheel._on_ready()
	wheel.run_ai(DT)
	check(wheel.velocity.x > 0.0, "rolls right")
	check(absf(wheel.velocity.x - wheel.def.walk_speed_mps) < 0.0001, "at the data's speed")
	wheel.speed_scale = 0.0
	wheel.run_ai(DT)
	check_eq(wheel.velocity.x, 0.0, "a spawn can stop it (speed_scale)")
	wheel.speed_scale = 1.0
	wheel.pin_left = 1.0
	wheel.run_ai(DT)
	check_eq(wheel.velocity.x, 0.0, "pinned: it does not roll")
