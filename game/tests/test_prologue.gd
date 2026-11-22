extends "res://tests/base_test.gd"
## Task 3a: the Map 1 prologue's rules, on a fresh director with a fresh GameState (no autoloads,
## no scene). Time is stepped by hand: 60 ticks = 1 s.

const GameStateScript := preload("res://systems/game_state.gd")
const DirectorScript := preload("res://prologue/prologue_director.gd")
const DataScript := preload("res://prologue/prologue_data.gd")

const DT: float = 1.0 / 60.0
const MIN_TELEGRAPH: float = 0.4


func _data() -> DataScript:
	return load("res://data/prologue/prologue.tres") as DataScript


func _make(seed_value: int = 1, gs: GameStateScript = null) -> DirectorScript:
	var state: GameStateScript = gs if gs != null else GameStateScript.new()
	var d: DirectorScript = DirectorScript.new(_data(), state)
	d.rng.seed = seed_value
	return d


## A director past the cutscene and the opening wiggle, ready to stab. The 떡 stands at x = 5.
func _in_stab_phase(seed_value: int = 1) -> DirectorScript:
	var d: DirectorScript = _make(seed_value)
	d.gs.prologue_intro_seen = true
	d.begin()
	d.player_x = 5.0
	d.player_bottom_y = 1.0
	d.debug_free()
	# Stop the moment the stabbing is allowed to start, before any pattern is rolled.
	for i: int in 600:
		if d.state == DirectorScript.State.STAB:
			break
		d.step(DT)
	return d


func _done(d: DirectorScript) -> void:
	var gs: GameStateScript = d.gs
	d.apply_damage = Callable()
	gs.free()


func run(d: DirectorScript, seconds: float) -> void:
	for i: int in int(ceil(seconds / DT)):
		d.step(DT)


## Forces a pattern and runs until it has finished. Returns the stabs that landed.
func play(d: DirectorScript, pattern_id: String, max_seconds: float = 60.0) -> Array[DirectorScript.Stab]:
	var landed: Array[DirectorScript.Stab] = []
	var on_landed: Callable = func(s: DirectorScript.Stab) -> void: landed.append(s)
	d.stab_landed.connect(on_landed)
	d.force_next_pattern(d.find_pattern(pattern_id))
	var started: bool = false
	var ticks: int = int(max_seconds / DT)
	for i: int in ticks:
		d.step(DT)
		if d.pattern_running():
			started = true
		elif started or d.state != DirectorScript.State.STAB:
			break
	d.stab_landed.disconnect(on_landed)
	return landed


func _free_him(d: DirectorScript) -> void:
	for i: int in d.wiggle_required:
		d.wiggle_press(1 if i % 2 == 0 else -1)


# --- Data ---------------------------------------------------------------------------------------

func test_the_data_holds_the_starting_values() -> void:
	var data: DataScript = _data()
	check(data != null, "prologue.tres loads")
	check_eq(data.required_alternations, 10, "wiggle alternations")
	check_eq(data.window_s, 3.0, "wiggle window (= the rise time)")
	check_eq(data.stab_target, 30, "30 stabs")
	check_eq(data.small_damage, 1, "a small stab is one half-heart")
	check_eq(data.big_damage, 2, "a big stab is two half-hearts")
	var firsts: Array[int] = []
	for stage in data.stages:
		firsts.append(stage.first_stab)
	check_eq(firsts, [1, 8, 16, 24] as Array[int], "anger stages start at stabs 1, 8, 16, 24")
	var kinds: Array[String] = []
	for p in data.patterns:
		kinds.append(p.kind)
	for kind: String in ["small", "big", "burst", "hover", "fake", "drag", "mandu"]:
		check(kinds.has(kind), "pattern kind present: " + kind)
	var burst: Variant = _make().find_pattern("burst")
	check(burst.count_min == 2 and burst.count_max == 5, "bursts are 2 to 5 stabs")
	var hover: Variant = _make().find_pattern("hover_strike")
	check(hover.hover_min_s == 0.5 and hover.hover_max_s == 1.5, "hover 0.5 to 1.5 s")
	var mandu: Variant = _make().find_pattern("mandu_break")
	check(mandu.pause_min_s == 1.5 and mandu.pause_max_s == 2.5, "만두 pause 1.5 to 2.5 s")


