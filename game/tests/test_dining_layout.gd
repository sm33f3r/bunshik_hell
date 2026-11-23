extends "res://tests/base_test.gd"
## Task 3b-ii: the dining room as data. The long run of tables, the napkin boxes and windowsills, the
## floor lane with the chairs that lead back up, and what stands where. Everything is checked against
## what the 떡 can do (JumpReach), not against typed-in numbers.

const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const MapSectionScript := preload("res://maps/layout/map_section.gd")
const PlatformDefScript := preload("res://maps/layout/platform_def.gd")
const SpawnEntryScript := preload("res://maps/layout/spawn_entry.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const MapFlowScript := preload("res://maps/layout/map_flow.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const GameStateScript := preload("res://systems/game_state.gd")

const LAYOUT_PATH: String = "res://data/maps/ep01/map01_layout.tres"

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


func _reach() -> JumpReachScript:
	return JumpReachScript.new(load("res://data/movement_tuning.tres") as MovementTuningScript,
		load("res://data/enemies/danmuji.tres") as EnemyDefScript, _data().m_per_cm())


func _anchor() -> Dictionary:
	var d: PrologueDataScript = _data()
	return {"left": d.next_table_min_x, "right": d.next_table_max_x, "top": d.next_table_top_y,
		"thickness": d.dims().next_table_thickness_cm * d.m_per_cm()}


func _placed(layout: MapLayoutScript = null) -> Array[LayoutGeometryScript.Placed]:
	return LayoutGeometryScript.resolve(layout if layout != null else _layout(), _reach(), _anchor())


func _with(edit: Callable) -> MapLayoutScript:
	var copy: MapLayoutScript = _layout().duplicate(true) as MapLayoutScript
	edit.call(copy)
	return copy


func _problems(layout: MapLayoutScript) -> Array[String]:
	return LayoutGeometryScript.validate(_placed(layout), _reach(), layout)


func _mentions(problems: Array[String], needle: String) -> bool:
	for line: String in problems:
		if needle in line:
			return true
	return false


func _def_in(layout: MapLayoutScript, section_id: String, platform_id: String) -> PlatformDefScript:
	for def: PlatformDefScript in layout.section(section_id).platforms:
		if def.id == platform_id:
			return def
	return null


func _dining() -> MapSectionScript:
	return _layout().section("dining_room")


# --- The layout as a whole ------------------------------------------------------------------------

func test_the_dining_room_validates_in_full() -> void:
	var problems: Array[String] = _problems(_layout())
	check(problems.is_empty(), "layout problems:\n        " + "\n        ".join(problems))


func test_the_dining_room_goes_on_from_the_dining_room_start() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var first: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "r_t1")
	var last_start: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "dining_3")
	check_eq(first.prev, last_start, "the first dining-room table is placed against the last one of the start")
	check(first.left > last_start.right, "after it")
	check_eq(first.section_id, "dining_room", "in its own section")
	check_eq(_layout().section("dining_room_start").end_wall_text, "", "the start no longer ends in a wall")
	check(_dining().end_wall_text != "", "the dining room does, with a marked wall")


func test_the_tables_vary_in_gap_height_and_width() -> void:
	var lengths: Dictionary = {}
	var gaps: Dictionary = {}
	var rises: Dictionary = {}
	var tables: int = 0
	for p: LayoutGeometryScript.Placed in _placed():
		if p.section_id == "dining_room" and p.def.kind == "table":
			tables += 1
			lengths[snappedf(p.length(), 0.1)] = true
			gaps[snappedf(p.gap_m, 0.1)] = true
			rises[snappedf(p.rise_m, 0.1)] = true
	check(tables >= 12, "a long run of tables (%d)" % tables)
	check(lengths.size() >= 6, "varied widths (%d kinds)" % lengths.size())
	check(gaps.size() >= 6, "varied gaps (%d kinds)" % gaps.size())
	check(rises.size() >= 5, "varied heights (%d kinds)" % rises.size())


func test_gaps_and_heights_come_from_fractions_not_metres() -> void:
	for def: PlatformDefScript in _dining().platforms:
		if def.kind == "table":
			check(def.gap_fraction <= JumpReachScript.SAFETY, "%s: gap fraction %.2f" % [def.id, def.gap_fraction])
			check(def.rise_basis == "jump" and def.rise_fraction <= JumpReachScript.SAFETY, "%s: rise fraction %.2f" % [def.id, def.rise_fraction])


