extends "res://tests/base_test.gd"
## Task 3a-polish: her reaction lines after attempted stabs, and the 만두 restock logic.
## A fresh director with a fresh GameState (no autoloads, no scene); time is stepped by hand.

const GameStateScript := preload("res://systems/game_state.gd")
const DirectorScript := preload("res://prologue/prologue_director.gd")
const DataScript := preload("res://prologue/prologue_data.gd")
const ManduRespawnScript := preload("res://prologue/mandu_respawn.gd")

const DT: float = 1.0 / 60.0
## Copied byte for byte from the task. Do not "fix" them.
const POOL: Array[String] = ["야!", "야 왜 그래?!", "젠장아!", "야 씨발 자식아!"]


func _data() -> DataScript:
	return load("res://data/prologue/prologue.tres") as DataScript


func _in_stab_phase(seed_value: int = 1) -> DirectorScript:
	var d: DirectorScript = DirectorScript.new(_data(), GameStateScript.new())
	d.rng.seed = seed_value
	d.reaction_rng.seed = seed_value + 100
	d.gs.prologue_intro_seen = true
	d.begin()
	d.player_x = 5.0
	d.player_bottom_y = 1.0
	d.apply_damage = func(_half: int, _x: float) -> bool: return false
	d.debug_free()
	for i: int in 600:
		if d.state == DirectorScript.State.STAB:
			break
		d.step(DT)
	return d


func _done(d: DirectorScript) -> void:
	var gs: GameStateScript = d.gs
	d.apply_damage = Callable()
	gs.free()


func _free_him(d: DirectorScript) -> void:
	for i: int in d.wiggle_required:
		d.wiggle_press(1 if i % 2 == 0 else -1)


## Steps one tick (freeing him from a lift). Returns true if a reaction was said in this tick.
## Also records breaches of the rules in `problems`.
func _tick(d: DirectorScript, problems: Array[String]) -> bool:
	if d.state == DirectorScript.State.LIFT:
		_free_him(d)
	var before: int = d.reaction_log.size()
	var scheduled_up: bool = d.line_scheduled and d.line_left > DT # still up after this tick
	var running: bool = d.pattern_running()
	d.step(DT)
	var said: bool = d.reaction_log.size() > before
	if said:
		if scheduled_up:
			problems.append("a reaction covered a scheduled line (%s)" % d.line_key)
		if running:
			problems.append("a reaction came before the pattern was over")
	return said


## Forces one pattern, then runs until it is over and the reaction delay and display are done.
func _play_and_wait(d: DirectorScript, pattern_id: String, problems: Array[String]) -> void:
	d.force_next_pattern(d.find_pattern(pattern_id))
	var started: bool = false
	for i: int in 60 * 20:
		_tick(d, problems)
		if d.pattern_running():
			started = true
		elif started:
			break
	# The reaction delay and its time on screen.
	for i: int in int((d.data.reaction_delay_s + 0.5) / DT):
		_tick(d, problems)
		if d.pattern_running():
			break


# --- Data ---------------------------------------------------------------------------------------

func test_the_four_reactions_match_the_task_byte_for_byte() -> void:
	var data: DataScript = _data()
	check_eq(data.reactions.size(), 4, "four reactions")
	for i: int in POOL.size():
		check_eq(data.reactions[i].to_utf8_buffer(), POOL[i].to_utf8_buffer(), "reaction %d bytes" % i)
	check(data.reaction_delay_s >= 0.0 and data.reaction_duration_s > 0.0, "timing is data")


func test_her_scheduled_lines_are_unchanged() -> void:
	var lines: Object = _data().lines
	check_eq(lines.opening, "오~~~ 맛있겠다~~~~~", "opening")
	check_eq(lines.stage_1_enter, "아이구 소스 너무 많아", "stage 1")
	check_eq(lines.stage_1_later, "이 떡볶이 왜 이렇게 미끄럽지?", "stage 1 later")
	check_eq(lines.stage_2_enter, "야! 왜 그래!!", "stage 2")
	check_eq(lines.stage_3_enter, "야 씨발 배고파!", "stage 3")
	check_eq(lines.mandu_break, "아 그래", "만두 break")
	check_eq(lines.final_stab, "씨~~~~~~발 년아!", "final stab")


# --- A reaction after every attempted stab ---------------------------------------------------------