func test_the_stage_of_a_stab_number() -> void:
	var d: DirectorScript = _make()
	check_eq(d.stage_for(1), 0, "stab 1")
	check_eq(d.stage_for(7), 0, "stab 7")
	check_eq(d.stage_for(8), 1, "stab 8")
	check_eq(d.stage_for(15), 1, "stab 15")
	check_eq(d.stage_for(16), 2, "stab 16")
	check_eq(d.stage_for(23), 2, "stab 23")
	check_eq(d.stage_for(24), 3, "stab 24")
	check_eq(d.stage_for(30), 3, "stab 30")
	_done(d)


# --- New game -----------------------------------------------------------------------------------

func test_the_new_game_state() -> void:
	var gs: GameStateScript = GameStateScript.new()
	check_eq(gs.hearts, 14, "7 hearts = 14 half-hearts")
	check_eq(gs.sauce, 3, "3 sauce")
	check_eq(gs.sodium, 0, "0 나트륨")
	check_eq(gs.container_id, "", "no container")
	check_eq(gs.inventory_capacity, 0, "no slots")
	for skill: String in ["move", "jump", "landing", "stomp"]:
		check(gs.has_skill(skill), "unlocked: " + skill)
	for skill: String in ["roll", "slam", "sauce_flick"]:
		check(not gs.has_skill(skill), "locked: " + skill)
	check(not gs.prologue_intro_seen and not gs.prologue_complete, "prologue flags start false")
	gs.free()


func test_the_prologue_flags_survive_a_save_round_trip() -> void:
	var a: GameStateScript = GameStateScript.new()
	a.prologue_intro_seen = true
	a.prologue_complete = true
	var b: GameStateScript = GameStateScript.new()
	b.from_dict(JSON.parse_string(JSON.stringify(a.to_dict())))
	check(b.prologue_intro_seen and b.prologue_complete, "both flags round-trip")
	b.from_dict({"hearts": 10}) # an older save without the keys
	check(not b.prologue_intro_seen and not b.prologue_complete, "missing keys read as false")
	b.from_dict({"prologue_intro_seen": "yes", "prologue_complete": 1})
	check(not b.prologue_intro_seen and not b.prologue_complete, "wrong types read as false")
	a.reset()
	check(not a.prologue_intro_seen and not a.prologue_complete, "reset clears them")
	a.free()
	b.free()


# --- The cutscene ---------------------------------------------------------------------------------

func test_the_cutscene_plays_on_the_first_run_and_ends_on_her_cup() -> void:
	var d: DirectorScript = _make()
	d.begin()
	check_eq(d.state, DirectorScript.State.INTRO, "a fresh game starts with the cutscene")
	var shots: int = d.data.shots.size()
	check(shots >= 3 and shots <= 4, "3 to 4 shots (%d)" % shots)
	var total: float = d.intro_total()
	check(total >= 8.0 and total <= 10.0, "about 8 to 10 s in total (%.1f)" % total)
	check_eq(d.data.shots[shots - 1].label, "her_table_and_cup", "the last shot is her table and cup")
	var look: Vector3 = d.data.shots[shots - 1].look_to
	check(absf(look.x - d.data.cup_x) < 0.5, "and it ends looking at the cup")
	var pose: Dictionary = d.camera_pose()
	check(pose["pos"] is Vector3 and pose["look"] is Vector3, "the director gives the camera pose")
	run(d, total - 0.5)
	check_eq(d.state, DirectorScript.State.INTRO, "still playing before the end")
	run(d, 0.6)
	check_eq(d.state, DirectorScript.State.PICK, "then the pick begins")
	check(d.gs.prologue_intro_seen, "the cutscene is marked as seen")
	_done(d)