# --- Windowsills ----------------------------------------------------------------------------------

func test_every_sill_is_reached_by_hopping_from_a_napkin_box() -> void:
	var reach: JumpReachScript = _reach()
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var sills: int = 0
	for p: LayoutGeometryScript.Placed in placed:
		if p.def.kind != "sill":
			continue
		sills += 1
		var box: LayoutGeometryScript.Placed = p.prev
		check_eq(box.def.kind, "prop", "%s: its host is a napkin box" % p.def.id)
		check(LayoutGeometryScript.can_hop(box, p, reach), "%s: the hop from %s is valid (gap %.2f m, rise %.2f m)" % [p.def.id, box.def.id, p.gap_m, p.rise_m])
		var table: LayoutGeometryScript.Placed = box.prev
		check_eq(table.def.kind, "table", "%s: the box stands on a table" % box.def.id)
		check(box.rise_m <= reach.max_rise("jump"), "%s: the box can be climbed (%.2f m)" % [box.def.id, box.rise_m])
		check(box.left >= table.left and box.right <= table.right + 0.001, "%s: the box is on the table" % box.def.id)
		check(p.top - table.top > reach.jump_height, "%s: %.2f m above the table, more than a jump (%.2f m): only the box gets him there" % [p.def.id, p.top - table.top, reach.jump_height])
	check(sills >= 3, "a few sills (%d)" % sills)


func test_exactly_one_sill_is_required_and_it_is_near_the_end() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var required: Array[LayoutGeometryScript.Placed] = []
	for p: LayoutGeometryScript.Placed in placed:
		if p.def.kind == "sill" and p.def.main_path:
			required.append(p)
	check_eq(required.size(), 1, "one required sill hop")
	var sill: LayoutGeometryScript.Placed = required[0]
	var tables: Array[LayoutGeometryScript.Placed] = []
	for p: LayoutGeometryScript.Placed in placed:
		if p.section_id == "dining_room" and p.def.kind == "table":
			tables.append(p)
	var before: LayoutGeometryScript.Placed = sill.prev.prev
	var after: LayoutGeometryScript.Placed = null
	for p: LayoutGeometryScript.Placed in placed:
		if p.prev == sill and p.def.main_path:
			after = p
	check(after != null, "the way goes on from the sill")
	check(after.left - before.right > _reach().jump_distance, "the tables either side are too far apart to jump: %.2f m (longest jump %.2f m)" % [after.left - before.right, _reach().jump_distance])
	check(tables.find(before) >= tables.size() - 5, "near the end of the section (table %d of %d)" % [tables.find(before) + 1, tables.size()])
	for p: LayoutGeometryScript.Placed in placed:
		if p.def.kind == "sill" and p != sill:
			check(not p.def.main_path, "%s is an extra: not on the way" % p.def.id)


func test_a_sill_hop_that_is_too_far_is_reported() -> void:
	var far: MapLayoutScript = _with(func(layout: MapLayoutScript) -> void:
		_def_in(layout, "dining_room", "sill_a").gap_fraction = 1.3)
	check(_mentions(_problems(far), "'sill_a'"), "reported with the sill's name")
	check(_mentions(_problems(far), "too far"), "and what is wrong")


func test_a_sill_that_needs_no_box_is_reported() -> void:
	var low: MapLayoutScript = _with(func(layout: MapLayoutScript) -> void:
		_def_in(layout, "dining_room", "sill_b").rise_fraction = -0.3)
	var problems: Array[String] = _problems(low)
	check(_mentions(problems, "'sill_b'") and _mentions(problems, "without the box"), "a sill he can jump onto from the table: " + str(problems))


func test_a_required_sill_that_can_be_skipped_is_reported() -> void:
	var close: MapLayoutScript = _with(func(layout: MapLayoutScript) -> void:
		_def_in(layout, "dining_room", "r_t12").gap_fraction = 0.0
		_def_in(layout, "dining_room", "sill_req").length_cm = 4.0)
	check(_mentions(_problems(close), "not a required hop"), "the tables next to a short sill are close enough to jump: " + str(_problems(close)))


# --- The floor lane and the way back up -----------------------------------------------------------

