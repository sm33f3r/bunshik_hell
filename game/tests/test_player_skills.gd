extends "res://tests/base_test.gd"
## Skill gating on fresh player instances. No scene tree, no physics, no autoloads:
## the GameState is injected and `grounded` is set by hand.

const DdeokScript := preload("res://player/ddeok.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")


func _make(gs: GameStateScript) -> DdeokScript:
	var p: DdeokScript = DdeokScript.new()
	p.game_state = gs
	p.tuning = load("res://data/movement_tuning.tres") as MovementTuningScript
	return p


func test_state_machine_has_the_nine_states() -> void:
	var names: Array[String] = ["idle", "squiggle", "jump", "fall", "stomp", "roll", "slam", "hurt", "dead"]
	check_eq(DdeokScript.STATE_NAMES, names, "state names")
	check_eq(DdeokScript.State.size(), 9, "state count")


func test_ground_roll_is_gated_by_the_roll_skill() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var p: DdeokScript = _make(gs)
	p.grounded = true
	check_eq(p.request_roll(), false, "roll refused while locked")
	check_eq(p.state, DdeokScript.State.IDLE, "state unchanged while locked")
	check_eq(p.velocity, Vector3.ZERO, "velocity unchanged while locked")
	gs.unlock_skill("roll")
	check_eq(p.request_roll(), true, "roll starts once unlocked")
	check_eq(p.state, DdeokScript.State.ROLL, "state is roll")
	check_eq(absf(p.velocity.x), p.tuning.roll_speed, "roll speed comes from tuning")
	p.free()
	gs.free()


func test_air_roll_is_a_slam_gated_by_the_slam_skill() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var p: DdeokScript = _make(gs)
	p.grounded = false
	p.state = DdeokScript.State.FALL
	gs.unlock_skill("roll") # roll alone must not give a slam
	check_eq(p.request_roll(), false, "slam refused while locked, even with roll")
	check_eq(p.state, DdeokScript.State.FALL, "state unchanged while slam locked")
	gs.unlock_skill("slam")
	check_eq(p.request_roll(), true, "slam starts once unlocked")
	check_eq(p.state, DdeokScript.State.SLAM, "state is slam")
	check_eq(p.velocity.y, -p.tuning.slam_speed, "slam speed comes from tuning")
	p.free()
	gs.free()


func test_slam_does_not_unlock_the_ground_roll() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var p: DdeokScript = _make(gs)
	gs.unlock_skill("slam")
	p.grounded = true
	check_eq(p.request_roll(), false, "ground roll still needs the roll skill")
	p.free()
	gs.free()


func test_relocking_takes_the_ability_away_again() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var p: DdeokScript = _make(gs)
	p.grounded = true
	gs.unlock_skill("roll")
	gs.skills["roll"] = false
	check_eq(p.request_roll(), false, "roll refused after relock")
	p.free()
	gs.free()


func test_stomp_needs_the_air_and_the_skill() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var p: DdeokScript = _make(gs)
	p.grounded = true
	check_eq(p.request_stomp(), false, "no stomp on the ground")
	p.grounded = false
	p.state = DdeokScript.State.FALL
	gs.skills["stomp"] = false
	check_eq(p.request_stomp(), false, "no stomp while locked")
	check_eq(p.state, DdeokScript.State.FALL, "state unchanged while stomp locked")
	gs.unlock_skill("stomp")
	check_eq(p.request_stomp(), true, "stomp starts in the air")
	check_eq(p.state, DdeokScript.State.STOMP, "state is stomp")
	check_eq(p.velocity.y, -p.tuning.stomp_speed, "stomp speed comes from tuning")
	p.free()
	gs.free()


func test_no_new_attack_while_dead_or_already_diving() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.unlock_skill("roll")
	gs.unlock_skill("slam")
	var p: DdeokScript = _make(gs)
	p.state = DdeokScript.State.DEAD
	p.grounded = true
	check_eq(p.request_roll(), false, "dead cannot roll")
	p.grounded = false
	check_eq(p.request_stomp(), false, "dead cannot stomp")
	p.state = DdeokScript.State.SLAM
	check_eq(p.request_stomp(), false, "slam cannot become a stomp")
	check_eq(p.request_roll(), false, "slam cannot restart")
	p.free()
	gs.free()