func test_skipping_the_cutscene_works() -> void:
	var d: DirectorScript = _make()
	d.begin()
	run(d, 1.0)
	check(d.skip_intro(), "skip reports that it skipped")
	check_eq(d.state, DirectorScript.State.PICK, "straight to the pick")
	check(d.gs.prologue_intro_seen, "skipping also marks it as seen")
	check(not d.skip_intro(), "nothing to skip any more")
	_done(d)


func test_the_cutscene_does_not_replay() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var first: DirectorScript = _make(1, gs)
	first.begin()
	first.skip_intro()
	var second: DirectorScript = _make(2, gs)
	second.begin()
	check_eq(second.state, DirectorScript.State.PICK, "a second start in the same game has no cutscene")
	# Being eaten and dying both restart at the pick, never at the cutscene.
	run(second, second.data.window_s + 0.1)
	check_eq(second.state, DirectorScript.State.EATEN, "eaten")
	run(second, second.data.eaten_total_s + 0.1)
	check_eq(second.state, DirectorScript.State.PICK, "after being eaten: the pick again")
	gs.take_damage(14)
	check_eq(second.state, DirectorScript.State.DEAD, "dead")
	second.on_player_respawned()
	check_eq(second.state, DirectorScript.State.PICK, "after dying: the pick again")
	gs.free()


# --- The pick and the wiggle ----------------------------------------------------------------------

func test_the_wiggle_frees_him_in_time() -> void:
	var d: DirectorScript = _make()
	d.gs.prologue_intro_seen = true
	d.begin()
	check_eq(d.state, DirectorScript.State.PICK, "on the pick")
	check_eq(d.line_text, "오~~~ 맛있겠다~~~~~", "she says the opening line")
	var freed: Array[bool] = []
	d.freed.connect(func() -> void: freed.append(true))
	for i: int in 9:
		d.wiggle_press(1 if i % 2 == 0 else -1)
		run(d, 0.3)
	check_eq(d.wiggle_alts, 9, "9 alternations so far")
	check_eq(d.state, DirectorScript.State.PICK, "one short")
	d.wiggle_press(-1 if d.wiggle_last_dir == 1 else 1)
	check_eq(d.state, DirectorScript.State.PRE_STAB, "the 10th alternation frees him")
	check_eq(freed.size(), 1, "freed fired once")
	run(d, d.data.pre_stab_delay_s + 0.1)
	check_eq(d.state, DirectorScript.State.STAB, "then the stabbing starts")
	_done(d)


func test_pressing_the_same_way_does_not_count() -> void:
	var d: DirectorScript = _make()
	d.gs.prologue_intro_seen = true
	d.begin()
	for i: int in 30:
		d.wiggle_press(1)
	check_eq(d.wiggle_alts, 1, "mashing one direction is one alternation")
	check_eq(d.state, DirectorScript.State.PICK, "and does not free him")
	d.wiggle_press(0)
	check_eq(d.wiggle_alts, 1, "no direction does nothing")
	_done(d)


func test_the_last_alternation_just_inside_the_window_wins() -> void:
	var d: DirectorScript = _make()
	d.gs.prologue_intro_seen = true
	d.begin()
	for i: int in 9:
		d.wiggle_press(1 if i % 2 == 0 else -1)
	run(d, d.data.window_s - 0.05)
	check_eq(d.state, DirectorScript.State.PICK, "still on the pick just before the window ends")
	d.wiggle_press(-1)
	check_eq(d.state, DirectorScript.State.PRE_STAB, "freed with 0.05 s to spare")
	_done(d)


