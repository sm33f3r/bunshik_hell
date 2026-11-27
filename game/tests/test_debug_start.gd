extends "res://tests/base_test.gd"
## The debug command-line options --start-at / --screenshot (systems/debug_start.gd): parsing, and the
## state a start-at session begins with. Fresh instances only; no autoload.

const DebugStartScript := preload("res://systems/debug_start.gd")
const MapFlowScript := preload("res://maps/layout/map_flow.gd")
const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")

var _nodes: Array[Object] = []


func after_each() -> void:
	for node: Object in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _layout() -> MapLayoutScript:
	return load(MapFlowScript.LAYOUT_PATH) as MapLayoutScript


func _flow() -> MapFlowScript:
	var data: PrologueDataScript = load("res://data/prologue/prologue.tres") as PrologueDataScript
	var flow: MapFlowScript = MapFlowScript.new()
	_nodes.append(flow)
	flow.layout = _layout()
	flow.reach = JumpReachScript.new(load(MapFlowScript.TUNING_PATH), load(MapFlowScript.WHEEL_DEF_PATH), data.m_per_cm())
	flow.index_layout({"left": data.next_table_min_x, "right": data.next_table_max_x, "top": data.next_table_top_y,
		"thickness": data.dims().next_table_thickness_cm * data.m_per_cm()})
	return flow


func _state() -> GameStateScript:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	return gs


func _parse(args: Array, debug_build: bool = true) -> Dictionary:
	return DebugStartScript.parse(PackedStringArray(args), _layout(), debug_build)


func test_a_known_checkpoint_or_steamer_id_is_accepted() -> void:
	for id: String in ["kitchen_front_start", "map01_dining_mid"]:
		var got: Dictionary = _parse(["--start-at=" + id])
		check_eq(got["id"], id, "accepted")
		check_eq(got["error"], "", "no error")
	var shot: Dictionary = _parse(["--start-at=kitchen_front_start", "--screenshot=user://a.png"])
	check_eq(shot["screenshot"], "user://a.png", "the screenshot path")
	check_eq(shot["error"], "", "no error with both")


func test_an_unknown_id_is_a_clear_error_and_starts_nothing() -> void:
	for bad: String in ["nowhere", ""]:
		var got: Dictionary = _parse(["--start-at=" + bad])
		check_eq(got["id"], "", "nothing to start")
		check("unknown id '%s'" % bad in got["error"], "says what was wrong: " + got["error"])
		check("kitchen_front_start" in got["error"], "and lists the known ids")


func test_screenshot_alone_is_an_error_and_no_option_is_nothing() -> void:
	check("--start-at" in _parse(["--screenshot=user://a.png"])["error"], "it needs --start-at")
	var none: Dictionary = _parse(["--spawn-pick=ganjang_bottle:under_last_table_left"])
	check_eq(none, {"id": "", "screenshot": "", "error": ""}, "other options are left alone")


func test_a_release_build_ignores_both_options() -> void:
	var got: Dictionary = _parse(["--start-at=kitchen_front_start", "--screenshot=user://a.png"], false)
	check_eq(got, {"id": "", "screenshot": "", "error": ""}, "nothing")


func test_start_at_a_checkpoint_is_a_new_game_that_respawns_there() -> void:
	var flow: MapFlowScript = _flow()
	var gs: GameStateScript = _state()
	gs.hearts = 3
	gs.ddeok = 50
	DebugStartScript.apply(gs, flow, "kitchen_front_start")
	check_eq(gs.hearts, GameStateScript.MAX_HEARTS, "a new game")
	check_eq(gs.ddeok, 0, "nothing carried over")
	check_eq(gs.checkpoint_id, "kitchen_front_start", "the respawn point")
	var at: Vector3 = LayoutGeometryScript.checkpoint_position(flow.placed, flow.layout.find_checkpoint("kitchen_front_start"))
	check(gs.checkpoint_position.distance_to(at) < 0.001, "at the checkpoint's place")
	check(gs.prologue_complete and gs.tutorial_done, "the prologue and tutorial are behind him")
	check(gs.has_skill("roll") and gs.has_skill("slam"), "with the tutorial's skills")
	check(gs.reached_checkpoints.has("map01_dining_start"), "earlier checkpoints count as reached")
	check_eq(gs.respawn(), gs.checkpoint_position, "dying brings him back there")


func test_start_at_a_steamer_is_the_state_after_using_it() -> void:
	var gs: GameStateScript = _state()
	DebugStartScript.apply(gs, _flow(), "map01_dining_mid")
	check_eq(gs.checkpoint_id, "map01_dining_mid", "the respawn point")
	check_eq(gs.respawn_type, GameStateScript.RESPAWN_JJIGI, "a 찜기")
	check(gs.is_jjigi_used("map01_dining_mid"), "used, like any 찜기 he respawns at")
	check(not gs.reached_checkpoints.has("kitchen_front_start"), "nothing further on is reached")
