extends "res://tests/base_test.gd"
## Task 3b-ii-fix2: nothing the way on needs can be used up. For every 단무지 of the map and every way of
## wasting it (killed, knocked flat toward either end, fallen off its table) the way on must still be
## there, or the entry is required_for_progress and the way is back after its respawn_delay_s. Uses the
## same hop rules as the layout validation (ProgressGraph on top of JumpReach), and the real layout data.
## Also: the first ledge has two independent ways up, the respawn rule of MapFlow, and that the prologue's
## exit does not depend on anything that is used up.

const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const MapSectionScript := preload("res://maps/layout/map_section.gd")
const PlatformDefScript := preload("res://maps/layout/platform_def.gd")
const SpawnEntryScript := preload("res://maps/layout/spawn_entry.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const ProgressGraphScript := preload("res://maps/layout/progress_graph.gd")
const MapFlowScript := preload("res://maps/layout/map_flow.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const DirectorScript := preload("res://prologue/prologue_director.gd")
const GameStateScript := preload("res://systems/game_state.gd")

const LAYOUT_PATH: String = "res://data/maps/ep01/map01_layout.tres"
const WHEEL_PATH: String = "res://data/enemies/danmuji.tres"

var _nodes: Array[Object] = []


func after_each() -> void:
	for node: Object in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _layout() -> MapLayoutScript:
	return load(LAYOUT_PATH) as MapLayoutScript


func _data() -> PrologueDataScript:
	return load("res://data/prologue/prologue.tres") as PrologueDataScript


func _wheel_def() -> EnemyDefScript:
	return load(WHEEL_PATH) as EnemyDefScript


func _reach() -> JumpReachScript:
	return JumpReachScript.new(load("res://data/movement_tuning.tres") as MovementTuningScript, _wheel_def(), _data().m_per_cm())


func _anchor() -> Dictionary:
	var d: PrologueDataScript = _data()
	return {"left": d.next_table_min_x, "right": d.next_table_max_x, "top": d.next_table_top_y,
		"thickness": d.dims().next_table_thickness_cm * d.m_per_cm()}


func _placed(layout: MapLayoutScript) -> Array[LayoutGeometryScript.Placed]:
	return LayoutGeometryScript.resolve(layout, _reach(), _anchor())


func _problems(layout: MapLayoutScript) -> Array[String]:
	return ProgressGraphScript.problems(layout, _placed(layout), _reach(), _wheel_def())


## A private copy of the layout with `edit` applied (the real data stays as it is).
func _with(edit: Callable) -> MapLayoutScript:
	var copy: MapLayoutScript = _layout().duplicate(true) as MapLayoutScript
	edit.call(copy)
	return copy


func _entry(layout: MapLayoutScript, group: String) -> SpawnEntryScript:
	for section: MapSectionScript in layout.sections:
		for entry: SpawnEntryScript in section.spawns:
			if entry.group == group and ProgressGraphScript.is_wheel(entry):
				return entry
	return null


func _mentions(lines: Array[String], needle: String) -> bool:
	for line: String in lines:
		if needle in line:
			return true
	return false


func _flow() -> MapFlowScript:
	var flow: MapFlowScript = MapFlowScript.new()
	_nodes.append(flow)
	flow.game_state = GameStateScript.new()
	_nodes.append(flow.game_state)
	flow.layout = _layout()
	flow.reach = _reach()
	flow.index_layout(_anchor())
	return flow


func _wheel_at(x: float, y: float, flat: bool, alive: bool = true) -> Node3D:
	var node: Node3D = (load("res://enemies/danmuji.tscn") as PackedScene).instantiate() as Node3D
	_nodes.append(node)
	node.position = Vector3(x, y, 0.0)
	node.set("flat", flat)
	node.set("alive", alive)
	return node


# --- The whole map -----------------------------------------------------------------------------------

func test_no_wasted_wheel_anywhere_in_the_map_leaves_no_way_on() -> void:
	var problems: Array[String] = _problems(_layout())
	check(problems.is_empty(), "soft-locks:\n        " + "\n        ".join(problems))


func test_with_every_wheel_in_place_the_whole_way_is_open() -> void:
	var layout: MapLayoutScript = _layout()
	var blocked: Array[String] = ProgressGraphScript.unreachable(layout, _placed(layout), _reach(), {})
	check(blocked.is_empty(), "cut off: " + str(blocked))


func test_every_wheel_the_tutorial_needs_is_marked_required_and_has_a_delay() -> void:
	var layout: MapLayoutScript = _layout()
	var required: Array[String] = []
	for entry: SpawnEntryScript in ProgressGraphScript.required_entries(layout):
		required.append(entry.group)
		check(entry.respawn_delay_s > 0.0, "%s has a respawn delay" % entry.group)
	check_eq(required, ["c1", "c2"] as Array[String], "the two wheels of beat c (the bounce and the roll platform)")
	check_eq(_entry(layout, "c1").respawn_delay_s, 4.0, "c1 comes back after 4 s (data)")
	check_eq(_entry(layout, "c2").respawn_delay_s, 4.0, "so does c2")
	check(not _entry(layout, "c1").usable_when_flat, "a flat first wheel is spent: it springs back (rolling it must not cost the bounce)")
	check(_entry(layout, "c2").usable_when_flat, "a flat second wheel is the platform and stays until he has left the beat")


func test_the_checker_finds_a_wheel_the_way_depends_on_but_nobody_respawns() -> void:
	var layout: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_entry(l, "c1").required_for_progress = false)
	var problems: Array[String] = _problems(layout)
	check(_mentions(problems, "wheel 'c1'") and _mentions(problems, "not required_for_progress"), "named: " + str(problems))
	check(_mentions(problems, killed_text()), "killing it is one of the ways: " + str(problems))
	check(_mentions(problems, ProgressGraphScript.FELL_OFF), "so is a fall")
	var layout2: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_entry(l, "c2").required_for_progress = false)
	check(_mentions(_problems(layout2), "wheel 'c2'"), "and the second wheel the same way")


