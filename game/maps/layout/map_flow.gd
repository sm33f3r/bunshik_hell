extends Node
## Map 1 after the prologue: runs the layout data. Builds the platforms, puts the enemies on them,
## asks once whether to do the tutorial, shows its hints, grants the skills, keeps the checkpoints
## and resets the section when he dies or falls. The prologue itself (PrologueDirector and the
## map script) is untouched: this starts when the prologue says it is complete.
##
## Gameplay is closed while the prompt is open: the tree is paused (the way the inventory and the
## popup do it) and the press that closes it is swallowed (GameplayInput).

signal prompt_answered(do_tutorial: bool)
signal checkpoint_reached(checkpoint_id: String)
signal tutorial_finished

enum Phase { IDLE, PROMPT, FADE_OUT, FADE_IN }

const GameStateScript := preload("res://systems/game_state.gd")
const DdeokScript := preload("res://player/ddeok.gd")
const PrologueDataScript := preload("res://prologue/prologue_data.gd")
const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const MapSectionScript := preload("res://maps/layout/map_section.gd")
const CheckpointDefScript := preload("res://maps/layout/checkpoint_def.gd")
const PromptTriggerScript := preload("res://maps/layout/prompt_trigger.gd")
const SpawnEntryScript := preload("res://maps/layout/spawn_entry.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")
const JumpReachScript := preload("res://maps/layout/jump_reach.gd")
const SectionBuilderScript := preload("res://maps/layout/section_builder.gd")
const HintTrackerScript := preload("res://maps/layout/hint_tracker.gd")
const TutorialUiScript := preload("res://ui/tutorial_ui.gd")
const ActionGlyphsScript := preload("res://systems/action_glyphs.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")

const LAYOUT_PATH: String = "res://data/maps/ep01/map01_layout.tres"
const WHEEL_DEF_PATH: String = "res://data/enemies/danmuji.tres"
const TUNING_PATH: String = "res://data/movement_tuning.tres"
## Physics ticks at the start of the prompt during which presses are ignored.
const PROMPT_GUARD_TICKS: int = 4
## How close his feet are to a platform's top for him to count as standing on it (metres).
const STAND_TOLERANCE_M: float = 0.3
## He starts the next section's hints this close above the top (so a hop does not skip a zone).
const HINT_FEET_LIFT_M: float = 0.1

## Injected by tests; the map script passes the real ones to setup().
var game_state: GameStateScript
var player: DdeokScript
var camera: Camera3D
var layout: MapLayoutScript
var reach: JumpReachScript
var placed: Array[LayoutGeometryScript.Placed] = []
var builder: SectionBuilderScript
var ui: TutorialUiScript
var tracker: HintTrackerScript = HintTrackerScript.new()

var phase: Phase = Phase.IDLE
## True while the controller was the last thing he touched (decides which button names show).
var using_pad: bool = false
## Section ids whose enemies are out and whose hints are live.
var enabled_sections: Array[String] = []
## Below this he has fallen off the tables: put back at the checkpoint, no damage. (Over a floor lane
## the catch is lower: see catch_y_at.)
var fall_y: float = -INF
## The tutorial was finished (reaching the last checkpoint of the optional section's way on).
var tutorial_done: bool = false

var _zones: Array[Dictionary] = []
var _checkpoints: Array[CheckpointDefScript] = []
var _guard: int = 0
var _fade_t: float = 0.0
## The fade in progress is the tutorial's own end (he reached the dining room), not the skip.
var _fade_exit: bool = false
## The platform he stood on at the last tick ("" = none), for the "steps onto its platform again" respawn.
var _last_stand: String = ""


