extends "res://tests/base_test.gd"
## Task 3b-ii: the hazards. The wiggle rule, the `stick` status (gum) and its three ways out, the
## metal chopsticks (telegraph, grab, release, enemies lifted away) and the giant foot (telegraph,
## damage, flatten-stun, crushing). Timings and numbers are read from the data files, never retyped.
## Fresh instances; nothing here relies on autoload state. The clocks are driven by hand.

const WiggleScript := preload("res://systems/wiggle.gd")
const StuckStatusScript := preload("res://systems/stuck_status.gd")
const StickDefScript := preload("res://hazards/stick_def.gd")
const GumScene: PackedScene = preload("res://hazards/gum_patch.tscn")
const ChopsticksScene: PackedScene = preload("res://hazards/chopsticks.tscn")
const GiantFootScene: PackedScene = preload("res://hazards/giant_foot.tscn")
const StrikeZoneScript := preload("res://hazards/strike_zone.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const DdeokScript := preload("res://player/ddeok.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")

const DT: float = 1.0 / 60.0

var _nodes: Array[Object] = []


func after_each() -> void:
	for node: Object in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _gs() -> GameStateScript:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	return gs


## The 떡, not in the scene tree, with his own GameState. Roll is unlocked.
func _player(gs: GameStateScript = null) -> DdeokScript:
	var player: DdeokScript = DdeokScript.new()
	player.game_state = gs if gs != null else _gs()
	player.tuning = load("res://data/movement_tuning.tres") as MovementTuningScript
	player.game_state.unlock_skill("roll")
	player.grounded = true
	_nodes.append(player)
	return player


func _gum() -> Node:
	var gum: Node = GumScene.instantiate()
	_nodes.append(gum)
	return gum


func _zone(scene: PackedScene, in_tree: bool = false) -> StrikeZoneScript:
	var zone: StrikeZoneScript = scene.instantiate() as StrikeZoneScript
	zone.m_per_cm = 0.1745
	zone.width_m = 8.0
	zone.rng.seed = 5
	_nodes.append(zone)
	if in_tree:
		tree.root.add_child(zone)
	else:
		zone.start()
	return zone


## Runs the zone's clock until `phase` begins; returns the seconds it took (-1 if never).
func _until_phase(zone: StrikeZoneScript, phase: StrikeZoneScript.Phase, limit_s: float = 30.0) -> float:
	var t: float = 0.0
	while t < limit_s:
		if zone.phase == phase:
			return t
		zone.step(DT)
		t += DT
	return -1.0


# --- The wiggle -----------------------------------------------------------------------------------

func test_the_wiggle_counts_alternations_like_the_prologue() -> void:
	var wiggle: WiggleScript = WiggleScript.new(4)
	check(not wiggle.press(1) and not wiggle.press(1) and not wiggle.press(1), "the same direction again and again counts once")
	check_eq(wiggle.count, 1, "one")
	check(not wiggle.press(-1), "left: two")
	check(not wiggle.press(1), "right: three")
	check(wiggle.press(-1), "left: four, free")
	check(wiggle.done() and wiggle.progress() == 1.0, "done")
	wiggle.reset()
	check(wiggle.count == 0 and wiggle.progress() == 0.0, "reset")
	check(not WiggleScript.new(0).done(), "at least one press is always needed")
	var same: WiggleScript = WiggleScript.new(3)
	for dir: int in [1, -1, -1, 1]:
		same.press(dir)
	check_eq(same.count, 3, "1, -1, -1, 1 is three alternations (the prologue's rule)")


func test_the_stick_data_is_slow_to_wiggle_and_has_three_ways_out() -> void:
	var def: StickDefScript = load("res://data/hazards/gum.tres") as StickDefScript
	var chopsticks: Resource = load("res://data/hazards/chopsticks.tres")
	check(def.wiggle_required > int(chopsticks.get("wiggle_required")) * 2, "the gum wiggle (%d) is much slower than the chopsticks' (%d)" % [def.wiggle_required, int(chopsticks.get("wiggle_required"))])
	check_eq(def.enemy_hits_required, 3, "three enemy hits")
	check_eq(def.timeout_s, 10.0, "ten seconds as a last resort")
	check(def.rearm_s > 0.0, "the patch rests a few seconds after")
	var prologue: Resource = load("res://data/prologue/prologue.tres")
	check(int(chopsticks.get("wiggle_required")) < int(prologue.get("required_alternations")), "the chopsticks' wiggle is easier than the prologue's pick")


func test_stuck_is_freed_by_the_wiggle() -> void:
	var def: StickDefScript = load("res://data/hazards/gum.tres") as StickDefScript
	var status: StuckStatusScript = StuckStatusScript.new(def)
	for i: int in def.wiggle_required - 1:
		status.press(1 if i % 2 == 0 else -1)
	check(not status.released, "one press short: still stuck")
	status.press(1 if (def.wiggle_required - 1) % 2 == 0 else -1)
	check(status.released and status.reason == "wiggle", "free by wiggling")


func test_stuck_is_freed_by_three_enemy_hits_a_few_at_a_time() -> void:
	var def: StickDefScript = load("res://data/hazards/gum.tres") as StickDefScript
	var status: StuckStatusScript = StuckStatusScript.new(def)
	status.enemy_hit()
	status.enemy_hit()
	check(not status.released, "two hits: not yet")
	status.enemy_hit()
	check(status.released and status.reason == "enemy_hits", "the third hit frees him")


func test_stuck_is_freed_after_ten_seconds() -> void:
	var def: StickDefScript = load("res://data/hazards/gum.tres") as StickDefScript
	var status: StuckStatusScript = StuckStatusScript.new(def)
	var t: float = 0.0
	while not status.released and t < 20.0:
		status.tick(DT)
		t += DT
	check(status.released and status.reason == "timeout", "the fallback")
	check(absf(t - def.timeout_s) < 0.05, "after %.2f s (data: %.0f s)" % [t, def.timeout_s])


func test_the_first_way_out_wins_and_later_ones_do_nothing() -> void:
	var status: StuckStatusScript = StuckStatusScript.new(load("res://data/hazards/gum.tres") as StickDefScript)
	status.enemy_hit()
	status.enemy_hit()
	status.enemy_hit()
	status.press(1)
	status.tick(100.0)
	check_eq(status.reason, "enemy_hits", "the reason stays the first one")


# --- Stuck on the player --------------------------------------------------------------------------

func test_a_stuck_player_cannot_walk_jump_or_roll() -> void:
	var player: DdeokScript = _player()
	player.game_state.unlock_skill("jump")
	var def: StickDefScript = load("res://data/hazards/gum.tres") as StickDefScript
	check(player.request_roll(), "(a free player can roll)")
	player.state = DdeokScript.State.IDLE
	player.set("_roll_cooldown", 0.0)
	check(player.apply_stick(def), "the gum sticks")
	check(player.is_stuck(), "stuck")
	check(not player.apply_stick(def), "already stuck: nothing happens twice")
	player.velocity = Vector3.ZERO
	player.call("_step_free", DT, 1.0)
	check_eq(player.velocity.x, 0.0, "pushing right: no walking")
	player.set("_buffer_timer", 0.1)
	player.grounded = true
	player.call("_step_free", DT, 0.0)
	check(player.velocity.y <= 0.0, "a buffered jump does nothing")
	check(not player.request_roll(), "no rolling")
	player.stuck = null
	player.set("_buffer_timer", 0.1)
	player.call("_step_free", DT, 0.0)
	check(player.velocity.y > 0.0, "free again: the same buffered jump works")


func test_the_gum_costs_no_hearts() -> void:
	var gs: GameStateScript = _gs()
	var player: DdeokScript = _player(gs)
	var gum: Node = _gum()
	gum.set("target_player", player)
	gum.call("tick", DT)
	check(player.is_stuck(), "stuck on contact")
	check_eq(gs.hearts, GameStateScript.MAX_HEARTS, "and no damage")


func test_hits_on_a_stuck_player_free_him_three_at_a_time_and_still_hurt() -> void:
	var gs: GameStateScript = _gs()
	var player: DdeokScript = _player(gs)
	var released: Array[String] = []
	player.stick_released.connect(func(reason: String) -> void: released.append(reason))
	player.apply_stick(load("res://data/hazards/gum.tres") as StickDefScript)
	for hit: int in 3:
		player.set("_invuln_timer", 0.0)
		check(player.hurt(2, 0.0), "hit %d lands" % (hit + 1))
		player.call("_step_stick", DT)
		check_eq(player.is_stuck(), hit < 2, "after %d hits he is %s" % [hit + 1, "still stuck" if hit < 2 else "free"])
	check_eq(released, ["enemy_hits"] as Array[String], "released by the hits")
	check_eq(gs.hearts, GameStateScript.MAX_HEARTS - 6, "the hits still cost their hearts")


func test_a_hit_during_the_invulnerable_moment_does_not_count() -> void:
	var player: DdeokScript = _player()
	player.apply_stick(load("res://data/hazards/gum.tres") as StickDefScript)
	player.set("_invuln_timer", 0.0)
	player.hurt(2, 0.0)
	player.hurt(2, 0.0)
	player.hurt(2, 0.0)
	check_eq(player.stuck.hits, 1, "only the first one counted")


func test_the_player_gets_free_by_wiggling_and_after_ten_seconds() -> void:
	var player: DdeokScript = _player()
	var def: StickDefScript = load("res://data/hazards/gum.tres") as StickDefScript
	var released: Array[String] = []
	player.stick_released.connect(func(reason: String) -> void: released.append(reason))
	player.apply_stick(def)
	for i: int in def.wiggle_required:
		player.stuck.press(1 if i % 2 == 0 else -1)
	player.call("_step_stick", DT)
	check(not player.is_stuck() and released == ["wiggle"], "wiggled free: " + str(released))
	player.apply_stick(def)
	for i: int in int(def.timeout_s / 0.5) + 2:
		player.call("_step_stick", 0.5)
	check(not player.is_stuck() and released == ["wiggle", "timeout"], "freed after the timer: " + str(released))


# --- The gum patch --------------------------------------------------------------------------------

func test_a_gum_patch_sticks_him_once_and_is_used_up_for_a_while() -> void:
	var player: DdeokScript = _player()
	var gum: Node = _gum()
	var def: StickDefScript = load("res://data/hazards/gum.tres") as StickDefScript
	gum.set("target_player", player)
	gum.call("tick", DT)
	check(player.is_stuck() and gum.get("holding"), "stuck on it")
	for i: int in def.wiggle_required:
		player.stuck.press(1 if i % 2 == 0 else -1)
	player.call("_step_stick", DT)
	gum.call("tick", DT)
	check(not player.is_stuck(), "free")
	check(not gum.get("holding") and not gum.get("armed"), "the patch is used up")
	check_eq(gum.get("rearm_left"), def.rearm_s, "for the time the data says")
	for i: int in 30:
		gum.call("tick", DT)
	check(not player.is_stuck(), "standing in a used-up patch does nothing")
	for i: int in int(def.rearm_s / DT) + 5:
		gum.call("tick", DT)
	check(player.is_stuck(), "once it has rested, he is still standing in it: stuck again")


func test_jumping_over_the_gum_avoids_it() -> void:
	var player: DdeokScript = _player()
	var gum: Node = _gum()
	gum.set("target_player", null)
	for i: int in 60:
		gum.call("tick", DT)
	check(not player.is_stuck() and gum.get("armed"), "never in it: never stuck, still armed")


func test_a_disabled_gum_patch_does_nothing() -> void:
	var player: DdeokScript = _player()
	var gum: Node = _gum()
	gum.set("target_player", player)
	gum.set("enabled", false)
	gum.call("tick", DT)
	check(not player.is_stuck(), "disabled")


func test_the_three_ways_out_work_on_a_real_patch_too() -> void:
	var def: StickDefScript = load("res://data/hazards/gum.tres") as StickDefScript
	for way: String in ["wiggle", "enemy_hits", "timeout"]:
		var player: DdeokScript = _player()
		var gum: Node = _gum()
		gum.set("target_player", player)
		gum.call("tick", DT)
		match way:
			"wiggle":
				for i: int in def.wiggle_required:
					player.stuck.press(1 if i % 2 == 0 else -1)
			"enemy_hits":
				for i: int in def.enemy_hits_required:
					player.stuck.enemy_hit()
			"timeout":
				player.stuck.tick(def.timeout_s + 0.1)
		player.call("_step_stick", DT)
		gum.call("tick", DT)
		check(not player.is_stuck() and not gum.get("armed"), "%s: free, patch used up" % way)


# --- Chopsticks -----------------------------------------------------------------------------------

func test_chopsticks_timings_come_from_the_data() -> void:
	var def: Resource = load("res://data/hazards/chopsticks.tres")
	check(absf(float(def.get("telegraph_s")) - 0.8) < 0.3, "a telegraph of about 0.8 s (%.2f)" % float(def.get("telegraph_s")))
	check(float(def.get("cooldown_max_s")) > float(def.get("cooldown_min_s")), "a random cooldown between two values")
	check_eq(int(def.get("damage_half_hearts")), 1, "half a heart")
	var zone: StrikeZoneScript = _zone(ChopsticksScene)
	var cooldowns: Array[float] = []
	for i: int in 12:
		var t: float = _until_phase(zone, StrikeZoneScript.Phase.TELEGRAPH)
		check(t >= 0.0, "a telegraph comes")
		cooldowns.append(t)
		var telegraph: float = _until_phase(zone, StrikeZoneScript.Phase.STRIKE)
		check(absf(telegraph - float(def.get("telegraph_s"))) < 0.05, "the shadow warns %.2f s" % telegraph)
		var hold: float = _until_phase(zone, StrikeZoneScript.Phase.RECOVER)
		check(absf(hold - float(def.get("strike_hold_s"))) < 0.05, "the strike lasts %.2f s" % hold)
		var recover: float = _until_phase(zone, StrikeZoneScript.Phase.COOLDOWN)
		check(absf(recover - float(def.get("recover_s"))) < 0.05, "it goes back up in %.2f s" % recover)
	var distinct: Dictionary = {}
	for c: float in cooldowns:
		check(c >= float(def.get("cooldown_min_s")) - 0.05 and c <= float(def.get("cooldown_max_s")) + 0.05 + float(def.get("recover_s")), "cooldown %.2f within the data's range" % c)
		distinct[snappedf(c, 0.1)] = true
	check(distinct.size() > 3, "with jitter: the waits differ (%d kinds)" % distinct.size())
	check_eq(zone.strikes, 12, "twelve strikes")


func test_the_chopsticks_strike_pinches_for_half_a_heart_and_grabs() -> void:
	var gs: GameStateScript = _gs()
	var player: DdeokScript = _player(gs)
	var zone: StrikeZoneScript = _zone(ChopsticksScene)
	zone.position = Vector3(0.0, 0.0, 0.0)
	player.position = Vector3(1.0, 0.32, 0.0)
	zone.target_player = player
	_until_phase(zone, StrikeZoneScript.Phase.TELEGRAPH)
	check(absf(zone.strike_x - 1.0) < 0.01, "the shadow settles where he stands (aim): %.2f" % zone.strike_x)
	_until_phase(zone, StrikeZoneScript.Phase.STRIKE)
	check_eq(gs.hearts, GameStateScript.MAX_HEARTS - 1, "half a heart")
	check(zone.get("held"), "it holds him")
	check_eq(player.held_by, zone, "he knows who holds him")
	check(player.controlled, "no input, no physics")
	check(not zone.call("_busy") == false, "the clock waits while it holds him")


func test_a_strike_that_misses_hurts_nobody() -> void:
	var gs: GameStateScript = _gs()
	var player: DdeokScript = _player(gs)
	var zone: StrikeZoneScript = _zone(ChopsticksScene)
	player.position = Vector3(40.0, 0.32, 0.0)
	zone.target_player = player
	_until_phase(zone, StrikeZoneScript.Phase.STRIKE)
	check_eq(gs.hearts, GameStateScript.MAX_HEARTS, "he stood elsewhere")
	check(not zone.get("held"), "nothing held")
	check(zone.strike_x >= zone.zone_left() and zone.strike_x <= zone.zone_right(), "it struck somewhere in its zone")


func test_he_wiggles_free_with_a_few_presses_and_is_safe_while_held() -> void:
	var gs: GameStateScript = _gs()
	var player: DdeokScript = _player(gs)
	var zone: StrikeZoneScript = _zone(ChopsticksScene)
	var def: Resource = load("res://data/hazards/chopsticks.tres")
	player.position = Vector3(0.0, 0.32, 0.0)
	zone.target_player = player
	_until_phase(zone, StrikeZoneScript.Phase.STRIKE)
	var hearts: int = gs.hearts
	check(zone.get("held"), "held")
	player.set("_invuln_timer", 0.0)
	check(not player.hurt(2, 0.0), "while he is held nothing hurts him")
	check(not player.smoosh(2, 0.5), "not even a foot")
	check_eq(gs.hearts, hearts, "no further damage")
	var y: float = player.position.y
	zone.call("step_hold", 0.5)
	check(player.position.y > y, "it lifts him")
	var presses: int = int(def.get("wiggle_required"))
	for i: int in presses - 1:
		zone.call("wiggle_press", 1 if i % 2 == 0 else -1)
	check(zone.get("held"), "one press short")
	zone.call("wiggle_press", 1 if (presses - 1) % 2 == 0 else -1)
	check(not zone.get("held"), "free after %d presses" % presses)
	check(player.held_by == null and not player.controlled, "he is his own again")


func test_the_chopsticks_let_go_after_a_while_if_he_does_not_wiggle() -> void:
	var player: DdeokScript = _player()
	var zone: StrikeZoneScript = _zone(ChopsticksScene)
	var def: Resource = load("res://data/hazards/chopsticks.tres")
	var reasons: Array[String] = []
	zone.connect("released", func(reason: String) -> void: reasons.append(reason))
	player.position = Vector3(0.0, 0.32, 0.0)
	zone.target_player = player
	_until_phase(zone, StrikeZoneScript.Phase.STRIKE)
	zone.call("step_hold", float(def.get("hold_max_s")) + 0.1)
	check_eq(reasons, ["timeout"] as Array[String], "let go")
	check(not zone.get("held") and not player.controlled, "free")


func test_the_chopsticks_lift_a_mandu_away_and_leave_a_tutorial_wheel() -> void:
	var gs: GameStateScript = _gs()
	var zone: StrikeZoneScript = _zone(ChopsticksScene, true)
	zone.position = Vector3(0.0, 0.0, 0.0)
	var mandu: Node3D = (load("res://enemies/mandu.tscn") as PackedScene).instantiate() as Node3D
	mandu.set("game_state", gs)
	tree.root.add_child(mandu)
	_nodes.append(mandu)
	mandu.global_position = Vector3(0.5, 0.0, 0.0)
	var wheel: Node3D = (load("res://enemies/danmuji.tscn") as PackedScene).instantiate() as Node3D
	wheel.set("game_state", gs)
	tree.root.add_child(wheel)
	_nodes.append(wheel)
	wheel.global_position = Vector3(1.0, 0.0, 0.0)
	zone.strike_x = 0.7
	zone.call("_on_strike")
	check(not mandu.get("alive"), "the 만두 in the zone is taken")
	check((mandu as CharacterBody3D).collision_layer == 0, "no longer solid")
	check(wheel.get("alive"), "a 단무지 is not on its list")
	check(gs.defeated_enemies.is_empty() and mandu.get("last_drops").is_empty(), "taken away is not defeated: no drop, no credit")


func test_chopsticks_do_nothing_when_turned_off() -> void:
	var zone: StrikeZoneScript = _zone(ChopsticksScene)
	zone.set_enabled(false)
	for i: int in 2000:
		zone.step(DT)
	check_eq(zone.strikes, 0, "quiet")
	zone.set_enabled(true)
	check(_until_phase(zone, StrikeZoneScript.Phase.STRIKE) >= 0.0, "and back on")


# --- The giant foot -------------------------------------------------------------------------------

func test_the_foot_numbers_come_from_the_data() -> void:
	var def: Resource = load("res://data/hazards/giant_foot.tres")
	check(absf(float(def.get("telegraph_s")) - 1.0) < 0.3, "a telegraph of about 1 s (%.2f)" % float(def.get("telegraph_s")))
	check_eq(int(def.get("damage_half_hearts")), 2, "1 heart")
	check(absf(float(def.get("stun_s")) - 0.6) < 0.2, "a stun of about 0.6 s (%.2f)" % float(def.get("stun_s")))
	check(int(def.get("damage_half_hearts")) < GameStateScript.MAX_HEARTS, "not an instant kill")
	var zone: StrikeZoneScript = _zone(GiantFootScene)
	_until_phase(zone, StrikeZoneScript.Phase.TELEGRAPH)
	var telegraph: float = _until_phase(zone, StrikeZoneScript.Phase.STRIKE)
	check(absf(telegraph - float(def.get("telegraph_s"))) < 0.05, "the shadow warns %.2f s before the foot" % telegraph)


func test_the_foot_smooshes_for_a_heart_and_a_flat_stun_then_he_pops_back() -> void:
	var gs: GameStateScript = _gs()
	var player: DdeokScript = _player(gs)
	var zone: StrikeZoneScript = _zone(GiantFootScene)
	var def: Resource = load("res://data/hazards/giant_foot.tres")
	player.position = Vector3(0.0, 0.32, 0.0)
	zone.target_player = player
	_until_phase(zone, StrikeZoneScript.Phase.STRIKE)
	check_eq(gs.hearts, GameStateScript.MAX_HEARTS - int(def.get("damage_half_hearts")), "one heart")
	check_eq(player.flat_left, float(def.get("stun_s")), "flat for the data's time")
	check(gs.hearts > 0 and not gs.is_dead(), "alive")
	player.state = DdeokScript.State.IDLE
	player.velocity = Vector3(3.0, 0.0, 0.0)
	player.call("_step_flat", DT)
	check_eq(player.velocity.x, 0.0, "while flat he cannot move")
	player.call("_tick_timers", float(def.get("stun_s")) - 0.01)
	check(player.flat_left > 0.0, "still flat just before the end")
	player.call("_tick_timers", 0.02)
	check_eq(player.flat_left, 0.0, "then he pops back")


func test_a_second_foot_during_the_stun_does_not_stack() -> void:
	var gs: GameStateScript = _gs()
	var player: DdeokScript = _player(gs)
	check(player.smoosh(2, 0.6), "the first lands")
	check(not player.smoosh(2, 0.6), "the second finds him invulnerable")
	check_eq(gs.hearts, GameStateScript.MAX_HEARTS - 2, "once")


func test_the_foot_crushes_a_mandu_and_knocks_a_wheel_over() -> void:
	var gs: GameStateScript = _gs()
	var zone: StrikeZoneScript = _zone(GiantFootScene, true)
	zone.position = Vector3(0.0, 0.0, 0.0)
	var mandu: Node3D = (load("res://enemies/mandu.tscn") as PackedScene).instantiate() as Node3D
	mandu.set("game_state", gs)
	tree.root.add_child(mandu)
	_nodes.append(mandu)
	mandu.global_position = Vector3(0.2, 0.0, 0.0)
	var wheel: Node3D = (load("res://enemies/danmuji.tscn") as PackedScene).instantiate() as Node3D
	wheel.set("game_state", gs)
	tree.root.add_child(wheel)
	_nodes.append(wheel)
	wheel.global_position = Vector3(-0.8, 0.0, 0.0)
	var far: Node3D = (load("res://enemies/mandu.tscn") as PackedScene).instantiate() as Node3D
	far.set("game_state", gs)
	tree.root.add_child(far)
	_nodes.append(far)
	far.global_position = Vector3(20.0, 0.0, 0.0)
	zone.strike_x = 0.0
	zone.call("_on_strike")
	check(not mandu.get("alive"), "the 만두 under it dies")
	check(wheel.get("flat") and not wheel.get("alive"), "the 단무지 is knocked over")
	check(far.get("alive"), "one outside the foot is fine")
	check_eq(zone.get("crushed"), 2, "two crushed")


func test_the_foot_does_nothing_when_turned_off() -> void:
	var zone: StrikeZoneScript = _zone(GiantFootScene)
	zone.set_enabled(false)
	for i: int in 3000:
		zone.step(DT)
	check_eq(zone.strikes, 0, "quiet")


func test_a_zone_with_no_def_and_a_zone_too_narrow_for_its_strike_stay_safe() -> void:
	var zone: StrikeZoneScript = _zone(ChopsticksScene)
	zone.width_m = 0.2
	zone.position = Vector3(5.0, 0.0, 0.0)
	_until_phase(zone, StrikeZoneScript.Phase.TELEGRAPH)
	check_eq(zone.strike_x, 5.0, "a zone narrower than the strike strikes in its middle")