func killed_text() -> String:
	return ProgressGraphScript.KILLED


func test_the_checker_finds_a_respawn_that_does_not_bring_the_way_back() -> void:
	var layout: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		_entry(l, "c1").respawn_delay_s = 0.0)
	check(_mentions(_problems(layout), "needs a respawn_delay_s"), "a required wheel without a delay: " + str(_problems(layout)))
	var cut: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		var section: MapSectionScript = l.section("tutorial")
		var kept: Array[SpawnEntryScript] = []
		for entry: SpawnEntryScript in section.spawns:
			if entry.group != "c1":
				kept.append(entry)
		section.spawns = kept)
	check(_mentions(_problems(cut), "the way on is cut"), "no first wheel at all cuts the way: " + str(_problems(cut)))


func test_the_other_sections_never_need_a_wheel() -> void:
	# Every wheel of the dining room can be wasted any way: the way through its tables needs none of them.
	var layout: MapLayoutScript = _layout()
	var placed: Array[LayoutGeometryScript.Placed] = _placed(layout)
	var all_gone: Dictionary = {}
	for entry: SpawnEntryScript in ProgressGraphScript.wheel_entries(layout):
		all_gone[entry] = ProgressGraphScript.GONE
	var sections: Array[String] = ["dining_room_start", "dining_room"]
	var blocked: Array[String] = ProgressGraphScript.unreachable(layout, placed, _reach(), all_gone, "dining_1", sections)
	check(blocked.is_empty(), "with every wheel gone the dining room's tables are still all reachable from its first: " + str(blocked))
	for section_id: String in sections:
		for entry: SpawnEntryScript in layout.section(section_id).spawns:
			check(not entry.required_for_progress, "'%s' in %s needs no respawn rule" % [entry.group, section_id])


# --- The first ledge: two independent ways up ---------------------------------------------------------