## Loads the layout, works out where everything stands and builds it. `data` is the prologue's data
## (the next table the tutorial begins on).
func setup(p_player: DdeokScript, p_camera: Camera3D, p_game_state: GameStateScript, data: PrologueDataScript) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = p_player
	camera = p_camera
	game_state = p_game_state
	layout = load(LAYOUT_PATH) as MapLayoutScript
	var tuning: MovementTuningScript = player.tuning if player != null and player.tuning != null \
		else load(TUNING_PATH) as MovementTuningScript
	var m: float = data.m_per_cm()
	reach = JumpReachScript.new(tuning, load(WHEEL_DEF_PATH) as EnemyDefScript, m)
	var anchor: Dictionary = {
		"left": data.next_table_min_x, "right": data.next_table_max_x, "top": data.next_table_top_y,
		"thickness": data.dims().next_table_thickness_cm * m,
	}
	index_layout(anchor)
	builder = SectionBuilderScript.new()
	builder.name = "Layout"
	add_child(builder)
	builder.build(layout, placed, m, data.dims().counter_depth_cm * m)
	ui = TutorialUiScript.new()
	ui.name = "TutorialUi"
	add_child(ui)


## Places the platforms, and lists the hint zones and checkpoints (also what tests use without a map).
func index_layout(anchor: Dictionary) -> void:
	placed = LayoutGeometryScript.resolve(layout, reach, anchor)
	fall_y = LayoutGeometryScript.lowest_top(placed) - layout.fall_depth_m
	_zones.clear()
	_checkpoints.clear()
	for section: MapSectionScript in layout.sections:
		for trigger: PromptTriggerScript in section.triggers:
			_zones.append({"def": trigger, "rect": LayoutGeometryScript.trigger_rect(placed, trigger), "section": section.id})
		for checkpoint: CheckpointDefScript in section.checkpoints:
			_checkpoints.append(checkpoint)


# --- Sections ---------------------------------------------------------------------------------------

## The optional tutorial: the section that can be skipped (it names where the skip goes).
func tutorial_section() -> MapSectionScript:
	for section: MapSectionScript in layout.sections:
		if section.skip_to_checkpoint != "":
			return section
	return null


func _section_index(section_id: String) -> int:
	for i: int in layout.sections.size():
		if layout.sections[i].id == section_id:
			return i
	return -1


## Turns a section on: its enemies come out and its hints are live.
func enable_section(section_id: String) -> void:
	if not enabled_sections.has(section_id):
		enabled_sections.append(section_id)
	if builder != null:
		builder.spawn_section(section_id)


func disable_section(section_id: String) -> void:
	enabled_sections.erase(section_id)
	if builder != null:
		builder.clear_section(section_id)


## Every enabled section starts over: enemies back where the data puts them, the loot, puddles and
## halves they left behind gone. (A knocked-over 단무지 is one of them: it stands up again.)
func reset_sections() -> void:
	if builder == null:
		return
	if is_inside_tree():
		get_tree().call_group("dropped_loot", "queue_free")
		get_tree().call_group("section_decor", "queue_free")
	for section_id: String in enabled_sections:
		builder.spawn_section(section_id)


# --- The prologue is over ---------------------------------------------------------------------------

## He landed on the next table: the tutorial's checkpoint, then (once per new game) the prompt.
func on_prologue_complete() -> void:
	var tutorial: MapSectionScript = tutorial_section()
	if tutorial == null or tutorial.checkpoints.is_empty():
		return
	if tutorial_done or is_past_tutorial():
		return # he is on the way on already: never back to the tutorial's start, never the prompt again
	reach_checkpoint(tutorial.checkpoints[0])
	if game_state.tutorial_prompt_shown:
		begin_tutorial()
		return
	game_state.tutorial_prompt_shown = true
	open_prompt()


## The map was loaded with the prologue already done: carry on from the checkpoint. No prompt: a
## continued game does not ask again.
func resume() -> void:
	var tutorial: MapSectionScript = tutorial_section()
	if tutorial == null:
		return
	game_state.tutorial_prompt_shown = true
	var section: MapSectionScript = layout.section_of_checkpoint(game_state.checkpoint_id)
	if section != null and _section_index(section.id) > _section_index(tutorial.id):
		tutorial_done = true # a continued game that is past the tutorial
	if section == null:
		# The prologue's own checkpoint (the next table): that is the tutorial's start.
		section = tutorial
		if not tutorial.checkpoints.is_empty():
			reach_checkpoint(tutorial.checkpoints[0])
	for i: int in range(_section_index(section.id), layout.sections.size()):
		if not layout.sections[i].external:
			enable_section(layout.sections[i].id)