func test_the_floor_lane_runs_under_the_whole_dining_room() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "dining_floor")
	check(lane != null and lane.def.kind == "floor", "a floor lane")
	for p: LayoutGeometryScript.Placed in placed:
		if p.def.kind == "table" and p.section_id in ["dining_room_start", "dining_room"]:
			check(p.left >= lane.left - 0.001 and p.right <= lane.right + 0.001, "%s is over the lane" % p.def.id)
	var anchor_top: float = _anchor()["top"]
	check(absf(lane.top) < 0.05, "the floor is the floor: y = %.2f (the prologue's counter is %.2f m up, %.0f cm)" % [lane.top, anchor_top, _data().dims().counter_top_height_cm])
	check(lane.top < LayoutGeometryScript.lowest_top(placed) - 8.0, "far below the tables")


func test_every_chair_step_is_a_real_hop_with_room_to_stand() -> void:
	var reach: JumpReachScript = _reach()
	var steps: int = 0
	for p: LayoutGeometryScript.Placed in _placed():
		if p.def.kind != "block":
			continue
		steps += 1
		check(LayoutGeometryScript.can_hop(p, p.prev, reach) or LayoutGeometryScript.can_hop(p.prev, p, reach),
			"%s: a hop from %s (%.2f m)" % [p.def.id, p.prev.def.id, p.rise_m])
		check(absf(p.rise_m) <= reach.max_rise("jump"), "%s: a step of %.2f m is within %.2f m" % [p.def.id, absf(p.rise_m), reach.max_rise("jump")])
	check(steps >= 30, "a staircase of chair steps at every way back up (%d)" % steps)


func test_every_point_of_the_floor_has_a_way_back_up_to_a_table() -> void:
	var layout: MapLayoutScript = _layout()
	var problems: Array[String] = _problems(layout)
	check(not _mentions(problems, "floor lane"), "the climb-back graph reaches a table from every floor point: " + str(problems))
	# The same check, written out: the nearest bottom step is never further than the layout allows.
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "dining_floor")
	var bottoms: Array[LayoutGeometryScript.Placed] = []
	for p: LayoutGeometryScript.Placed in placed:
		if p.def.kind == "block" and p.top - lane.top < _reach().max_rise("jump"):
			bottoms.append(p)
	check(bottoms.size() >= 3, "a few ways up (%d)" % bottoms.size())
	var x: float = lane.left
	while x <= lane.right:
		var nearest: float = INF
		for b: LayoutGeometryScript.Placed in bottoms:
			nearest = minf(nearest, 0.0 if x >= b.left and x <= b.right else minf(absf(x - b.left), absf(x - b.right)))
		check(nearest <= layout.climb_spacing_max_m, "x=%.0f: the nearest way up is %.0f m away" % [x, nearest])
		x += 5.0


func test_a_floor_lane_without_a_way_up_is_reported() -> void:
	var none: MapLayoutScript = _with(func(layout: MapLayoutScript) -> void:
		var kept: Array[PlatformDefScript] = []
		for def: PlatformDefScript in layout.section("dining_room").platforms:
			if def.kind != "stairs":
				kept.append(def)
		layout.section("dining_room").platforms = kept)
	check(_mentions(_problems(none), "no way back up"), "reported: " + str(_problems(none)))


func test_a_floor_point_too_far_from_a_way_up_is_reported() -> void:
	var tight: MapLayoutScript = _with(func(layout: MapLayoutScript) -> void:
		layout.climb_spacing_max_m = 12.0)
	check(_mentions(_problems(tight), "nearest way back up"), "a stricter spacing finds a point too far from any way up")


func test_a_chair_step_with_no_headroom_is_reported() -> void:
	var low: MapLayoutScript = _with(func(layout: MapLayoutScript) -> void:
		_def_in(layout, "dining_room", "chair_r_t5").bottom_rise_cm = 60.0)
	var problems: Array[String] = _problems(low)
	check(not problems.is_empty(), "a staircase with steps he cannot hop is reported (the way up is gone from the climb-back graph): " + str(problems))