func test_the_first_ledge_has_two_independent_ways_up_and_neither_is_a_plain_jump() -> void:
	var layout: MapLayoutScript = _layout()
	var placed: Array[LayoutGeometryScript.Placed] = _placed(layout)
	var reach: JumpReachScript = _reach()
	var c1: SpawnEntryScript = _entry(layout, "c1")
	var ledge: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "tut_ledge1")
	var box: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "tut_box")
	var table: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "tut_t2")
	check(box != null and box.prev == table, "a napkin box stands on the table next to the ledge")
	check(ledge.rise_m > reach.jump_height, "the ledge cannot be jumped (%.2f m, jump %.2f m)" % [ledge.rise_m, reach.jump_height])
	check(box.rise_m > reach.jump_height, "nor the box (%.2f m)" % box.rise_m)
	var gone: Array[String] = ProgressGraphScript.unreachable(layout, placed, reach, {c1: ProgressGraphScript.GONE})
	check(gone.has("tut_ledge1"), "without a wheel the ledge is out of reach: " + str(gone))
	check(not ProgressGraphScript.unreachable(layout, placed, reach, {c1: ProgressGraphScript.UPRIGHT}).has("tut_ledge1"),
		"way 1: bounce on the upright wheel")
	check(not ProgressGraphScript.unreachable(layout, placed, reach, {c1: ProgressGraphScript.FLAT_USEFUL}).has("tut_ledge1"),
		"way 2: the wheel knocked flat against the box, then the box, then the ledge")
	# Way 2 does not use the bounce, and way 1 does not use the box: take the box away and way 1 stays.
	var no_box: MapLayoutScript = _with(func(l: MapLayoutScript) -> void:
		var section: MapSectionScript = l.section("tutorial")
		var kept: Array[PlatformDefScript] = []
		for def: PlatformDefScript in section.platforms:
			if def.id != "tut_box":
				kept.append(def)
		section.platforms = kept)
	var no_box_c1: SpawnEntryScript = _entry(no_box, "c1")
	check(not ProgressGraphScript.unreachable(no_box, _placed(no_box), reach, {no_box_c1: ProgressGraphScript.UPRIGHT}).has("tut_ledge1"),
		"the bounce route does not need the box")
	check(ProgressGraphScript.unreachable(no_box, _placed(no_box), reach, {no_box_c1: ProgressGraphScript.FLAT_USEFUL}).has("tut_ledge1"),
		"and a flat wheel alone is not enough without it: that was the soft-lock")


func test_a_wheel_knocked_toward_the_box_lies_where_it_is_a_step() -> void:
	var layout: MapLayoutScript = _layout()
	var placed: Array[LayoutGeometryScript.Placed] = _placed(layout)
	var reach: JumpReachScript = _reach()
	var c1: SpawnEntryScript = _entry(layout, "c1")
	var box: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "tut_box")
	var x_right: float = ProgressGraphScript.flat_end_x(placed, reach, _wheel_def(), c1, 1.0)
	check(absf(x_right - (box.left - reach.wheel_diameter * 0.5)) < 0.001, "it stops against the box")
	check(ProgressGraphScript.flat_is_useful_at(placed, c1, x_right), "that is inside the useful stretch")
	var x_left: float = ProgressGraphScript.flat_end_x(placed, reach, _wheel_def(), c1, -1.0)
	check(not ProgressGraphScript.flat_is_useful_at(placed, c1, x_left), "at the far end it is no step")
	check_eq(ProgressGraphScript.state_after(placed, reach, _wheel_def(), c1, ProgressGraphScript.FLAT_RIGHT), ProgressGraphScript.FLAT_USEFUL, "toward the box: a step")
	check_eq(ProgressGraphScript.state_after(placed, reach, _wheel_def(), c1, ProgressGraphScript.FLAT_LEFT), ProgressGraphScript.GONE, "toward the far end: none")
	check_eq(ProgressGraphScript.state_after_respawn(c1, ProgressGraphScript.FLAT_USEFUL), ProgressGraphScript.UPRIGHT, "a flat first wheel springs back upright")
	var c2: SpawnEntryScript = _entry(layout, "c2")
	check_eq(ProgressGraphScript.state_after_respawn(c2, ProgressGraphScript.FLAT_USEFUL), ProgressGraphScript.FLAT_USEFUL, "a flat second wheel by the ledge stays")
	check_eq(ProgressGraphScript.state_after_respawn(c2, ProgressGraphScript.GONE), ProgressGraphScript.UPRIGHT, "a lost one is back")