func test_a_reaction_follows_a_landed_small_stab() -> void:
	_expect_one_reaction("single_small")


func test_a_reaction_follows_a_landed_big_stab_after_he_is_freed() -> void:
	_expect_one_reaction("single_big")


func test_a_reaction_follows_a_drag() -> void:
	_expect_one_reaction("slow_drag")


func test_a_reaction_follows_a_fake_out() -> void:
	_expect_one_reaction("fake_out")


func test_a_reaction_follows_a_hover_strike() -> void:
	_expect_one_reaction("hover_strike")


func _expect_one_reaction(pattern_id: String) -> void:
	var d: DirectorScript = _in_stab_phase(3)
	var problems: Array[String] = []
	var shown: Array[String] = []
	d.line_shown.connect(func(key: String, text: String) -> void:
		if key == "reaction":
			shown.append(text))
	_play_and_wait(d, pattern_id, problems)
	check_eq(d.reaction_log.size(), 1, "%s: exactly one reaction" % pattern_id)
	check_eq(shown.size(), 1, "%s: one subtitle" % pattern_id)
	if not d.reaction_log.is_empty():
		check(d.reaction_log[0] in POOL, "%s: from the pool" % pattern_id)
		check_eq(d.line_key, "reaction", "%s: it is on screen" % pattern_id)
	check(problems.is_empty(), "%s: %s" % [pattern_id, "; ".join(problems)])
	_done(d)


func test_a_burst_gets_one_reaction_after_the_burst() -> void:
	for seed_value: int in [1, 2, 3, 4]:
		var d: DirectorScript = _in_stab_phase(seed_value)
		var problems: Array[String] = []
		var landed: Array[int] = [0]
		d.stab_landed.connect(func(_s: DirectorScript.Stab) -> void: landed[0] += 1)
		_play_and_wait(d, "burst", problems)
		check(landed[0] >= 2, "a burst is two stabs or more (%d)" % landed[0])
		check_eq(d.reaction_log.size(), 1, "one reaction for %d stabs (seed %d)" % [landed[0], seed_value])
		check(problems.is_empty(), "; ".join(problems))
		_done(d)


func test_a_mandu_break_is_not_an_attempted_stab_and_gets_no_reaction() -> void:
	var d: DirectorScript = _in_stab_phase(5)
	var problems: Array[String] = []
	d.mandu_xs = [4.0] as Array[float]
	_play_and_wait(d, "mandu_break", problems)
	check_eq(d.reaction_log.size(), 0, "no reaction after the 만두 break (she says 아 그래 instead)")
	_done(d)


# --- Never the same twice, never over a scheduled line --------------------------------------------------

func test_never_the_same_reaction_twice_in_a_row() -> void:
	var d: DirectorScript = _in_stab_phase(7)
	var problems: Array[String] = []
	for i: int in 40:
		_play_and_wait(d, "fake_out", problems)
	check(d.reaction_log.size() >= 30, "many reactions (%d)" % d.reaction_log.size())
	for i: int in range(1, d.reaction_log.size()):
		check(d.reaction_log[i] != d.reaction_log[i - 1], "repeat at %d (%s)" % [i, d.reaction_log[i]])
	for text: String in POOL:
		check(text in d.reaction_log, "%s is used" % text)
	_done(d)


func test_a_reaction_never_covers_or_cuts_off_a_scheduled_line() -> void:
	var d: DirectorScript = _in_stab_phase(8)
	var problems: Array[String] = []
	d.force_next_pattern(d.find_pattern("fake_out"))
	var started: bool = false
	for i: int in 60 * 20:
		_tick(d, problems)
		if d.pattern_running():
			started = true
		elif started:
			break
	# One of her scheduled lines starts right now, before the reaction delay is over.
	d._show_line("mandu_break")
	check_eq(d.line_key, "mandu_break", "her scheduled line is up")
	var key_while_up: Array[String] = []
	for i: int in int((d.data.line_duration_s - 0.2) / DT):
		_tick(d, problems)
		if d.line_scheduled and d.line_left > 0.0:
			key_while_up.append(d.line_key)
		if d.pattern_running():
			break
	check(not key_while_up.has("reaction"), "the reaction waited")
	check(problems.is_empty(), "; ".join(problems))
	_done(d)