func test_failing_the_wiggle_gets_him_eaten_and_restarts_at_the_opening_line() -> void:
	var d: DirectorScript = _make()
	d.gs.prologue_intro_seen = true
	d.begin()
	d.gs.take_damage(4)
	var eaten: Array[bool] = []
	d.eaten.connect(func() -> void: eaten.append(true))
	for i: int in 5:
		d.wiggle_press(1 if i % 2 == 0 else -1)
	run(d, d.data.window_s + 0.05)
	check_eq(d.state, DirectorScript.State.EATEN, "the pick reached her mouth")
	check_eq(eaten.size(), 1, "eaten fired once")
	check(d.eaten_progress() >= 0.0 and d.eaten_progress() < 1.0, "the beat is playing")
	d.wiggle_press(1)
	check_eq(d.state, DirectorScript.State.EATEN, "no wiggling once eaten")
	run(d, d.data.eaten_total_s + 0.1)
	check_eq(d.state, DirectorScript.State.PICK, "restart at the 맛있겠다 moment")
	check_eq(d.count, 0, "count 0")
	check_eq(d.gs.hearts, 14, "hearts back to 7")
	check_eq(d.wiggle_alts, 0, "a fresh wiggle")
	check_eq(d.line_text, "오~~~ 맛있겠다~~~~~", "she says it again")
	_done(d)


# --- Count rules ----------------------------------------------------------------------------------

func test_a_single_small_stab_counts_once() -> void:
	var d: DirectorScript = _in_stab_phase()
	var landed: Array[DirectorScript.Stab] = play(d, "single_small")
	check_eq(landed.size(), 1, "one stab landed")
	check_eq(d.count, 1, "count 1")
	_done(d)


func test_every_stab_of_a_burst_counts() -> void:
	for seed_value: int in [1, 2, 3, 4, 5, 6]:
		var d: DirectorScript = _in_stab_phase(seed_value)
		var landed: Array[DirectorScript.Stab] = play(d, "burst")
		check(landed.size() >= 2 and landed.size() <= 5, "a burst is 2 to 5 stabs (%d)" % landed.size())
		check_eq(d.count, landed.size(), "each stab of the burst counts (seed %d)" % seed_value)
		_done(d)


func test_a_burst_never_runs_past_the_29th_stab() -> void:
	var d: DirectorScript = _in_stab_phase()
	d.debug_set_count(27)
	var landed: Array[DirectorScript.Stab] = play(d, "burst")
	check_eq(landed.size(), 2, "only 2 stabs fit before the finale")
	check_eq(d.count, 29, "count 29: the 30th is the finale")
	_done(d)


func test_a_drag_counts_once() -> void:
	var d: DirectorScript = _in_stab_phase()
	var landed: Array[DirectorScript.Stab] = play(d, "slow_drag")
	check_eq(landed.size(), 1, "the drag lands once")
	check_eq(d.count, 1, "and counts once")
	_done(d)


func test_fake_outs_and_mandu_breaks_do_not_count() -> void:
	var d: DirectorScript = _in_stab_phase()
	var telegraphs: Array[String] = []
	d.telegraph_started.connect(func(s: DirectorScript.Stab) -> void: telegraphs.append(s.kind))
	var landed: Array[DirectorScript.Stab] = play(d, "fake_out")
	check_eq(landed.size(), 0, "a fake-out never lands")
	check_eq(d.count, 0, "a fake-out does not count")
	check_eq(d.gs.hearts, 14, "and does not hurt")
	var before: int = d.plate_mandu
	play(d, "mandu_break")
	check_eq(d.count, 0, "a 만두 break does not count")
	check_eq(d.plate_mandu, before - 1, "but she eats a 만두")
	check_eq(d.gs.hearts, 14, "and it does not hurt")
	check(telegraphs.has("fake") and telegraphs.has("mandu"), "both were telegraphed")
	_done(d)


func test_a_hit_does_not_reset_the_count() -> void:
	var d: DirectorScript = _in_stab_phase()
	play(d, "single_small")
	check_eq(d.gs.hearts, 13, "he stood in the stab: hurt")
	check_eq(d.count, 1, "count 1")
	play(d, "single_small")
	check_eq(d.count, 2, "the count kept going after the hit")
	check_eq(d.gs.hearts, 12, "hurt again")
	_done(d)


