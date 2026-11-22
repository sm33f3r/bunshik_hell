extends RefCounted
## The Map 1 prologue as pure logic: no nodes, no physics. The scene (maps/ep01/map01_bunsikjip/map01.gd)
## calls step(delta) once per physics tick, feeds it the 떡's position and wiggle presses, and draws
## what the director says is happening. Tests drive it directly with a fresh GameState.
##
## Flow: INTRO (first run only) -> PICK (wiggle off the opening pick) -> PRE_STAB -> STAB
##   (patterns until the 30th stab) -> EXIT_OPEN (she yanks her forearm away) -> COMPLETE.
## A big stab lifts him: STAB -> LIFT (wiggle again) -> STAB. Failing either wiggle: EATEN ->
## PICK again (count 0, full hearts, no cutscene). Dying: DEAD -> (respawned) -> PICK again.

const GameStateScript := preload("res://systems/game_state.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const StabPatternScript := preload("res://prologue/stab_pattern.gd")
const AngerStageScript := preload("res://prologue/anger_stage.gd")
const CutsceneShotScript := preload("res://prologue/cutscene_shot.gd")

const DATA_PATH: String = "res://data/prologue/prologue.tres"
const CHECKPOINT_START: String = "map01_prologue_start"
const CHECKPOINT_NEXT_TABLE: String = "map01_next_table"

enum State { NOT_STARTED, INTRO, PICK, PRE_STAB, STAB, LIFT, EATEN, DEAD, EXIT_OPEN, COMPLETE }
enum Phase { NONE, TELEGRAPH, STRIKE, HOLD, RETRACT, DRAG, FAKE_RETRACT }

const STATE_NAMES: Array[String] = [
	"not_started", "intro", "pick", "pre_stab", "stab", "lift", "eaten", "dead", "exit_open", "complete",
]
const PHASE_NAMES: Array[String] = [
	"none", "telegraph", "strike", "hold", "retract", "drag", "fake_retract",
]

const KIND_SMALL: String = "small"
const KIND_BIG: String = "big"
const KIND_FAKE: String = "fake"
const KIND_DRAG: String = "drag"
const KIND_MANDU: String = "mandu"
const KIND_FINAL: String = "final"

signal state_changed(new_state: int)
## A line of hers is shown. `key` is the PrologueLines field, `text` the Korean string.
signal line_shown(key: String, text: String)
signal telegraph_started(stab: Stab)
signal stab_landed(stab: Stab)
## A stab or drag hurt him (`half_hearts` was applied; false = ignored by i-frames).
signal stab_hit(stab: Stab, half_hearts: int, applied: bool)
signal count_changed(count: int)
signal stage_changed(stage: int)
## A wiggle press (every press, counted or not): the 떡 squirms.
signal wiggle_pressed(dir: int)
## He slid off the pick (opening or after a lift).
signal freed
signal lifted(stab: Stab)
signal eaten
signal exit_opened
## A 만두 break landed on a live 만두 at this x: she eats it.
signal mandu_eaten(x: float)
signal completed
## The sequence (re)started at the 맛있겠다 moment.
signal restarted

## One stab of a pattern, while it plays.
class Stab extends RefCounted:
	var kind: String = "small"
	var counts: bool = true
	var hazard: bool = true
	var big: bool = false
	var target_x: float = 0.0
	var aim_offset: float = 0.0
	var locked: bool = false
	var phase: int = 0
	var phase_t: float = 0.0
	var phase_len: float = 0.0
	var telegraph_len: float = 0.0
	var lock_t: float = 0.0
	var damage: int = 0
	var half_width: float = 0.3
	var hit_done: bool = false
	var burst_follow: bool = false
	## Seconds she pauses after this stab (the 만두 break).
	var pause_s: float = 0.0
	## A 만두 break that really spears a live 만두 (it may have walked away by the time it lands).
	var mandu_hit: bool = false
	var drag_from: float = 0.0
	var drag_to: float = 0.0
	var drag_s: float = 1.0
	var stage: int = 0
	## Where the pick tip is along x while dragging (else target_x).
	var tip_x: float = 0.0

var data: PrologueDataScript
var gs: GameStateScript
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Her reactions have their own dice, so saying one never changes which stabs come next.
var reaction_rng: RandomNumberGenerator = RandomNumberGenerator.new()
## (half_hearts: int, source_x: float) -> bool. The scene sets it to the 떡's hurt(), which
## honours i-frames. Left invalid, damage goes straight through GameState.take_hit().
var apply_damage: Callable

var state: State = State.NOT_STARTED
var count: int = 0
var stage: int = 0
var exit_open: bool = false
## Where the live 만두 are along the counter (x). The scene refreshes it every tick; a 만두 break
## needs one, and aims at one. Empty = no more 만두 breaks.
var mandu_xs: Array[float] = []
## The 떡's position, set by the scene every tick (x along the counter, y of his feet).
var player_x: float = 0.0
var player_bottom_y: float = 0.0

var stab: Stab = null
var pattern_id: String = ""
## x the pick was stabbed into during a lift.
var lift_x: float = 0.0
## x of the pick when he was eaten (the cup on the opening pick, lift_x after a lift).
var eaten_x: float = 0.0

var intro_t: float = 0.0
var eaten_t: float = 0.0
var wiggle_alts: int = 0
var wiggle_last_dir: int = 0
var wiggle_t: float = 0.0
var wiggle_required: int = 10
var wiggle_window: float = 3.0

var line_key: String = ""
var line_text: String = ""
var line_left: float = 0.0
## True while the line on screen is one of her scheduled lines (never covered by a reaction).
var line_scheduled: bool = false
var lines_shown: Dictionary = {}
## Every reaction she said, in order, and the last one (for "never twice in a row").
var reaction_log: Array[String] = []
var last_reaction: String = ""

## For the HUD and the tests: every telegraph that started (kind, length, stage, hazard).
var telegraph_log: Array[Dictionary] = []
var landed_count: int = 0

var _queue: Array[Dictionary] = []
var _gap_left: float = 0.0
var _pre_left: float = 0.0
var _forced: StabPatternScript = null
var _reaction_pending: bool = false
var _reaction_wait: float = 0.0


func _init(prologue_data: PrologueDataScript = null, game_state: GameStateScript = null) -> void:
	data = prologue_data if prologue_data != null else load(DATA_PATH) as PrologueDataScript
	gs = game_state
	rng.randomize()
	reaction_rng.randomize()
	if gs != null:
		gs.died.connect(_on_died)


func state_name() -> String:
	return STATE_NAMES[state]


func phase_name() -> String:
	return PHASE_NAMES[stab.phase] if stab != null else "none"


# --- Start, cutscene -------------------------------------------------------------------------

## Starts the prologue: the cutscene on a first run, else straight to the pick.
func begin() -> void:
	if gs.checkpoint_id == "":
		gs.set_checkpoint(CHECKPOINT_START, data.start_spawn)
	if gs.prologue_complete:
		exit_open = true
		count = data.stab_target
		_update_stage()
		_set_state(State.COMPLETE)
		return
	if not gs.prologue_intro_seen and not data.shots.is_empty():
		intro_t = 0.0
		_set_state(State.INTRO)
	else:
		_start_pick()


func intro_total() -> float:
	var total: float = 0.0
	for shot: CutsceneShotScript in data.shots:
		total += shot.duration_s
	return total


## Index of the shot playing at intro_t (the last one once past the end).
func intro_shot_index() -> int:
	var t: float = 0.0
	for i: int in data.shots.size():
		t += data.shots[i].duration_s
		if intro_t < t:
			return i
	return maxi(data.shots.size() - 1, 0)


## Camera for the current moment of the cutscene: {"pos": Vector3, "look": Vector3}.
func camera_pose() -> Dictionary:
	if data.shots.is_empty():
		return {"pos": data.pick_camera_pos, "look": data.start_spawn}
	var index: int = intro_shot_index()
	var start: float = 0.0
	for i: int in index:
		start += data.shots[i].duration_s
	var shot: CutsceneShotScript = data.shots[index]
	var u: float = clampf((intro_t - start) / maxf(shot.duration_s, 0.001), 0.0, 1.0)
	return {"pos": data.shot_from(shot).lerp(data.shot_to(shot), u),
		"look": data.shot_look_from(shot).lerp(data.shot_look_to(shot), u)}


## Skip button. Only does anything during the cutscene.
func skip_intro() -> bool:
	if state != State.INTRO:
		return false
	_finish_intro()
	return true


func _finish_intro() -> void:
	gs.prologue_intro_seen = true
	_start_pick()


# --- The pick and the wiggle -----------------------------------------------------------------

## (Re)starts at the 맛있겠다 moment: count 0, full hearts, no cutscene.
func _start_pick() -> void:
	gs.respawn() # full hearts (checkpoint position is not used here)
	count = 0
	landed_count = 0
	stage = 0
	exit_open = false
	stab = null
	pattern_id = ""
	_queue.clear()
	_forced = null
	_gap_left = 0.0
	_reaction_pending = false
	lines_shown.clear()
	telegraph_log.clear()
	_wiggle_reset(data.required_alternations, data.window_s)
	_set_state(State.PICK)
	restarted.emit()
	_show_line("opening")


func _wiggle_reset(required: int, window: float) -> void:
	wiggle_alts = 0
	wiggle_last_dir = 0
	wiggle_t = 0.0
	wiggle_required = maxi(required, 1)
	wiggle_window = maxf(window, 0.01)


## A left (-1) or right (+1) press. Only a change of direction counts as an alternation.
func wiggle_press(dir: int) -> void:
	if state != State.PICK and state != State.LIFT:
		return
	if dir == 0:
		return
	wiggle_pressed.emit(dir)
	if dir != wiggle_last_dir:
		wiggle_last_dir = dir
		wiggle_alts += 1
	if wiggle_alts >= wiggle_required:
		_wiggle_success()


func wiggle_progress() -> float:
	return clampf(float(wiggle_alts) / float(wiggle_required), 0.0, 1.0)


## 0 at the start of the window, 1 when the pick reaches her mouth.
func wiggle_time_progress() -> float:
	return clampf(wiggle_t / wiggle_window, 0.0, 1.0)


func _wiggle_success() -> void:
	if state == State.PICK:
		_pre_left = data.pre_stab_delay_s
		_set_state(State.PRE_STAB)
	else:
		stab = null
		_gap_left = _gap_for(stage)
		_set_state(State.STAB)
	freed.emit()


func _eaten() -> void:
	eaten_x = lift_x if state == State.LIFT else data.cup_x
	stab = null
	_queue.clear()
	eaten_t = 0.0
	_set_state(State.EATEN)
	eaten.emit()


# --- Time ------------------------------------------------------------------------------------

func step(delta: float) -> void:
	if line_left > 0.0:
		line_left = maxf(line_left - delta, 0.0)
		if line_left <= 0.0:
			line_text = ""
			line_key = ""
			line_scheduled = false
	_step_reaction(delta)
	match state:
		State.INTRO:
			intro_t += delta
			if intro_t >= intro_total():
				_finish_intro()
		State.PICK, State.LIFT:
			wiggle_t += delta
			if wiggle_t >= wiggle_window:
				_eaten()
		State.EATEN:
			eaten_t += delta
			if eaten_t >= data.eaten_total_s:
				_start_pick()
		State.PRE_STAB:
			_pre_left -= delta
			if _pre_left <= 0.0:
				_gap_left = 0.0
				_set_state(State.STAB)
		State.STAB:
			_step_stab(delta)
		State.EXIT_OPEN:
			# The 30th stab finishes its retract after the way opened.
			if stab != null:
				_advance_stab(delta)


## 0..1 progress of the eaten beat (the chomp, the blackout from the top, the game-over text).
func eaten_progress() -> float:
	return clampf(eaten_t / maxf(data.eaten_total_s, 0.01), 0.0, 1.0)


# --- Death -----------------------------------------------------------------------------------

func _on_died() -> void:
	if state == State.NOT_STARTED or state == State.COMPLETE or state == State.INTRO:
		return
	stab = null
	_queue.clear()
	_reaction_pending = false
	_set_state(State.DEAD)


## The 떡 came back after dying: start over at the 맛있겠다 moment.
func on_player_respawned() -> void:
	if state == State.DEAD:
		_start_pick()


# --- Stage and lines -------------------------------------------------------------------------

## Anger stage of the stab with this number (1-based).
func stage_for(stab_number: int) -> int:
	var result: int = 0
	for i: int in data.stages.size():
		if stab_number >= (data.stages[i] as AngerStageScript).first_stab:
			result = i
	return result


func _update_stage() -> void:
	var new_stage: int = stage_for(count + 1)
	if new_stage != stage:
		stage = new_stage
		stage_changed.emit(stage)
		match stage:
			1: _show_line("stage_1_enter")
			2: _show_line("stage_2_enter")
			3: _show_line("stage_3_enter")
	if stage == 1 and count >= data.stage1_later_stab and not lines_shown.has("stage_1_later"):
		_show_line("stage_1_later")


func _show_line(key: String) -> void:
	lines_shown[key] = true
	line_scheduled = true
	line_key = key
	line_text = data.lines.get_line(key) if data.lines != null else ""
	line_left = data.line_duration_s
	line_shown.emit(key, line_text)


# --- Her reactions ------------------------------------------------------------------------------

## An attempted stab (landed, drag or fake-out) was made: she will react once the whole pattern
## (a burst is one pattern) is over.
func _note_attempt() -> void:
	_reaction_pending = true
	_reaction_wait = data.reaction_delay_s


## Counts the delay down once no stab is playing or queued, then says the reaction as soon as no
## scheduled line of hers is on screen (a scheduled line is never covered or cut off).
func _step_reaction(delta: float) -> void:
	if not _reaction_pending or pattern_running():
		return
	if state != State.STAB and state != State.PRE_STAB and state != State.LIFT:
		return
	if _reaction_wait > 0.0:
		_reaction_wait -= delta
		return
	if line_left > 0.0 and line_scheduled:
		return
	_reaction_pending = false
	_say_reaction()


func _say_reaction() -> void:
	var pool: Array[String] = []
	for text: String in data.reactions:
		if text != last_reaction:
			pool.append(text)
	if pool.is_empty():
		for text: String in data.reactions:
			pool.append(text)
	if pool.is_empty():
		return
	var text: String = pool[reaction_rng.randi_range(0, pool.size() - 1)]
	last_reaction = text
	reaction_log.append(text)
	line_scheduled = false
	line_key = "reaction"
	line_text = text
	line_left = data.reaction_duration_s
	line_shown.emit("reaction", text)


# --- Patterns --------------------------------------------------------------------------------

## Patterns that may play now: they have odds in this stage, fit before the finale (`remaining`
## = counted stabs still allowed before the 30th), and a 만두 break needs a live 만두.
func eligible_patterns(for_stage: int, remaining: int) -> Array[StabPatternScript]:
	var out: Array[StabPatternScript] = []
	for p: StabPatternScript in data.patterns:
		if p.weight_for(for_stage) <= 0.0 or p.min_stabs() > remaining:
			continue
		if p.kind == "mandu" and mandu_xs.is_empty():
			continue
		out.append(p)
	return out


## Weighted random pick, or null if nothing fits. Does not change any state (but uses rng).
func pick_pattern(for_stage: int, remaining: int) -> StabPatternScript:
	var options: Array[StabPatternScript] = eligible_patterns(for_stage, remaining)
	var total: float = 0.0
	for p: StabPatternScript in options:
		total += p.weight_for(for_stage)
	if total <= 0.0:
		return null
	var roll: float = rng.randf() * total
	for p: StabPatternScript in options:
		roll -= p.weight_for(for_stage)
		if roll < 0.0:
			return p
	return options[options.size() - 1]


## Tests: the next pattern is this one (once), whatever the odds say.
func force_next_pattern(pattern: StabPatternScript) -> void:
	_forced = pattern
	_gap_left = 0.0


## True while a pattern is in progress (a stab is playing or more of its stabs are queued).
func pattern_running() -> bool:
	return stab != null or not _queue.is_empty()


func find_pattern(id: String) -> StabPatternScript:
	for p: StabPatternScript in data.patterns:
		if p.id == id:
			return p
	return null


func _gap_for(for_stage: int) -> float:
	var s: AngerStageScript = data.stages[clampi(for_stage, 0, data.stages.size() - 1)]
	return rng.randf_range(s.gap_min_s, s.gap_max_s)


func _step_stab(delta: float) -> void:
	if stab == null:
		_gap_left -= delta
		if _gap_left <= 0.0:
			_next_stab()
		return
	_advance_stab(delta)


## The next stab of the running pattern, or a new pattern.
func _next_stab() -> void:
	if _queue.is_empty():
		_plan_pattern()
	if _queue.is_empty():
		return
	stab = _make_stab(_queue.pop_front())


func _plan_pattern() -> void:
	var remaining: int = data.stab_target - 1 - count
	if remaining <= 0 and _forced == null:
		_queue = [{"kind": KIND_FINAL}]
		pattern_id = "final"
		return
	var pattern: StabPatternScript = _forced
	_forced = null
	if pattern == null:
		pattern = pick_pattern(stage_for(count + 1), remaining)
	if pattern == null:
		_queue = [{"kind": KIND_SMALL}]
		pattern_id = "small"
		return
	pattern_id = pattern.id
	match pattern.kind:
		"small":
			_queue = [{"kind": KIND_SMALL}]
		"big":
			_queue = [{"kind": KIND_BIG}]
		"burst":
			var n: int = rng.randi_range(pattern.count_min, maxi(mini(pattern.count_max, remaining), pattern.count_min))
			_queue = []
			for i: int in n:
				_queue.append({"kind": KIND_SMALL, "burst_follow": i > 0})
		"hover":
			_queue = [{"kind": KIND_SMALL, "hover": rng.randf_range(pattern.hover_min_s, pattern.hover_max_s)}]
		"fake":
			_queue = [{"kind": KIND_FAKE}]
		"drag":
			_queue = [{"kind": KIND_DRAG, "drag_length": pattern.drag_length_m, "drag_s": pattern.drag_s}]
		"mandu":
			_queue = [{"kind": KIND_MANDU, "pause": rng.randf_range(pattern.pause_min_s, pattern.pause_max_s)}]
		_:
			_queue = [{"kind": KIND_SMALL}]


func _make_stab(spec: Dictionary) -> Stab:
	var s: Stab = Stab.new()
	s.kind = spec["kind"]
	s.stage = stage_for(count + 1)
	s.counts = s.kind in [KIND_SMALL, KIND_BIG, KIND_DRAG, KIND_FINAL]
	s.hazard = s.kind in [KIND_SMALL, KIND_BIG, KIND_DRAG]
	s.big = s.kind == KIND_BIG
	s.burst_follow = spec.get("burst_follow", false)
	s.pause_s = spec.get("pause", 0.0)
	s.damage = data.big_damage if s.big else data.small_damage
	s.half_width = data.big_half_width if s.big else data.small_half_width
	if s.kind == KIND_DRAG:
		s.half_width = data.drag_half_width
		s.drag_s = spec.get("drag_s", 1.4)
		s.drag_to = spec.get("drag_length", 3.0) # the length for now; resolved when it lands
	var base: float = (data.stages[s.stage] as AngerStageScript).telegraph_s
	if s.big:
		base *= data.big_telegraph_mult
	if s.burst_follow:
		base *= data.burst_telegraph_mult
	var base_len: float = maxf(base, data.min_telegraph_s)
	s.telegraph_len = base_len + spec.get("hover", 0.0)
	s.lock_t = s.telegraph_len - base_len * (1.0 - data.lock_fraction)
	s.aim_offset = rng.randf_range(-data.aim_jitter_m, data.aim_jitter_m)
	match s.kind:
		KIND_MANDU:
			s.target_x = _pick_mandu_target()
		KIND_FINAL:
			s.target_x = data.final_x
			s.locked = true
		_:
			s.target_x = _aim(s)
	s.tip_x = s.target_x
	s.phase = Phase.TELEGRAPH
	s.phase_len = s.telegraph_len
	telegraph_log.append({
		"kind": s.kind, "length": s.telegraph_len, "base": base_len, "stage": s.stage,
		"hazard": s.hazard, "count_before": count,
	})
	if s.kind == KIND_FINAL:
		_reaction_pending = false # her scream is the last word
		_show_line("final_stab")
	telegraph_started.emit(s)
	return s


## x of the live 만두 closest to `x` (or `x` itself if there is none).
func _nearest_mandu(x: float) -> float:
	var best: float = x
	var best_distance: float = INF
	for mx: float in mandu_xs:
		if absf(mx - x) < best_distance:
			best_distance = absf(mx - x)
			best = mx
	return best


## A 만두 break aims at a random live 만두 and follows it until the shadow locks.
func _pick_mandu_target() -> float:
	if mandu_xs.is_empty():
		return data.plate_x
	return mandu_xs[rng.randi_range(0, mandu_xs.size() - 1)]


func _aim(s: Stab) -> float:
	if s.kind == KIND_MANDU:
		return _nearest_mandu(s.target_x)
	return clampf(player_x + s.aim_offset, data.section_min_x, data.section_max_x)


func _advance_stab(delta: float) -> void:
	var s: Stab = stab
	s.phase_t += delta
	match s.phase:
		Phase.TELEGRAPH:
			if not s.locked:
				if s.phase_t >= s.lock_t:
					s.locked = true
				else:
					s.target_x = _aim(s)
					s.tip_x = s.target_x
			if s.phase_t >= s.phase_len:
				if s.kind == KIND_FAKE:
					_note_attempt()
					_enter_phase(s, Phase.FAKE_RETRACT, data.fake_retract_s)
				else:
					_enter_phase(s, Phase.STRIKE, data.strike_s)
		Phase.STRIKE:
			if s.phase_t >= s.phase_len:
				_impact(s)
		Phase.HOLD:
			_try_hit_column(s)
			if s.phase_t >= s.phase_len:
				_enter_phase(s, Phase.RETRACT, _retract_len(s))
		Phase.DRAG:
			var u: float = clampf(s.phase_t / maxf(s.phase_len, 0.001), 0.0, 1.0)
			s.tip_x = lerpf(s.drag_from, s.drag_to, u)
			_try_hit_drag(s)
			if s.phase_t >= s.phase_len:
				_enter_phase(s, Phase.RETRACT, _retract_len(s))
		Phase.RETRACT, Phase.FAKE_RETRACT:
			if s.phase_t >= s.phase_len:
				_end_stab(s)


func _retract_len(s: Stab) -> float:
	return data.burst_retract_s if not _queue.is_empty() else data.retract_s


func _enter_phase(s: Stab, phase: int, length: float) -> void:
	s.phase = phase
	s.phase_t = 0.0
	s.phase_len = length


func _impact(s: Stab) -> void:
	if s.counts:
		count += 1
		landed_count += 1
		count_changed.emit(count)
	stab_landed.emit(s)
	if s.kind in [KIND_SMALL, KIND_BIG, KIND_DRAG]:
		_note_attempt()
	match s.kind:
		KIND_FINAL:
			_update_stage()
			exit_open = true
			_enter_phase(s, Phase.HOLD, data.hold_s)
			_set_state(State.EXIT_OPEN)
			exit_opened.emit()
			return
		KIND_MANDU:
			s.mandu_hit = _mandu_in_column(s)
			if s.mandu_hit:
				_show_line("mandu_break")
				mandu_eaten.emit(s.target_x)
			else:
				s.pause_s = 0.0 # nothing on the pick, so no chewing pause
			_enter_phase(s, Phase.HOLD, data.hold_s)
		KIND_DRAG:
			_try_hit_column(s)
			var dir: float = signf(player_x - s.target_x)
			if is_zero_approx(dir):
				dir = 1.0 if rng.randf() < 0.5 else -1.0
			s.drag_from = s.target_x
			var length: float = s.drag_to
			var end_x: float = clampf(s.target_x + dir * length, data.section_min_x, data.section_max_x)
			if absf(end_x - s.target_x) < length * 0.5:
				end_x = clampf(s.target_x - dir * length, data.section_min_x, data.section_max_x)
			s.drag_to = end_x
			if state == State.STAB:
				_enter_phase(s, Phase.DRAG, s.drag_s)
		_:
			_try_hit_column(s)
			if state == State.STAB:
				_enter_phase(s, Phase.HOLD, data.hold_s)
	_update_stage()


## True if any live 만두 is inside the stab's column (so the pick spears it).
func _mandu_in_column(s: Stab) -> bool:
	for mx: float in mandu_xs:
		if absf(mx - s.target_x) < s.half_width + data.mandu_half_width_m:
			return true
	return false


func _in_column(s: Stab) -> bool:
	return absf(player_x - s.target_x) < s.half_width + data.player_half_width


func _try_hit_column(s: Stab) -> void:
	if s.hit_done or not s.hazard or state != State.STAB or not _in_column(s):
		return
	_hurt(s)
	if s.big and state == State.STAB:
		_begin_lift(s)


func _try_hit_drag(s: Stab) -> void:
	if s.hit_done or state != State.STAB:
		return
	if absf(player_x - s.tip_x) < s.half_width + data.player_half_width \
			and player_bottom_y < data.counter_top_y + data.drag_height_m:
		_hurt(s)


func _hurt(s: Stab) -> void:
	s.hit_done = true
	var applied: bool = true
	if apply_damage.is_valid():
		applied = apply_damage.call(s.damage, s.target_x)
	else:
		gs.take_hit(s.damage)
	stab_hit.emit(s, s.damage, applied)


func _begin_lift(s: Stab) -> void:
	lift_x = s.target_x
	_wiggle_reset(data.lift_required_alternations, data.lift_window_s)
	_set_state(State.LIFT)
	lifted.emit(s)


func _end_stab(s: Stab) -> void:
	stab = null
	if _queue.is_empty():
		_gap_left = s.pause_s if s.pause_s > 0.0 else _gap_for(stage)
	else:
		_gap_left = 0.0


# --- The exit ---------------------------------------------------------------------------------

## The 떡 landed on the next table. Only counts once the exit is open.
func reach_next_table() -> bool:
	if state != State.EXIT_OPEN:
		return false
	gs.prologue_complete = true
	gs.set_checkpoint(CHECKPOINT_NEXT_TABLE, data.next_table_spawn)
	_set_state(State.COMPLETE)
	completed.emit()
	return true


## Debug key 8: skip to the end of the prologue (the scene also moves the 떡).
func debug_finish() -> void:
	if state == State.COMPLETE:
		return
	if state == State.INTRO:
		gs.prologue_intro_seen = true
	stab = null
	_queue.clear()
	count = data.stab_target
	landed_count = data.stab_target
	_update_stage()
	exit_open = true
	if state != State.EXIT_OPEN:
		_set_state(State.EXIT_OPEN)
		exit_opened.emit()
	reach_next_table()


## Pause menu "Restart": back to the 맛있겠다 moment (count 0, full hearts). Nothing to restart once
## the prologue is complete (the checkpoint is on the next table then).
func restart() -> bool:
	if state == State.NOT_STARTED or state == State.COMPLETE:
		return false
	_start_pick()
	return true


## Tests and the debug HUD: skip the wiggle.
func debug_free() -> void:
	if state == State.INTRO:
		_finish_intro()
	if state == State.PICK or state == State.LIFT:
		_wiggle_success()


## Tests: pretend this many stabs already landed.
func debug_set_count(n: int) -> void:
	count = n
	_update_stage()


func _set_state(new_state: State) -> void:
	if new_state == state:
		return
	state = new_state
	state_changed.emit(int(state))


## Lines for the debug HUD.
func debug_lines() -> Array[String]:
	var cur: String = "-"
	if stab != null:
		cur = "%s %s %.2f/%.2f s x=%.2f" % [stab.kind, phase_name(), stab.phase_t, stab.phase_len, stab.target_x]
	return [
		"Prologue: %s    Stabs: %d / %d    Anger stage: %d" % [state_name(), count, data.stab_target, stage],
		"Pattern: %s    Current: %s" % [pattern_id if pattern_id != "" else "-", cur],
		"Wiggle: %d / %d alternations   %.1f / %.1f s" % [
			wiggle_alts, wiggle_required, wiggle_t, wiggle_window] if state == State.PICK or state == State.LIFT \
			else "Wiggle: -",
		"8 finish the prologue",
	]