## True once the last checkpoint is in a section after the tutorial.
func is_past_tutorial() -> bool:
	var tutorial: MapSectionScript = tutorial_section()
	var section: MapSectionScript = layout.section_of_checkpoint(game_state.checkpoint_id)
	return tutorial != null and section != null and _section_index(section.id) > _section_index(tutorial.id)


# --- The prompt -------------------------------------------------------------------------------------

func prompt_text() -> String:
	return "%s = %s\n%s = %s" % [
		ActionGlyphsScript.glyph("ui_accept", using_pad), layout.prompt_accept_text,
		ActionGlyphsScript.glyph("ui_cancel", using_pad), layout.prompt_cancel_text]


func open_prompt() -> void:
	phase = Phase.PROMPT
	_guard = PROMPT_GUARD_TICKS
	if ui != null:
		ui.show_prompt(prompt_text())
	if is_inside_tree():
		get_tree().paused = true


## ✕ / accept (true) or ○ / cancel (false). Public so tests can answer without a button.
func answer_prompt(do_tutorial: bool) -> void:
	if phase != Phase.PROMPT:
		return
	if ui != null:
		ui.hide_prompt()
	prompt_answered.emit(do_tutorial)
	if do_tutorial:
		phase = Phase.IDLE
		_release_pause()
		begin_tutorial()
	else:
		phase = Phase.FADE_OUT
		_fade_t = 0.0


func begin_tutorial() -> void:
	var tutorial: MapSectionScript = tutorial_section()
	for section: MapSectionScript in layout.sections:
		if section.external or _section_index(section.id) < _section_index(tutorial.id):
			continue
		enable_section(section.id)


func _release_pause() -> void:
	if is_inside_tree():
		get_tree().paused = false
	GameplayInputScript.swallow()


# --- Skills and the toast ---------------------------------------------------------------------------

## Grants a skill from a source. Granting twice is harmless. Returns true when it was new (and then
## the toast shows). `toast_text` may hold {action_id} placeholders.
func grant_skill(skill_id: String, source: String, toast_text: String = "", action: String = "") -> bool:
	var was: bool = game_state.has_skill(skill_id)
	game_state.unlock_skill(skill_id, source)
	var is_new: bool = not was and game_state.has_skill(skill_id)
	if is_new and toast_text != "" and ui != null:
		ui.show_toast(ActionGlyphsScript.fill(toast_text, action, using_pad))
	return is_new


## The skills of skipping (or finishing) the tutorial, as the section's data lists them. One toast
## for all of them.
func grant_tutorial_skills() -> bool:
	var tutorial: MapSectionScript = tutorial_section()
	if tutorial == null:
		return false
	var any_new: bool = false
	for skill_id: String in tutorial.skip_grants:
		if grant_skill(skill_id, tutorial.skip_source):
			any_new = true
	if any_new and ui != null and tutorial.skip_toast != "":
		ui.show_toast(ActionGlyphsScript.fill(tutorial.skip_toast, "", using_pad))
	return any_new


# --- Checkpoints ------------------------------------------------------------------------------------

func checkpoint_index(checkpoint_id: String) -> int:
	for i: int in _checkpoints.size():
		if _checkpoints[i].id == checkpoint_id:
			return i
	return -1


## He is at this checkpoint now: dying brings him back here with full hearts and what he carries now.
func reach_checkpoint(checkpoint: CheckpointDefScript) -> void:
	game_state.set_checkpoint_snapshot(checkpoint.id, LayoutGeometryScript.checkpoint_position(placed, checkpoint))
	checkpoint_reached.emit(checkpoint.id)
	if checkpoint.finishes_tutorial:
		var first: bool = not tutorial_done
		finish_tutorial()
		if first and phase == Phase.IDLE and ui != null and is_inside_tree():
			begin_exit_fade()


## He reached the dining room's first table: the screen fades out and in, as in the skip, and the
## tutorial is left behind (its enemies and hints off) while he stands at the dining room's checkpoint.
func begin_exit_fade() -> void:
	phase = Phase.FADE_OUT
	_fade_t = 0.0
	_fade_exit = true