func test_a_stab_that_hits_but_is_blocked_by_i_frames_still_counts() -> void:
	var d: DirectorScript = _in_stab_phase()
	d.apply_damage = func(_half: int, _x: float) -> bool: return false
	play(d, "single_small")
	check_eq(d.count, 1, "counted")
	check_eq(d.gs.hearts, 14, "no damage while invulnerable")
	_done(d)


# --- Damage ---------------------------------------------------------------------------------------

func test_a_small_stab_is_one_half_heart() -> void:
	var d: DirectorScript = _in_stab_phase()
	play(d, "single_small")
	check_eq(d.gs.hearts, 13, "14 -> 13")
	check_eq(d.state, DirectorScript.State.STAB, "he is not lifted by a small stab")
	_done(d)


func test_a_big_stab_is_one_heart_and_lifts_him() -> void:
	var d: DirectorScript = _in_stab_phase()
	var lifted: Array[bool] = []
	d.lifted.connect(func(_s: DirectorScript.Stab) -> void: lifted.append(true))
	d.force_next_pattern(d.find_pattern("single_big"))
	for i: int in 600:
		d.step(DT)
		if d.state == DirectorScript.State.LIFT:
			break
	check_eq(d.state, DirectorScript.State.LIFT, "lifted on the pick")
	check_eq(lifted.size(), 1, "lifted fired")
	check_eq(d.gs.hearts, 12, "a big stab takes two half-hearts")
	check_eq(d.count, 1, "and it counted")
	# Same wiggle as on the opening pick.
	check_eq(d.wiggle_required, 10, "same required alternations")
	check_eq(d.wiggle_window, 3.0, "same window")
	_free_him(d)
	check_eq(d.state, DirectorScript.State.STAB, "wiggled off: the stabbing goes on")
	check_eq(d.count, 1, "the count is kept")
	_done(d)


func test_failing_the_wiggle_after_a_big_stab_gets_him_eaten() -> void:
	var d: DirectorScript = _in_stab_phase()
	d.force_next_pattern(d.find_pattern("single_big"))
	for i: int in 600:
		d.step(DT)
		if d.state == DirectorScript.State.LIFT:
			break
	run(d, d.data.lift_window_s + 0.1)
	check_eq(d.state, DirectorScript.State.EATEN, "eaten")
	run(d, d.data.eaten_total_s + 0.1)
	check_eq(d.state, DirectorScript.State.PICK, "back at the 맛있겠다 moment")
	check_eq(d.count, 0, "count 0")
	check_eq(d.gs.hearts, 14, "hearts 7")
	_done(d)


func test_a_stab_misses_a_떡_that_moved_away() -> void:
	var d: DirectorScript = _in_stab_phase()
	d.force_next_pattern(d.find_pattern("single_small"))
	# Wait for the shadow to lock, then step away.
	for i: int in 600:
		d.step(DT)
		if d.stab != null and d.stab.locked:
			break
	check(d.stab != null and d.stab.locked, "the shadow locked")
	d.player_x = d.stab.target_x + 4.0
	run(d, 2.0)
	check_eq(d.count, 1, "the stab still landed and counted")
	check_eq(d.gs.hearts, 14, "but missed him")
	_done(d)


func test_the_shadow_follows_him_until_it_locks() -> void:
	var d: DirectorScript = _in_stab_phase()
	d.force_next_pattern(d.find_pattern("single_small"))
	for i: int in 600:
		d.step(DT)
		if d.stab != null:
			break
	d.player_x = 3.0
	d.step(DT)
	var early: float = d.stab.target_x
	check(absf(early - 3.0) <= d.data.aim_jitter_m + 0.001, "tracking him while unlocked")
	for i: int in 600:
		d.step(DT)
		if d.stab.locked:
			break
	var locked_at: float = d.stab.target_x
	d.player_x = 9.0
	d.step(DT)
	check_eq(d.stab.target_x, locked_at, "once locked it stays")
	_done(d)


# --- Telegraphs -----------------------------------------------------------------------------------

