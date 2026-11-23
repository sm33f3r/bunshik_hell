extends "res://tests/base_test.gd"
## Task 3b-i: the rules behind the tutorial, on fresh instances (no map, no autoloads): the skills
## granted (and not before), the prompt flag, the checkpoint snapshot, and hints that fire once.

const MapFlowScript := preload("res://maps/layout/map_flow.gd")
const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const HintTrackerScript := preload("res://maps/layout/hint_tracker.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const SteamerScript := preload("res://items/steamer.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const ActionGlyphsScript := preload("res://systems/action_glyphs.gd")

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


## A flow with the real layout, placed, and an injected GameState. No player, no scene.
func _flow(gs: GameStateScript) -> MapFlowScript:
	var flow: MapFlowScript = MapFlowScript.new()
	_nodes.append(flow)
	flow.game_state = gs
	flow.layout = load(MapFlowScript.LAYOUT_PATH) as MapLayoutScript
	var data: PrologueDataScript = load("res://data/prologue/prologue.tres") as PrologueDataScript
	flow.reach = JumpReachScript.new(load("res://data/movement_tuning.tres") as MovementTuningScript,
		load("res://data/enemies/danmuji.tres") as EnemyDefScript, data.m_per_cm())
	flow.index_layout({"left": data.next_table_min_x, "right": data.next_table_max_x, "top": data.next_table_top_y,
		"thickness": data.dims().next_table_thickness_cm * data.m_per_cm()})
	return flow


# --- Skills -----------------------------------------------------------------------------------------

func test_roll_and_slam_are_locked_until_the_tutorial_grants_them() -> void:
	var gs: GameStateScript = _gs()
	var flow: MapFlowScript = _flow(gs)
	check(not gs.has_skill("roll") and not gs.has_skill("slam"), "locked at the start")
	flow.on_player_respawned() # nothing in the flow grants a skill by itself
	check(not gs.has_skill("roll") and not gs.has_skill("slam"), "still locked")
	check(gs.has_skill("jump") and gs.has_skill("landing") and gs.has_skill("stomp"), "the old skills are there")


func test_skipping_grants_roll_and_slam_from_the_tutorial_source() -> void:
	var gs: GameStateScript = _gs()
	var flow: MapFlowScript = _flow(gs)
	var unlocked: Array[String] = []
	gs.skill_unlocked.connect(func(id: String) -> void: unlocked.append(id))
	check(flow.grant_tutorial_skills(), "something new was granted")
	check(gs.has_skill("roll") and gs.has_skill("slam"), "both are his")
	check_eq(gs.skill_sources.get("roll"), "tutorial", "roll's source id")
	check_eq(gs.skill_sources.get("slam"), "tutorial", "slam's source id")
	check_eq(unlocked, ["roll", "slam"] as Array[String], "each announced once")
	check(not gs.has_skill("sauce_flick"), "the flick is not part of it")


func test_granting_twice_is_harmless() -> void:
	var gs: GameStateScript = _gs()
	var flow: MapFlowScript = _flow(gs)
	var unlocked: Array[String] = []
	gs.skill_unlocked.connect(func(id: String) -> void: unlocked.append(id))
	flow.grant_tutorial_skills()
	check(not flow.grant_tutorial_skills(), "the second time nothing is new")
	check(not flow.grant_skill("roll", "somewhere_else"), "nor from another source")
	check_eq(unlocked.size(), 2, "no second announcement")
	check_eq(gs.skill_sources.get("roll"), "tutorial", "the first source stays")
	check(gs.has_skill("roll") and gs.has_skill("slam"), "and they stay unlocked")


func test_finishing_the_tutorial_grants_what_he_is_still_missing() -> void:
	var gs: GameStateScript = _gs()
	var flow: MapFlowScript = _flow(gs)
	var done: Array[bool] = []
	flow.tutorial_finished.connect(func() -> void: done.append(true))
	flow.grant_skill("roll", "tutorial") # he got roll at beat c, slam not yet
	check(not gs.has_skill("slam"), "slam not yet")
	var dining: Resource = flow.layout.find_checkpoint("map01_dining_start")
	check(dining.finishes_tutorial, "the dining room start is the finish")
	flow.reach_checkpoint(dining)
	check(gs.has_skill("roll") and gs.has_skill("slam"), "both his on finishing")
	check(flow.tutorial_done and done.size() == 1, "the tutorial is marked finished")
	check_eq(gs.checkpoint_id, "map01_dining_start", "and the checkpoint is set")


func test_the_unlock_source_is_remembered_and_cleared_on_a_new_game() -> void:
	var gs: GameStateScript = _gs()
	gs.unlock_skill("roll", "tutorial")
	check_eq(gs.skill_sources.get("roll"), "tutorial", "recorded")
	gs.unlock_skill("sauce_flick")
	check(not gs.skill_sources.has("sauce_flick"), "no source given, none recorded")
	check_eq(gs.unlock_skill("no_such_skill", "tutorial"), false, "an unknown skill is refused")
	gs.reset()
	check(gs.skill_sources.is_empty() and not gs.has_skill("roll"), "a new game forgets both")


# --- The prompt flag --------------------------------------------------------------------------------

func test_the_prompt_flag_resets_on_a_new_game_and_is_saved() -> void:
	var gs: GameStateScript = _gs()
	check_eq(gs.tutorial_prompt_shown, false, "not shown yet")
	gs.tutorial_prompt_shown = true
	check(gs.to_dict().has("tutorial_prompt_shown"), "written to the save (a loaded game does not ask again)")
	var other: GameStateScript = _gs()
	other.from_dict(gs.to_dict())
	check_eq(other.tutorial_prompt_shown, true, "a loaded game carries it")
	gs.reset()
	check_eq(gs.tutorial_prompt_shown, false, "a new game asks again")


func test_the_prompt_comes_once_per_run() -> void:
	var gs: GameStateScript = _gs()
	var flow: MapFlowScript = _flow(gs)
	flow.on_prologue_complete()
	check_eq(flow.phase, MapFlowScript.Phase.PROMPT, "the first time: the prompt")
	check(gs.tutorial_prompt_shown, "and the flag is set")
	flow.answer_prompt(true)
	check_eq(flow.phase, MapFlowScript.Phase.IDLE, "answered")
	flow.on_prologue_complete()
	check_eq(flow.phase, MapFlowScript.Phase.IDLE, "never a second time in this run")
	gs.reset()
	flow.on_prologue_complete()
	check_eq(flow.phase, MapFlowScript.Phase.PROMPT, "a new game asks again")


func test_the_prompt_text_is_korean_with_the_button_of_the_device_in_use() -> void:
	var flow: MapFlowScript = _flow(_gs())
	flow.using_pad = true
	check_eq(flow.prompt_text(), "✕ (A) = 튜토리얼 하기\n○ (B) = 건너뛰기", "controller")
	flow.using_pad = false
	var text: String = flow.prompt_text()
	check("튜토리얼 하기" in text and "건너뛰기" in text, "keyboard: the same words")
	check("✕" not in text, "with the keyboard's names")


func test_the_prompt_answers_only_while_it_is_open() -> void:
	var gs: GameStateScript = _gs()
	var flow: MapFlowScript = _flow(gs)
	var answers: Array[bool] = []
	flow.prompt_answered.connect(func(yes: bool) -> void: answers.append(yes))
	flow.answer_prompt(true)
	check(answers.is_empty(), "nothing to answer yet")
	flow.on_prologue_complete()
	flow.answer_prompt(false)
	check_eq(answers, [false] as Array[bool], "the skip was answered")
	check_eq(flow.phase, MapFlowScript.Phase.FADE_OUT, "and the fade starts")
	flow.answer_prompt(true)
	check_eq(answers.size(), 1, "a second answer is ignored")


# --- The checkpoint snapshot ------------------------------------------------------------------------

func test_a_checkpoint_snapshot_restores_hearts_sauce_and_sodium() -> void:
	var gs: GameStateScript = _gs()
	gs.add_sauce(2) # 3 -> 5
	gs.add_sodium(2)
	gs.set_checkpoint_snapshot("here", Vector3(4.0, 5.0, 0.0))
	gs.spend_sauce(4)
	gs.add_sodium(4)
	gs.take_damage(14)
	check(gs.is_dead(), "dead")
	var at: Vector3 = gs.respawn()
	check_eq(at, Vector3(4.0, 5.0, 0.0), "back at the checkpoint")
	check_eq(gs.hearts, 14, "full hearts")
	check_eq(gs.sauce, 5, "the sauce he had when he got there")
	check_eq(gs.sodium, 2, "the 나트륨 he had when he got there")


func test_a_later_checkpoint_takes_a_new_snapshot() -> void:
	var gs: GameStateScript = _gs()
	gs.set_checkpoint_snapshot("first", Vector3.ZERO)
	gs.add_sodium(3)
	gs.add_sauce(1)
	gs.set_checkpoint_snapshot("second", Vector3(9.0, 0.0, 0.0))
	gs.spend_sodium(3)
	gs.spend_sauce(4)
	gs.respawn()
	check_eq(gs.sodium, 3, "the second checkpoint's 나트륨")
	check_eq(gs.sauce, 4, "and sauce")


func test_a_steamer_takes_its_own_snapshot_when_used() -> void:
	var gs: GameStateScript = _gs()
	gs.set_checkpoint_snapshot("map", Vector3.ZERO)
	var steamer: SteamerScript = SteamerScript.new()
	_nodes.append(steamer)
	steamer.steamer_id = "pot"
	gs.add_sodium(2)
	steamer.activate(gs)
	check_eq(gs.checkpoint_snapshot, {"sauce": 3, "sodium": 2}, "a 찜기 replaces the map checkpoint's snapshot with its own")
	gs.spend_sauce(3)
	gs.take_damage(14)
	gs.respawn()
	check_eq(gs.sauce, 3, "and respawning there restores what he had when he used it")


func test_the_snapshot_is_not_saved_to_disk() -> void:
	var gs: GameStateScript = _gs()
	gs.set_checkpoint_snapshot("x", Vector3.ONE)
	var saved: Dictionary = gs.to_dict()
	check(not saved.has("checkpoint_snapshot"), "not in the save")
	var other: GameStateScript = _gs()
	other.from_dict(saved)
	check(other.checkpoint_snapshot.is_empty(), "so a loaded game starts without one")
	check_eq(other.checkpoint_id, "x", "(the checkpoint itself is saved)")
	gs.reset()
	check(gs.checkpoint_snapshot.is_empty(), "a new game clears it")


func test_reaching_a_map_checkpoint_stores_the_snapshot_and_the_position() -> void:
	var gs: GameStateScript = _gs()
	var flow: MapFlowScript = _flow(gs)
	var reached: Array[String] = []
	flow.checkpoint_reached.connect(func(id: String) -> void: reached.append(id))
	gs.add_sodium(2)
	var start: Resource = flow.layout.find_checkpoint("map01_tutorial_start")
	flow.reach_checkpoint(start)
	check_eq(gs.checkpoint_id, "map01_tutorial_start", "id")
	check_eq(gs.checkpoint_position, LayoutGeometryScript.checkpoint_position(flow.placed, start), "position from the data")
	check_eq(gs.checkpoint_snapshot, {"sauce": 3, "sodium": 2}, "snapshot")
	check_eq(reached, ["map01_tutorial_start"] as Array[String], "announced")
	check(not flow.tutorial_done, "the tutorial's start is not its end")


func test_checkpoints_only_move_forward() -> void:
	var gs: GameStateScript = _gs()
	var flow: MapFlowScript = _flow(gs)
	check_eq(flow.checkpoint_index("map01_tutorial_start"), 0, "first")
	check_eq(flow.checkpoint_index("map01_dining_start"), 1, "second")
	check_eq(flow.checkpoint_index("map01_next_table"), -1, "the prologue's own is outside the list")


# --- Hints ------------------------------------------------------------------------------------------

func _zones(flow: MapFlowScript) -> Array:
	var zones: Array = []
	for trigger in flow.layout.section("tutorial").triggers:
		zones.append({"def": trigger, "rect": LayoutGeometryScript.trigger_rect(flow.placed, trigger)})
	return zones


func test_a_hint_fires_once_per_life() -> void:
	var flow: MapFlowScript = _flow(_gs())
	var tracker: HintTrackerScript = HintTrackerScript.new()
	var zones: Array = _zones(flow)
	var table: LayoutGeometryScript.Placed = LayoutGeometryScript.find(flow.placed, "tut_t1")
	var inside: Vector2 = Vector2(table.left + 1.0, table.top + 0.1)
	var first: Array[Resource] = tracker.check(zones, inside)
	check_eq(first.size(), 1, "one hint fires")
	check_eq(first[0].id, "hint_b_stomp", "the one for this table")
	check_eq(tracker.check(zones, inside).size(), 0, "not twice while standing there")
	check_eq(tracker.check(zones, Vector2(table.left + 20.0, table.top + 0.1)).size(), 0, "nor elsewhere")
	check_eq(tracker.check(zones, inside).size(), 0, "nor when he comes back")
	tracker.reset() # he died
	check_eq(tracker.check(zones, inside).size(), 1, "a new life: it may show again")


func test_each_beat_has_its_own_zone_and_they_do_not_overlap() -> void:
	var flow: MapFlowScript = _flow(_gs())
	var zones: Array = _zones(flow)
	for i: int in zones.size():
		for j: int in range(i + 1, zones.size()):
			var a: Rect2 = zones[i]["rect"]
			var b: Rect2 = zones[j]["rect"]
			check(not a.intersects(b), "%s and %s overlap" % [zones[i]["def"].id, zones[j]["def"].id])
		check((zones[i]["rect"] as Rect2).size.x > 0.0, "%s has a size" % zones[i]["def"].id)


func test_hint_text_uses_the_glyphs_of_the_device_in_use() -> void:
	var flow: MapFlowScript = _flow(_gs())
	var trigger: Resource = null
	for t in flow.layout.section("tutorial").triggers:
		if t.id == "hint_c_roll":
			trigger = t
	var pad_text: String = ActionGlyphsScript.fill(trigger.text, trigger.action, true)
	var key_text: String = ActionGlyphsScript.fill(trigger.text, trigger.action, false)
	check("○ (B)" in pad_text, "controller: " + pad_text)
	check("○" not in key_text and "{" not in key_text, "keyboard: " + key_text)
	check(pad_text != key_text, "they differ")


func test_the_skill_beats_grant_through_their_trigger() -> void:
	var gs: GameStateScript = _gs()
	var flow: MapFlowScript = _flow(gs)
	var by_id: Dictionary = {}
	for t in flow.layout.section("tutorial").triggers:
		by_id[t.id] = t
	flow.fire_trigger(by_id["hint_b_stomp"])
	check(not gs.has_skill("roll"), "the stomp beat grants nothing")
	flow.fire_trigger(by_id["hint_c_bounce"])
	check(gs.has_skill("roll") and not gs.has_skill("slam"), "beat c: roll, not slam yet")
	flow.fire_trigger(by_id["hint_c_roll"])
	check(not gs.has_skill("slam"), "the roll hint grants nothing more")
	flow.fire_trigger(by_id["hint_d_slam"])
	check(gs.has_skill("slam"), "beat d: slam")
	check_eq(gs.skill_sources.get("slam"), "tutorial", "from the tutorial")