## Reaching the way on counts as finishing the tutorial: whatever he did not get on the way, he gets.
func finish_tutorial() -> void:
	tutorial_done = true
	grant_tutorial_skills()
	tutorial_finished.emit()


# --- Every physics tick -----------------------------------------------------------------------------

func _physics_process(delta: float) -> void:
	if layout == null or player == null:
		return
	match phase:
		Phase.PROMPT:
			_step_prompt()
			return
		Phase.FADE_OUT:
			_step_fade_out(delta)
			return
		Phase.FADE_IN:
			_step_fade_in(delta)
	if get_tree().paused or enabled_sections.is_empty():
		return
	_step_checkpoints()
	_step_hints()
	_step_respawns(delta)


func _step_prompt() -> void:
	if _guard > 0:
		_guard -= 1
		return
	if Input.is_action_just_pressed("ui_accept"):
		answer_prompt(true)
	elif Input.is_action_just_pressed("ui_cancel"):
		answer_prompt(false)


func _step_fade_out(delta: float) -> void:
	_fade_t += delta
	ui.set_fade(_fade_t / maxf(layout.fade_out_s, 0.01))
	if _fade_t >= layout.fade_out_s:
		if _fade_exit:
			_perform_exit()
		else:
			_perform_skip()
			_release_pause()
		_fade_exit = false
		phase = Phase.FADE_IN
		_fade_t = 0.0


func _step_fade_in(delta: float) -> void:
	_fade_t += delta
	ui.set_fade(1.0 - _fade_t / maxf(layout.fade_in_s, 0.01))
	if _fade_t >= layout.fade_in_s:
		ui.set_fade(0.0)
		phase = Phase.IDLE


## The skip: roll and slam are his, the tutorial's enemies and hints are off, and he is on the way
## on (behind the black screen, so there is no pop).
func _perform_skip() -> void:
	var tutorial: MapSectionScript = tutorial_section()
	grant_tutorial_skills()
	for section: MapSectionScript in layout.sections:
		if section.external:
			continue
		if _section_index(section.id) <= _section_index(tutorial.id):
			disable_section(section.id)
		else:
			enable_section(section.id)
	var target: CheckpointDefScript = layout.find_checkpoint(tutorial.skip_to_checkpoint) as CheckpointDefScript
	if target != null:
		reach_checkpoint(target)
		_move_player_to(game_state.checkpoint_position)
	if ui != null:
		ui.clear_hint()


## The tutorial's end, behind the black screen: its enemies and hints go, he stands at the dining
## room's checkpoint (the checkpoint, the skills and the toast were set when he reached it).
func _perform_exit() -> void:
	var tutorial: MapSectionScript = tutorial_section()
	for section: MapSectionScript in layout.sections:
		if not section.external and _section_index(section.id) <= _section_index(tutorial.id):
			disable_section(section.id)
	if player.call("state_name") != "dead":
		_move_player_to(game_state.checkpoint_position)
	if ui != null:
		ui.clear_hint()


func _move_player_to(at: Vector3) -> void:
	player.global_position = at
	player.velocity = Vector3.ZERO
	player.grounded = false
	player.reset_physics_interpolation()
	if camera != null:
		camera.global_position = Vector3(at.x, at.y, 0.0) + (camera.get("offset") as Vector3)


func _step_checkpoints() -> void:
	if not player.grounded:
		return
	var current: int = checkpoint_index(game_state.checkpoint_id)
	var feet_y: float = player.global_position.y - player.body_half_height
	for i: int in range(current + 1, _checkpoints.size()):
		var platform: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, _checkpoints[i].platform_id)
		if platform == null:
			continue
		var x: float = player.global_position.x
		if x >= platform.left and x <= platform.right and absf(feet_y - platform.top) <= STAND_TOLERANCE_M:
			reach_checkpoint(_checkpoints[i])
			return