## A whole prologue, with the 떡 standing still and never dying.
func _run_whole_prologue(seed_value: int) -> DirectorScript:
	var d: DirectorScript = _in_stab_phase(seed_value)
	d.apply_damage = func(_half: int, _x: float) -> bool: return false
	var guard: int = 0
	while d.state != DirectorScript.State.EXIT_OPEN and guard < 60 * 60 * 12:
		if d.state == DirectorScript.State.LIFT:
			_free_him(d)
		d.step(DT)
		guard += 1
	return d


func test_every_stab_is_telegraphed_for_at_least_the_minimum() -> void:
	for seed_value: int in [11, 12, 13]:
		var d: DirectorScript = _run_whole_prologue(seed_value)
		check_eq(d.state, DirectorScript.State.EXIT_OPEN, "the exit opened (seed %d)" % seed_value)
		check(d.telegraph_log.size() >= d.landed_count, "a telegraph before every landing")
		check_eq(d.landed_count, 30, "30 stabs landed")
		for entry: Dictionary in d.telegraph_log:
			check(entry["length"] >= MIN_TELEGRAPH - 0.0001,
				"telegraph %.2f s (%s, stage %d) is under the minimum" % [entry["length"], entry["kind"], entry["stage"]])
		_done(d)


func test_telegraphs_shorten_as_her_anger_rises() -> void:
	var d: DirectorScript = _run_whole_prologue(21)
	var base_by_stage: Dictionary = {}
	for entry: Dictionary in d.telegraph_log:
		if entry["kind"] == "small":
			var stage: int = entry["stage"]
			base_by_stage[stage] = minf(base_by_stage.get(stage, 99.0), entry["base"])
	check(base_by_stage.size() >= 3, "small stabs seen in several stages")
	var previous: float = 99.0
	for stage: int in [0, 1, 2, 3]:
		if not base_by_stage.has(stage):
			continue
		check(base_by_stage[stage] <= previous, "stage %d is not slower than the one before" % stage)
		previous = base_by_stage[stage]
	# The stage telegraphs in the data fall strictly, and the last one is above the minimum.
	var data: DataScript = _data()
	for i: int in range(1, data.stages.size()):
		check(data.stages[i].telegraph_s < data.stages[i - 1].telegraph_s, "stage %d telegraph is shorter" % i)
		check(data.stages[i].gap_max_s <= data.stages[i - 1].gap_max_s, "stage %d gaps are shorter" % i)
	check(data.stages[3].telegraph_s >= data.min_telegraph_s, "the last stage stays above the minimum")
	_done(d)


func test_a_burst_follow_up_is_quicker_but_never_below_the_minimum() -> void:
	var d: DirectorScript = _in_stab_phase(3)
	d.apply_damage = func(_half: int, _x: float) -> bool: return false
	d.debug_set_count(24)
	play(d, "burst")
	var lengths: Array[float] = []
	for entry: Dictionary in d.telegraph_log:
		lengths.append(entry["length"])
	check(lengths.size() >= 2, "a burst has several telegraphs")
	if lengths.size() >= 2:
		check(lengths[1] <= lengths[0], "follow-up stabs are quicker")
	for length: float in lengths:
		check(length >= MIN_TELEGRAPH - 0.0001, "still at least the minimum")
	_done(d)


# --- Pattern weights ------------------------------------------------------------------------------

func test_pattern_odds_follow_the_weights_in_every_stage() -> void:
	var d: DirectorScript = _make(99)
	d.plate_mandu = 99
	var freq: Array[Dictionary] = []
	for stage: int in 4:
		var counts: Dictionary = {}
		var total_weight: float = 0.0
		for p in d.data.patterns:
			total_weight += p.weight_for(stage)
		var rolls: int = 8000
		for i: int in rolls:
			var p: Variant = d.pick_pattern(stage, 29)
			counts[p.id] = counts.get(p.id, 0) + 1
		var f: Dictionary = {}
		for p in d.data.patterns:
			f[p.id] = float(counts.get(p.id, 0)) / rolls
			var expected: float = p.weight_for(stage) / total_weight
			check(absf(f[p.id] - expected) < 0.025, "stage %d %s: %.3f vs %.3f" % [stage, p.id, f[p.id], expected])
		freq.append(f)
	for id: String in ["burst", "single_big", "slow_drag"]:
		for stage: int in range(1, 4):
			check(freq[stage][id] > freq[stage - 1][id], "%s gets likelier from stage %d to %d" % [id, stage - 1, stage])
	for stage: int in range(1, 4):
		check(freq[stage]["mandu_break"] < freq[stage - 1]["mandu_break"], "만두 breaks get rarer at stage %d" % stage)
	_done(d)


