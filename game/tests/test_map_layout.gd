extends "res://tests/base_test.gd"
## Task 3b-i: Map 1's layout as data. The resource loads, it is the right shape, and every step of
## the main path can be done at 85% of what the 떡 can (gaps against his longest jump, ledges against
## his jump height, or the 단무지 help a step is built around). A failing step is printed.

const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const MapSectionScript := preload("res://maps/layout/map_section.gd")
const PlatformDefScript := preload("res://maps/layout/platform_def.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const ActionGlyphsScript := preload("res://systems/action_glyphs.gd")
const ControlsListingScript := preload("res://systems/controls_listing.gd")

const LAYOUT_PATH: String = "res://data/maps/ep01/map01_layout.tres"


func _layout() -> MapLayoutScript:
	return load(LAYOUT_PATH) as MapLayoutScript


func _prologue() -> PrologueDataScript:
	return load("res://data/prologue/prologue.tres") as PrologueDataScript


func _reach(tuning: MovementTuningScript = null) -> JumpReachScript:
	var t: MovementTuningScript = tuning if tuning != null else load("res://data/movement_tuning.tres") as MovementTuningScript
	return JumpReachScript.new(t, load("res://data/enemies/danmuji.tres") as EnemyDefScript, _prologue().m_per_cm())


func _anchor() -> Dictionary:
	var d: PrologueDataScript = _prologue()
	return {"left": d.next_table_min_x, "right": d.next_table_max_x, "top": d.next_table_top_y,
		"thickness": d.dims().next_table_thickness_cm * d.m_per_cm()}


func _placed(layout: MapLayoutScript = null, reach: JumpReachScript = null) -> Array[LayoutGeometryScript.Placed]:
	return LayoutGeometryScript.resolve(layout if layout != null else _layout(), reach if reach != null else _reach(), _anchor())


func test_the_layout_loads_with_its_three_sections() -> void:
	var layout: MapLayoutScript = _layout()
	check(layout != null, "the layout resource loads")
	if layout == null:
		return
	var ids: Array[String] = []
	for section: MapSectionScript in layout.sections:
		ids.append(section.id)
	check_eq(ids, ["prologue", "tutorial", "dining_room_start"] as Array[String], "sections in order")
	check(layout.section("prologue").external, "the prologue is built by the prologue code, not from here")
	check(layout.section("prologue").platforms.is_empty(), "so it lists nothing")
	check(not layout.section("tutorial").platforms.is_empty(), "the tutorial has platforms")
	check(not layout.section("dining_room_start").platforms.is_empty(), "so does the dining room start")
	check(layout.section("dining_room_start").end_wall_text != "", "the dining room start ends in a marked wall")


func test_every_step_of_the_main_path_can_be_done_at_85_percent() -> void:
	var reach: JumpReachScript = _reach()
	var problems: Array[String] = LayoutGeometryScript.validate(_placed(null, reach), reach)
	check(problems.is_empty(), "layout problems:\n        " + "\n        ".join(problems))


func test_the_validation_names_the_step_that_is_too_hard() -> void:
	var layout: MapLayoutScript = _layout().duplicate(true) as MapLayoutScript
	var gap_def: PlatformDefScript = null
	for def: PlatformDefScript in layout.section("tutorial").platforms:
		if def.id == "tut_t2":
			gap_def = def
	gap_def.gap_fraction = 0.95 # wider than 85% of his longest jump
	var reach: JumpReachScript = _reach()
	var problems: Array[String] = LayoutGeometryScript.validate(_placed(layout, reach), reach)
	check_eq(problems.size(), 1, "exactly the one step is reported")
	if not problems.is_empty():
		check("'tut_t2'" in problems[0] and "gap" in problems[0] and "section tutorial" in problems[0], "it says which step and what: " + problems[0])
	var high: MapLayoutScript = _layout().duplicate(true) as MapLayoutScript
	for def: PlatformDefScript in high.section("tutorial").platforms:
		if def.id == "tut_t1":
			def.rise_fraction = 0.9 # a plain jump onto a ledge 90% of his jump height
	problems = LayoutGeometryScript.validate(_placed(high, reach), reach)
	check(not problems.is_empty() and "'tut_t1'" in problems[0] and "ledge" in problems[0], "a too high ledge is reported too: " + str(problems))


func test_the_two_helped_steps_really_need_their_help() -> void:
	var reach: JumpReachScript = _reach()
	var placed: Array[LayoutGeometryScript.Placed] = _placed(null, reach)
	var bounce: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "tut_ledge1")
	var platform: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, "tut_ledge2")
	check(bounce.rise_m > reach.jump_height, "the bounce ledge (%.2f m) is higher than he can jump (%.2f m)" % [bounce.rise_m, reach.jump_height])
	check(bounce.rise_m <= reach.wheel_diameter + JumpReachScript.SAFETY * reach.bounce_height, "but a bounce reaches it")
	check(platform.rise_m > reach.jump_height, "the flat-wheel ledge (%.2f m) is higher than he can jump" % platform.rise_m)
	check(platform.rise_m - reach.wheel_flat_height <= JumpReachScript.SAFETY * reach.jump_height, "but a jump from the flat wheel reaches it")
	check_eq(bounce.gap_m, 0.0, "both are walls")
	check_eq(platform.gap_m, 0.0, "both are walls")