func test_a_fall_is_caught_on_the_floor_in_the_dining_room_and_by_the_checkpoint_rule_elsewhere() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var depth: float = _layout().fall_depth_m
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "dining_floor")
	var in_dining: float = LayoutGeometryScript.catch_y_at(placed, LayoutGeometryScript.find(placed, "r_t5").center_x(), depth)
	check_eq(in_dining, lane.top - depth, "in the dining room he lands on the floor first; the catch is below it")
	var in_tutorial: float = LayoutGeometryScript.catch_y_at(placed, LayoutGeometryScript.find(placed, "tut_t1").center_x(), depth)
	check_eq(in_tutorial, LayoutGeometryScript.lowest_top(placed) - depth, "in the tutorial the old rule: put back at the checkpoint")
	check(in_tutorial > in_dining + 5.0, "far above the floor catch")
	check(LayoutGeometryScript.lowest_top(placed) > 5.0, "the chair steps and the floor do not lower the tutorial's limit")


# --- What stands where ----------------------------------------------------------------------------

func test_every_spawn_entry_is_complete() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var allowed: Array[String] = ["mandu", "danmuji", "gimbap_train", "chopsticks", "giant_foot", "gum_patch", "falling_zone", "natrium_pickup", "sauce_drip"]
	var entries: int = 0
	for entry: SpawnEntryScript in _dining().spawns:
		entries += 1
		var where: String = "%s @ %.1f" % [entry.platform_id, entry.along_m]
		var p: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, entry.platform_id)
		check(p != null, "%s: its platform exists" % where)
		if p == null:
			continue
		check(entry.scene != null, "%s: a scene" % where)
		var name: String = entry.scene.resource_path.get_file().get_basename()
		check(allowed.has(name), "%s: '%s' is a known scene" % [where, name])
		var x: float = LayoutGeometryScript.spawn_position(placed, entry).x
		check(x > p.left + 0.3 and x < p.right - 0.3, "%s: on the platform (x %.1f, %.1f..%.1f)" % [where, x, p.left, p.right])
		check(entry.group != "", "%s: a group" % where)
		check(p.def.kind in ["table", "floor", "sill"], "%s: stands on a table, a sill or the floor, not on a prop" % where)
		if name in ["chopsticks", "giant_foot", "gum_patch"]:
			check(entry.size_cm > 0.0, "%s: a zone with a width" % where)
			check(x - entry.size_cm * _reach().m_per_cm * 0.5 > p.left - 0.001 and x + entry.size_cm * _reach().m_per_cm * 0.5 < p.right + 0.001, "%s: the zone fits on the platform" % where)
		if name == "mandu":
			check(entry.size_cm > 0.0, "%s: a 만두 has its size" % where)
		check(entry.start_dir == 1.0 or entry.start_dir == -1.0, "%s: a direction" % where)
	check(entries >= 35, "the dining room is populated (%d entries)" % entries)


func test_the_dining_room_has_every_kind_on_tables_and_the_floor() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var counts: Dictionary = {}
	var pairs: int = 0
	var per_platform: Dictionary = {}
	for entry: SpawnEntryScript in _dining().spawns:
		var kind: String = entry.scene.resource_path.get_file().get_basename()
		var lane: String = "floor" if LayoutGeometryScript.find(placed, entry.platform_id).def.kind == "floor" else "table"
		counts["%s/%s" % [kind, lane]] = int(counts.get("%s/%s" % [kind, lane], 0)) + 1
		if kind == "mandu":
			per_platform[entry.platform_id] = int(per_platform.get(entry.platform_id, 0)) + 1
	for id: String in per_platform:
		if int(per_platform[id]) >= 2:
			pairs += 1
	check(int(counts.get("mandu/table", 0)) + int(counts.get("mandu/floor", 0)) >= 8, "several 만두")
	check(pairs >= 2, "some in pairs (%d)" % pairs)
	for key: String in ["danmuji/table", "danmuji/floor", "gimbap_train/table", "chopsticks/table", "chopsticks/floor", "gum_patch/floor", "giant_foot/floor"]:
		check(int(counts.get(key, 0)) >= 1, "at least one %s" % key)
	check(int(counts.get("gimbap_train/table", 0)) >= 3, "김밥 trains on the tables")
	check(not counts.has("gum_patch/table") and not counts.has("giant_foot/table"), "gum and feet are floor hazards")