func test_patterns_that_do_not_fit_are_never_picked() -> void:
	var d: DirectorScript = _make(5)
	d.plate_mandu = 99
	for i: int in 2000:
		var p: Variant = d.pick_pattern(3, 1)
		check(p.kind != "burst", "a burst needs 2 stabs: not with 1 left")
	d.plate_mandu = 0
	for i: int in 2000:
		check(d.pick_pattern(0, 29).kind != "mandu", "no 만두 left on the plate: no break")
	_done(d)


# --- Her lines ------------------------------------------------------------------------------------

func test_her_lines_are_exactly_as_written() -> void:
	var lines: Variant = _data().lines
	var expected: Dictionary = {
		"opening": "오~~~ 맛있겠다~~~~~",
		"stage_1_enter": "아이구 소스 너무 많아",
		"stage_1_later": "이 떡볶이 왜 이렇게 미끄럽지?",
		"stage_2_enter": "야! 왜 그래!!",
		"stage_3_enter": "야 씨발 배고파!",
		"mandu_break": "아 그래",
		"final_stab": "씨~~~~~~발 년아!",
	}
	for key: String in expected:
		var got: String = lines.get_line(key)
		check(got.to_utf8_buffer() == (expected[key] as String).to_utf8_buffer(), "line %s: '%s'" % [key, got])
	check_eq(lines.get_line("no_such_line"), "", "unknown key: empty")


func test_each_line_appears_at_its_trigger() -> void:
	var d: DirectorScript = _in_stab_phase()
	var shown: Array[String] = []
	d.line_shown.connect(func(key: String, _text: String) -> void: shown.append(key))
	d.debug_set_count(6)
	check(not shown.has("stage_1_enter"), "not yet in stage 1")
	play(d, "single_small") # the 7th stab lands: stab 8 is stage 1
	check_eq(d.count, 7, "7 stabs")
	check_eq(shown, ["stage_1_enter"] as Array[String], "entering stage 1")
	check_eq(d.line_text, "아이구 소스 너무 많아", "the stage 1 line is on screen")
	d.debug_set_count(10)
	check(not shown.has("stage_1_later"), "not yet")
	d.debug_set_count(11)
	check(shown.has("stage_1_later"), "later in stage 1")
	check_eq(d.line_text, "이 떡볶이 왜 이렇게 미끄럽지?", "the later line text")
	d.debug_set_count(12)
	check_eq(shown.count("stage_1_later"), 1, "said once")
	d.debug_set_count(15)
	check(shown.has("stage_2_enter"), "entering stage 2")
	check_eq(d.line_text, "야! 왜 그래!!", "stage 2 text")
	d.debug_set_count(23)
	check(shown.has("stage_3_enter"), "entering stage 3")
	check_eq(d.line_text, "야 씨발 배고파!", "stage 3 text")
	var before: int = shown.count("mandu_break")
	play(d, "mandu_break")
	check_eq(shown.count("mandu_break"), before + 1, "every 만두 break")
	play(d, "mandu_break")
	check_eq(shown.count("mandu_break"), before + 2, "every single one")
	check_eq(d.lines_shown.has("final_stab"), false, "the scream is not said early")
	_done(d)


func test_the_line_goes_away_after_a_while() -> void:
	var d: DirectorScript = _make()
	d.gs.prologue_intro_seen = true
	d.begin()
	check(d.line_text != "", "the opening line is up")
	run(d, d.data.line_duration_s + 0.1)
	check_eq(d.line_text, "", "and gone again")
	_done(d)