func test_the_whole_prologue_follows_every_rule() -> void:
	for seed_value: int in [21, 22, 23]:
		var d: DirectorScript = _in_stab_phase(seed_value)
		var problems: Array[String] = []
		var guard: int = 0
		while d.state != DirectorScript.State.EXIT_OPEN and guard < 60 * 60 * 12:
			_tick(d, problems)
			guard += 1
		check_eq(d.state, DirectorScript.State.EXIT_OPEN, "the exit opened (seed %d)" % seed_value)
		check(d.reaction_log.size() >= 5, "she reacted along the way (%d)" % d.reaction_log.size())
		for text: String in d.reaction_log:
			check(text in POOL, "only strings of the pool: %s" % text)
		for i: int in range(1, d.reaction_log.size()):
			check(d.reaction_log[i] != d.reaction_log[i - 1], "no repeat (seed %d, at %d)" % [seed_value, i])
		check(problems.is_empty(), "seed %d: %s" % [seed_value, "; ".join(problems)])
		# Her scream is the last word: no reaction after the final stab.
		var count_at_exit: int = d.reaction_log.size()
		for i: int in 60 * 3:
			d.step(DT)
		check_eq(d.reaction_log.size(), count_at_exit, "no reaction after the final scream")
		_done(d)


func test_a_restart_forgets_a_reaction_that_was_waiting() -> void:
	var d: DirectorScript = _in_stab_phase(9)
	d.force_next_pattern(d.find_pattern("fake_out"))
	var problems: Array[String] = []
	for i: int in 60 * 6:
		_tick(d, problems)
		if d._reaction_pending and not d.pattern_running():
			break
	check(d._reaction_pending, "one is waiting")
	d.restart()
	check(not d._reaction_pending, "restart clears it")
	_done(d)


# --- 만두 restock ------------------------------------------------------------------------------------

func test_the_last_mandu_gone_brings_two_after_the_delay() -> void:
	var r: ManduRespawnScript = ManduRespawnScript.new(2, 1.5)
	check_eq(r.update(3, DT, true), 0, "three alive: nothing")
	check_eq(r.update(1, DT, true), 0, "one alive: nothing")
	var spawned: int = 0
	var ticks: int = 0
	while spawned == 0 and ticks < 600:
		spawned = r.update(0, DT, true)
		ticks += 1
	check_eq(spawned, 2, "two appear")
	check(absf(float(ticks) * DT - 1.5) < 0.05, "after about 1.5 s (%d ticks)" % ticks)
	check_eq(r.update(2, DT, true), 0, "and no more while they live")


func test_nothing_appears_while_one_is_still_alive() -> void:
	var r: ManduRespawnScript = ManduRespawnScript.new(2, 1.5)
	r.update(2, DT, true)
	for i: int in 300:
		check_eq(r.update(1, DT, true), 0, "one alive: nothing")


func test_it_restocks_again_each_time_the_plate_runs_out() -> void:
	var r: ManduRespawnScript = ManduRespawnScript.new(2, 0.5)
	var total: int = 0
	for round: int in 3:
		r.update(2, DT, true)
		for i: int in 120:
			total += r.update(0, DT, true)
	check_eq(total, 6, "two each time, three times")


func test_nothing_appears_when_the_stabbing_is_not_going_on() -> void:
	var r: ManduRespawnScript = ManduRespawnScript.new(2, 0.5)
	r.update(3, DT, true)
	for i: int in 200:
		check_eq(r.update(0, DT, false), 0, "wiggle, cutscene, eaten beat: nothing")
	check(not r.waiting(), "not counting down")


func test_a_reset_forgets_a_countdown() -> void:
	var r: ManduRespawnScript = ManduRespawnScript.new(2, 1.0)
	r.update(1, DT, true)
	r.update(0, DT, true)
	check(r.waiting(), "counting down")
	r.reset()
	check(not r.waiting(), "reset stops it")
	for i: int in 200:
		check_eq(r.update(0, DT, true), 0, "and nothing comes from an empty start")


func test_restock_numbers_are_data() -> void:
	var data: DataScript = _data()
	check_eq(data.mandu_respawn_count, 2, "two at a time")
	check(absf(data.mandu_respawn_delay_s - 1.5) < 0.0001, "1.5 s to start with")
	check_eq(data.plate_mandu_count, 3, "the start is still three")