func test_the_difficulty_starts_gentle_and_rises() -> void:
	var weight: Dictionary = {"mandu": 1.0, "danmuji": 2.0, "gimbap_train": 3.0, "chopsticks": 2.0, "giant_foot": 3.0, "gum_patch": 2.0}
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var thirds: Array[float] = [0.0, 0.0, 0.0]
	var lane_thirds: Array[float] = [0.0, 0.0, 0.0]
	var lane: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "dining_floor")
	var first: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "r_t1")
	var last: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "r_t15")
	for entry: SpawnEntryScript in _dining().spawns:
		var name: String = entry.scene.resource_path.get_file().get_basename()
		if not weight.has(name):
			continue
		var x: float = LayoutGeometryScript.spawn_position(placed, entry).x
		if LayoutGeometryScript.find(placed, entry.platform_id).def.kind == "floor":
			lane_thirds[clampi(int(3.0 * (x - lane.left) / lane.length()), 0, 2)] += float(weight[name])
		else:
			thirds[clampi(int(3.0 * (x - first.left) / (last.right - first.left)), 0, 2)] += float(weight[name])
	check(thirds[0] < thirds[2], "tables: the first third (%.0f) is gentler than the last (%.0f)" % [thirds[0], thirds[2]])
	check(thirds[0] <= thirds[1] and thirds[1] <= thirds[2] + 3.0, "and it does not dip in the middle (%s)" % str(thirds))
	check(lane_thirds[0] < lane_thirds[2], "floor: the first third (%.0f) is gentler than the last (%.0f)" % [lane_thirds[0], lane_thirds[2]])
	var lane_first: float = LayoutGeometryScript.find(placed, "r_t1").left
	for entry: SpawnEntryScript in _dining().spawns:
		if entry.platform_id == "r_t1" or entry.platform_id == "r_t2":
			check(entry.scene.resource_path.ends_with("mandu.tscn"), "%s at the start is only a 만두" % entry.platform_id)
	check(lane_first > 0.0, "(sanity)")


func test_there_is_a_mid_section_jjigi_on_a_table() -> void:
	var layout: MapLayoutScript = _layout()
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var mid: Resource = layout.find_jjigi("map01_dining_mid")
	check(mid != null, "the 찜기 exists")
	check(layout.find_checkpoint("map01_dining_mid") == null, "and it replaced the data checkpoint")
	check_eq(layout.section_of_respawn("map01_dining_mid").id, "dining_room", "in the dining room section")
	check(mid.def != null and mid.def.heals_once and mid.def.saves and not mid.def.debug_unlimited, "once-only, saving, never debug_unlimited")
	var table: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, mid.platform_id)
	check_eq(table.def.kind, "table", "on a table")
	var first: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "r_t1")
	var last: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "r_t15")
	var fraction: float = (table.left - first.left) / (last.right - first.left)
	check(fraction > 0.3 and fraction < 0.7, "about half way (%.0f%%)" % (fraction * 100.0))
	check_eq(layout.section("dining_room").jjigi.size(), 1, "one 찜기 in the dining room")
	check(layout.find_checkpoint("map01_dining_start") != null, "the start's checkpoint is still there")


func test_a_chair_arrives_at_a_free_table_edge() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var stations: int = 0
	for def: PlatformDefScript in _dining().platforms:
		if def.kind != "stairs":
			continue
		stations += 1
		var host: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, def.host)
		for p: LayoutGeometryScript.Placed in placed:
			if p.def.kind == "prop" and p.prev == host:
				var near_edge: bool = p.right > host.right - 1.0 if def.side == "right" else p.left < host.left + 1.0
				check(not near_edge, "%s: the napkin box %s stands where the chair meets the table" % [def.id, p.def.id])
	check(stations >= 3, "chairs (%d)" % stations)


func test_no_gum_lies_under_a_chair_so_it_can_be_jumped_over() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var gum_count: int = 0
	for entry: SpawnEntryScript in _dining().spawns:
		if not entry.scene.resource_path.ends_with("gum_patch.tscn"):
			continue
		gum_count += 1
		var x: float = LayoutGeometryScript.spawn_position(placed, entry).x
		var half: float = entry.size_cm * _reach().m_per_cm * 0.5
		for p: LayoutGeometryScript.Placed in placed:
			if p.def.kind == "block":
				check(p.right < x - half - 4.0 or p.left > x + half + 4.0, "gum at %.1f m is within a jump of the chair step %s" % [x, p.def.id])
	check(gum_count >= 2, "gum patches (%d)" % gum_count)


func test_the_pickups_sit_on_optional_sills() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var found: int = 0
	for entry: SpawnEntryScript in _dining().spawns:
		var name: String = entry.scene.resource_path.get_file().get_basename()
		if name in ["natrium_pickup", "sauce_drip"]:
			found += 1
			var p: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, entry.platform_id)
			check_eq(p.def.kind, "sill", "%s on a sill" % name)
			check(not p.def.main_path, "an optional sill: no required progress up there")
	check(found >= 2, "pickups up on the sills (%d)" % found)