func test_gaps_and_heights_follow_the_movement_tuning() -> void:
	var tuning: MovementTuningScript = (load("res://data/movement_tuning.tres") as MovementTuningScript).duplicate() as MovementTuningScript
	var normal: Array[LayoutGeometryScript.Placed] = _placed()
	tuning.jump_velocity *= 1.2
	tuning.max_speed *= 1.1
	var changed: Array[LayoutGeometryScript.Placed] = _placed(null, _reach(tuning))
	var a: LayoutGeometryScript.Placed = LayoutGeometryScript.find(normal, "tut_t1")
	var b: LayoutGeometryScript.Placed = LayoutGeometryScript.find(changed, "tut_t1")
	check(b.gap_m > a.gap_m, "a stronger jump widens the gaps (%.2f -> %.2f m)" % [a.gap_m, b.gap_m])
	# The flat-wheel ledge is measured against his jump height, so it follows the jump.
	var ledge_a: LayoutGeometryScript.Placed = LayoutGeometryScript.find(normal, "tut_ledge2")
	var ledge_b: LayoutGeometryScript.Placed = LayoutGeometryScript.find(changed, "tut_ledge2")
	check(ledge_b.rise_m > ledge_a.rise_m, "and the ledge higher (%.2f -> %.2f m)" % [ledge_a.rise_m, ledge_b.rise_m])


func test_the_jump_numbers_match_the_tuning() -> void:
	var t: MovementTuningScript = load("res://data/movement_tuning.tres") as MovementTuningScript
	var reach: JumpReachScript = _reach()
	check(absf(reach.jump_height - t.jump_velocity * t.jump_velocity / (2.0 * t.gravity)) < 0.0001, "jump height v^2 / 2g")
	var up: float = t.jump_velocity / t.gravity
	var down: float = sqrt(2.0 * reach.jump_height / (t.gravity * t.fall_gravity_scale))
	check(absf(reach.jump_distance - t.max_speed * (up + down)) < 0.0001, "jump distance = speed x air time")
	check(reach.distance_for_rise(reach.jump_height * 0.5) < reach.jump_distance, "a jump up covers less ground")
	check_eq(reach.distance_for_rise(reach.jump_height * 1.01), 0.0, "and none above his jump height")


func test_platforms_follow_one_another_in_order_without_overlap() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	check_eq(placed.size(), 10, "ten platforms (the prologue's table, six tutorial, three dining)")
	check_eq(placed[0].def.kind, "existing", "the first is the prologue's next table")
	var d: PrologueDataScript = _prologue()
	check_eq(placed[0].left, d.next_table_min_x, "placed where the prologue's table is")
	check_eq(placed[0].top, d.next_table_top_y, "at its height")
	for i: int in range(1, placed.size()):
		check(placed[i].left >= placed[i - 1].right, "%s starts after %s" % [placed[i].def.id, placed[i - 1].def.id])
		check(placed[i].length() > 0.0, "%s has a length" % placed[i].def.id)


func test_everything_the_sections_name_exists() -> void:
	var layout: MapLayoutScript = _layout()
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var checkpoint_ids: Array[String] = []
	for section: MapSectionScript in layout.sections:
		for spawn in section.spawns:
			check(LayoutGeometryScript.find(placed, spawn.platform_id) != null, "spawn on %s: no such platform" % spawn.platform_id)
			check(spawn.scene != null, "spawn on %s has a scene" % spawn.platform_id)
			var at: Vector3 = LayoutGeometryScript.spawn_position(placed, spawn)
			var p: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, spawn.platform_id)
			check(at.x > p.left and at.x < p.right, "spawn on %s is on the platform" % spawn.platform_id)
		for checkpoint in section.checkpoints:
			check(LayoutGeometryScript.find(placed, checkpoint.platform_id) != null, "checkpoint %s: no such platform" % checkpoint.id)
			checkpoint_ids.append(checkpoint.id)
		for trigger in section.triggers:
			check(LayoutGeometryScript.find(placed, trigger.platform_id) != null, "trigger %s: no such platform" % trigger.id)
	check(checkpoint_ids.has("map01_tutorial_start"), "a checkpoint at the tutorial start")
	check(checkpoint_ids.has("map01_dining_start"), "and one at the dining room start")
	check_eq(layout.section("tutorial").skip_to_checkpoint, "map01_dining_start", "skipping goes to the dining room start")


func test_the_tutorial_start_checkpoint_is_where_the_prologue_leaves_him() -> void:
	var placed: Array[LayoutGeometryScript.Placed] = _placed()
	var checkpoint: Resource = _layout().find_checkpoint("map01_tutorial_start")
	check_eq(LayoutGeometryScript.checkpoint_position(placed, checkpoint), _prologue().next_table_spawn, "the same spot as the prologue's own respawn point")