func _step_hints() -> void:
	var live: Array[Dictionary] = []
	for zone: Dictionary in _zones:
		if enabled_sections.has(zone["section"]):
			live.append(zone)
	var feet: Vector2 = Vector2(player.global_position.x, player.global_position.y - player.body_half_height + HINT_FEET_LIFT_M)
	for trigger: Resource in tracker.check(live, feet):
		fire_trigger(trigger as PromptTriggerScript)


## The hint goes up (with the glyph names of the device in use) and its skill, if any, is granted.
func fire_trigger(trigger: PromptTriggerScript) -> void:
	if ui != null and trigger.text != "":
		ui.show_hint(ActionGlyphsScript.fill(trigger.text, trigger.action, using_pad), trigger.show_s)
	if trigger.grants_skill != "":
		grant_skill(trigger.grants_skill, trigger.grant_source, trigger.toast, trigger.action)


# --- Things that end up out of reach ----------------------------------------------------------------

## True when a spawned thing is where it is no use any more (see SpawnEntry): fallen off its platform,
## or knocked over (flat) outside the stretch of its platform the entry calls useful.
func is_out_of_reach(node: Node3D, entry: SpawnEntryScript) -> bool:
	var platform: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, entry.platform_id)
	if platform == null or not is_instance_valid(node):
		return false
	var at: Vector3 = node.global_position if node.is_inside_tree() else node.position
	if at.y < platform.top - entry.out_below_m:
		return true
	if entry.useful_from_m != entry.useful_to_m and bool(node.get("flat")):
		var a: float = LayoutGeometryScript.x_on(platform, entry.useful_from_m)
		var b: float = LayoutGeometryScript.x_on(platform, entry.useful_to_m)
		if at.x < minf(a, b) or at.x > maxf(a, b):
			return true
	return false


## The id of the platform he stands on ("" = none).
func standing_on() -> String:
	if player == null or not player.grounded:
		return ""
	var feet_y: float = player.global_position.y - player.body_half_height
	for p: LayoutGeometryScript.Placed in placed:
		if p.def.kind == "floor" or p.def.kind == "block":
			continue
		var x: float = player.global_position.x
		if x >= p.left and x <= p.right and absf(feet_y - p.top) <= STAND_TOLERANCE_M:
			return p.def.id
	return ""


## Every tick: a thing that has been out of reach for its respawn delay is put back as it started; so is
## one that is out of reach when he steps onto its platform again.
func _step_respawns(delta: float) -> void:
	if builder == null:
		return
	var stand: String = standing_on()
	for section_id: String in enabled_sections:
		for node: Node3D in builder.enemies_of(section_id):
			var entry: SpawnEntryScript = node.get_meta("entry", null) as SpawnEntryScript
			if entry == null or not entry.respawn_when_out_of_reach:
				continue
			if is_out_of_reach(node, entry):
				var out_time: float = float(node.get_meta("out_time", 0.0)) + delta
				node.set_meta("out_time", out_time)
				var entered: bool = stand == entry.platform_id and _last_stand != stand
				if out_time >= entry.respawn_delay_s or entered:
					builder.respawn_node(node)
			else:
				node.set_meta("out_time", 0.0)
	_last_stand = stand


# --- Death and falls --------------------------------------------------------------------------------

## Where a fall is caught at x: below the floor lane where there is one (he lands on it first), else
## below the lowest table.
func catch_y_at(x: float) -> float:
	return LayoutGeometryScript.catch_y_at(placed, x, layout.fall_depth_m)


## A new life: the hints may show again, and the section starts over.
func on_player_respawned() -> void:
	tracker.reset()
	if ui != null:
		ui.clear_hint()
	reset_sections()


## Fell off the tables: he was put back at the checkpoint; the section starts over (no damage).
func on_fell() -> void:
	reset_sections()


func _input(event: InputEvent) -> void:
	var was: bool = using_pad
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf((event as InputEventJoypadMotion).axis_value) > 0.5):
		using_pad = true
	elif event is InputEventKey or event is InputEventMouseButton:
		using_pad = false
	if was != using_pad and phase == Phase.PROMPT and ui != null:
		ui.show_prompt(prompt_text())