# --- Wheel 2 (part 0 of the task) -----------------------------------------------------------------

func _flow() -> MapFlowScript:
	var flow: MapFlowScript = MapFlowScript.new()
	_nodes.append(flow)
	flow.game_state = GameStateScript.new()
	_nodes.append(flow.game_state)
	flow.layout = _layout()
	flow.reach = _reach()
	flow.index_layout(_anchor())
	return flow


func _wheel_entry() -> SpawnEntryScript:
	for entry: SpawnEntryScript in _layout().section("tutorial").spawns:
		if entry.group == "c2":
			return entry
	return null


func test_wheel_2s_spawn_entry_says_when_it_comes_back() -> void:
	var entry: SpawnEntryScript = _wheel_entry()
	check(entry.respawn_when_out_of_reach, "it respawns when it is out of reach")
	check_eq(entry.respawn_delay_s, 4.0, "after 4 s (data)")
	check(entry.useful_from_m < 0.0 and entry.useful_to_m < 0.0 and entry.useful_from_m < entry.useful_to_m, "the useful stretch is at the platform's right end, by the ledge")
	check(entry.out_below_m > 0.0, "and a fall counts too")
	var others: int = 0
	for e: SpawnEntryScript in _layout().section("tutorial").spawns:
		if e != entry and e.respawn_when_out_of_reach:
			others += 1
	check_eq(others, 0, "no other tutorial entry asks for it")


func _wheel_at(x: float, y: float, flat: bool) -> Node3D:
	var wheel: Node3D = (load("res://enemies/danmuji.tscn") as PackedScene).instantiate() as Node3D
	_nodes.append(wheel)
	wheel.position = Vector3(x, y, 0.0)
	wheel.set("flat", flat)
	return wheel


func test_a_wheel_knocked_the_wrong_way_is_out_of_reach() -> void:
	var flow: MapFlowScript = _flow()
	var entry: SpawnEntryScript = _wheel_entry()
	var t3: LayoutGeometryScript.Placed = LayoutGeometryScript.find(flow.placed, "tut_t3")
	var top: float = t3.top
	check(not flow.is_out_of_reach(_wheel_at(t3.left + 5.0, top, false), entry), "rolling on its spot: fine")
	check(not flow.is_out_of_reach(_wheel_at(t3.right - 0.7, top, true), entry), "flat against the ledge: it is the platform he needs")
	check(flow.is_out_of_reach(_wheel_at(t3.left + 1.0, top, true), entry), "flat at the far end: out of reach")
	check(flow.is_out_of_reach(_wheel_at(t3.left + 5.0, top, true), entry), "flat in the middle: out of reach")
	check(flow.is_out_of_reach(_wheel_at(t3.left + 5.0, top - entry.out_below_m - 0.5, false), entry), "off its table: out of reach")
	check(flow.is_out_of_reach(_wheel_at(t3.right + 5.0, top - 0.2, true), entry), "past the end: out of reach")


func test_respawn_is_generic_any_entry_can_ask_for_it() -> void:
	var flow: MapFlowScript = _flow()
	var entry: SpawnEntryScript = SpawnEntryScript.new()
	entry.platform_id = "tut_t1"
	entry.respawn_when_out_of_reach = true
	entry.out_below_m = 2.0
	var t1: LayoutGeometryScript.Placed = LayoutGeometryScript.find(flow.placed, "tut_t1")
	var mandu: Node3D = (load("res://enemies/mandu.tscn") as PackedScene).instantiate() as Node3D
	_nodes.append(mandu)
	mandu.position = Vector3(t1.left + 3.0, t1.top, 0.0)
	check(not flow.is_out_of_reach(mandu, entry), "on its table")
	mandu.position = Vector3(t1.left + 3.0, t1.top - 3.0, 0.0)
	check(flow.is_out_of_reach(mandu, entry), "fallen off (a 만두)")
	entry.useful_from_m = 0.0
	entry.useful_to_m = 0.0
	mandu.position = Vector3(t1.left + 3.0, t1.top, 0.0)
	check(not flow.is_out_of_reach(mandu, entry), "no useful stretch: anywhere on the table is fine")