func test_the_tutorial_beats_a_to_e_are_all_there_in_order() -> void:
	var section: MapSectionScript = _layout().section("tutorial")
	var beats: Array[String] = []
	for trigger in section.triggers:
		if not beats.has(trigger.beat):
			beats.append(trigger.beat)
	check_eq(beats, ["a", "b", "c", "d", "e"] as Array[String], "hints for beats a to e, in order")
	var groups: Array[String] = []
	for spawn in section.spawns:
		if not groups.has(spawn.group):
			groups.append(spawn.group)
	check_eq(groups, ["b", "c1", "c2", "d"] as Array[String], "enemies: a 만두, two 단무지, a 만두 cluster")
	var cluster: int = 0
	var wheels: int = 0
	var mandu_alone: int = 0
	for spawn in section.spawns:
		if spawn.group == "d":
			cluster += 1
		elif spawn.scene.resource_path.ends_with("danmuji.tscn"):
			wheels += 1
		else:
			mandu_alone += 1
	check_eq(cluster, 3, "a cluster of three 만두")
	check_eq(wheels, 2, "two 단무지 wheels")
	check_eq(mandu_alone, 1, "and one lone 만두")
	var dining_wheels: int = 0
	for spawn in _layout().section("dining_room_start").spawns:
		if spawn.scene.resource_path.ends_with("danmuji.tscn"):
			dining_wheels += 1
	check_eq(dining_wheels, 1, "the second 단무지 sits in the dining room start")


func test_the_skills_come_from_the_tutorial_beats() -> void:
	var granted: Dictionary = {}
	for trigger in _layout().section("tutorial").triggers:
		if trigger.grants_skill != "":
			granted[trigger.grants_skill] = trigger
	check(granted.has("roll") and granted.has("slam"), "roll and slam are each granted by a beat")
	check_eq((granted["roll"] as Resource).beat, "c", "roll at the start of beat c")
	check_eq((granted["slam"] as Resource).beat, "d", "slam at the start of beat d")
	for skill: String in granted:
		check_eq((granted[skill] as Resource).grant_source, "tutorial", "%s: source id" % skill)
		check((granted[skill] as Resource).toast != "", "%s has a toast" % skill)
	var skip: MapSectionScript = _layout().section("tutorial")
	check_eq(Array(skip.skip_grants), ["roll", "slam"], "skipping grants both")
	check_eq(skip.skip_source, "tutorial", "from the same source")


func test_the_korean_text_is_exact_and_names_no_keys() -> void:
	var layout: MapLayoutScript = _layout()
	check_eq(layout.prompt_accept_text, "튜토리얼 하기", "accept text")
	check_eq(layout.prompt_cancel_text, "건너뛰기", "cancel text")
	var key_words: Array[String] = ["Space", "Shift", "Enter", "Esc", "Mouse", "Ctrl", "Alt", "Tab"]
	var regex: RegEx = RegEx.new()
	regex.compile("\\{[a-z_]+\\}")
	var texts: Array[String] = []
	for trigger in layout.section("tutorial").triggers:
		texts.append(trigger.text)
		if trigger.toast != "":
			texts.append(trigger.toast)
		check(trigger.action != "" and InputMap.has_action(trigger.action), "%s: a real action name" % trigger.id)
	texts.append(layout.section("tutorial").skip_toast)
	for text: String in texts:
		check(text != "", "no empty text")
		for word: String in key_words:
			check(not (word in text), "'%s' hard-codes the key name %s" % [text, word])
		var plain: String = regex.sub(text, "", true)
		var latin: RegEx = RegEx.new()
		latin.compile("[A-Za-z]")
		check(latin.search(plain) == null, "'%s' is Korean only (apart from {action} placeholders)" % text)
		for found: RegExMatch in regex.search_all(text):
			var action: String = found.get_string().trim_prefix("{").trim_suffix("}")
			check(action == "action" or InputMap.has_action(action), "'%s': {%s} is not an action" % [text, action])


func test_button_names_come_from_the_input_map_for_the_device_in_use() -> void:
	var rows: Array[Dictionary] = ControlsListingScript.rows()
	for row: Dictionary in rows:
		var action: String = row["action"]
		if action in ["jump", "roll", "look_down", "move_left", "move_right", "ui_accept", "ui_cancel"]:
			var keyboard: String = ActionGlyphsScript.glyph(action, false)
			var pad: String = ActionGlyphsScript.glyph(action, true)
			check(keyboard in String(row["keyboard"]), "%s: keyboard glyph '%s' is in the row '%s'" % [action, keyboard, row["keyboard"]])
			check(pad in String(row["controller"]), "%s: controller glyph '%s' is in the row '%s'" % [action, pad, row["controller"]])
			check(keyboard != pad, "%s shows different names on the two devices" % action)
	check_eq(ActionGlyphsScript.glyph("jump", true), "✕ (A)", "jump on the controller")
	check_eq(ActionGlyphsScript.glyph("ui_cancel", true), "○ (B)", "cancel on the controller")
	check_eq(ActionGlyphsScript.fill("점프: {jump} / 구르기 {action}", "roll", true), "점프: ✕ (A) / 구르기 ○ (B)", "placeholders become glyphs")
	check_eq(ActionGlyphsScript.glyph("no_such_action", false), "no_such_action", "an unknown action shows its id")