# --- The exit -------------------------------------------------------------------------------------

func test_the_finale_after_the_29th_stab() -> void:
	var d: DirectorScript = _in_stab_phase()
	d.debug_set_count(29)
	var telegraphed: Array[String] = []
	d.telegraph_started.connect(func(s: DirectorScript.Stab) -> void: telegraphed.append(s.kind))
	var opened: Array[bool] = []
	d.exit_opened.connect(func() -> void: opened.append(true))
	for i: int in 600:
		d.step(DT)
		if not telegraphed.is_empty():
			break
	check_eq(telegraphed, ["final"] as Array[String], "the 30th is the furious stab, telegraphed too")
	check_eq(d.line_text, "씨~~~~~~발 년아!", "she screams")
	check(not d.exit_open, "still closed during the telegraph")
	check(not d.reach_next_table(), "the next table is unreachable until it lands")
	for i: int in 600:
		d.step(DT)
		if d.exit_open:
			break
	check(d.exit_open, "the exit opened")
	check_eq(opened.size(), 1, "exit_opened fired once")
	check_eq(d.count, 30, "30 stabs")
	check_eq(d.state, DirectorScript.State.EXIT_OPEN, "state exit_open")
	check_eq(d.gs.hearts, 14, "the furious stab is a miss: it never hurts, even under it")
	check(d.reach_next_table(), "landing on the next table")
	check_eq(d.state, DirectorScript.State.COMPLETE, "prologue complete")
	check(d.gs.prologue_complete, "remembered")
	check_eq(d.gs.checkpoint_id, "map01_next_table", "respawn point on the next table")
	check_eq(d.gs.checkpoint_position, d.data.next_table_spawn, "at the next table's spawn")
	_done(d)


func test_dying_restarts_at_the_opening_line() -> void:
	var d: DirectorScript = _in_stab_phase()
	d.debug_set_count(12)
	d.gs.take_damage(14)
	check_eq(d.state, DirectorScript.State.DEAD, "dead")
	check(d.stab == null and not d.pattern_running(), "no stab keeps going")
	run(d, 2.0)
	check_eq(d.count, 12, "nothing happens while dead")
	d.gs.respawn() # what the 떡's own respawn does first
	d.on_player_respawned()
	check_eq(d.state, DirectorScript.State.PICK, "back on the pick")
	check_eq(d.count, 0, "count 0")
	check_eq(d.gs.hearts, 14, "7 hearts")
	check_eq(d.stage, 0, "stage 0")
	check(not d.exit_open, "the exit is closed again")
	check_eq(d.line_text, "오~~~ 맛있겠다~~~~~", "the opening line again")
	_done(d)


func test_dying_after_completing_does_not_restart_the_prologue() -> void:
	var d: DirectorScript = _in_stab_phase()
	d.debug_finish()
	check_eq(d.state, DirectorScript.State.COMPLETE, "complete")
	d.gs.take_damage(14)
	check_eq(d.state, DirectorScript.State.COMPLETE, "still complete after dying")
	d.on_player_respawned()
	check_eq(d.state, DirectorScript.State.COMPLETE, "no restart")
	_done(d)


func test_debug_finish_completes_from_anywhere() -> void:
	var d: DirectorScript = _make()
	d.begin()
	d.debug_finish()
	check_eq(d.state, DirectorScript.State.COMPLETE, "straight to complete, even from the cutscene")
	check(d.gs.prologue_complete and d.exit_open, "flags set")
	check_eq(d.count, 30, "30 stabs")
	_done(d)


func test_a_finished_prologue_does_not_start_again() -> void:
	var gs: GameStateScript = GameStateScript.new()
	gs.prologue_complete = true
	var d: DirectorScript = _make(1, gs)
	d.begin()
	check_eq(d.state, DirectorScript.State.COMPLETE, "begin on a finished game: nothing to do")
	check(d.exit_open, "the way on is open")
	gs.free()