# --- The respawn rule --------------------------------------------------------------------------------

func test_a_required_wheel_is_out_of_reach_when_it_is_dead_spent_or_fallen() -> void:
	var flow: MapFlowScript = _flow()
	var c1: SpawnEntryScript = _entry(flow.layout, "c1")
	var c2: SpawnEntryScript = _entry(flow.layout, "c2")
	var t2: LayoutGeometryScript.Placed = LayoutGeometryScript.find(flow.placed, "tut_t2")
	var t3: LayoutGeometryScript.Placed = LayoutGeometryScript.find(flow.placed, "tut_t3")
	check(not flow.is_out_of_reach(_wheel_at(t2.left + 5.0, t2.top, false), c1), "rolling on its table: fine")
	check(flow.is_out_of_reach(_wheel_at(t2.left + 5.0, t2.top, false, false), c1), "dead (a slam, a hazard took it): out")
	check(flow.is_out_of_reach(_wheel_at(t2.right - 2.0, t2.top, true, false), c1), "flat, even next to the box: spent, it springs back")
	check(flow.is_out_of_reach(_wheel_at(t2.left + 1.0, t2.top, true, false), c1), "flat far from the box: out")
	check(flow.is_out_of_reach(_wheel_at(t2.left + 5.0, t2.top - c1.out_below_m - 0.5, false), c1), "fallen off the table: out")
	check(not flow.is_out_of_reach(_wheel_at(t3.right - 0.7, t3.top, true, false), c2), "the second wheel flat against its ledge is the platform: it stays")
	check(flow.is_out_of_reach(_wheel_at(t3.left + 1.0, t3.top, true, false), c2), "flat at the far end: out")
	check(flow.is_out_of_reach(_wheel_at(t3.left + 5.0, t3.top, false, false), c2), "the second wheel dead: out too")


func test_an_entry_that_is_not_required_is_not_touched_by_the_new_rules() -> void:
	var flow: MapFlowScript = _flow()
	var entry: SpawnEntryScript = SpawnEntryScript.new()
	entry.platform_id = "tut_t1"
	entry.respawn_when_out_of_reach = true
	var t1: LayoutGeometryScript.Placed = LayoutGeometryScript.find(flow.placed, "tut_t1")
	check(not flow.is_out_of_reach(_wheel_at(t1.left + 3.0, t1.top, false, false), entry), "a dead one is simply dead (the old behaviour)")
	check(not flow.is_out_of_reach(_wheel_at(t1.left + 3.0, t1.top, true, false), entry), "a flat one is fine without a useful stretch")


# --- The prologue ------------------------------------------------------------------------------------

## The prologue has one thing that is used up: the 만두 on her plate (she eats them, he stomps them). The
## exit must not need any: with none left (and none coming back) the 30th stab still opens it.
func test_the_prologue_exit_does_not_need_a_single_mandu() -> void:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	var d: DirectorScript = DirectorScript.new(_data(), gs)
	d.rng.seed = 99
	d.reaction_rng.seed = 98
	gs.prologue_intro_seen = true
	d.begin()
	d.debug_free()
	d.mandu_xs = [] as Array[float] # all eaten or stomped
	d.player_x = 1000.0 # far outside every stab column, so nothing lifts or eats him
	d.player_bottom_y = 13.0
	d.debug_set_count(_data().stab_target - 2)
	for i: int in 4800:
		d.step(1.0 / 60.0)
		if d.exit_open:
			break
	check(d.exit_open, "the exit opened with no 만두 on the plate (count %d)" % d.count)
