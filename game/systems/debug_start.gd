extends RefCounted
## DEBUG-ONLY command-line options of Map 1 (ignored in an exported release build; the options
## themselves save nothing):
##   --start-at=<checkpoint or 찜기 id>   a NEW session that starts at that point, as if he had respawned
##                                       there: prologue done, and past the tutorial its skills are his
##   --screenshot=<out.png>              with --start-at: waits a few frames, saves the main viewport to
##                                       the file and quits (needs a real window, not --headless)
## e.g. godot --path game -- --start-at=kitchen_front_start --screenshot=user://shot.png
## They act once per run: loading the map again later (debug key 0) does not start over.

const GameStateScript := preload("res://systems/game_state.gd")
const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const MapSectionScript := preload("res://maps/layout/map_section.gd")
const LayoutGeometryScript := preload("res://maps/layout/layout_geometry.gd")

const START_PREFIX: String = "--start-at="
const SCREENSHOT_PREFIX: String = "--screenshot="
const SCREENSHOT_WAIT_FRAMES: int = 30
## Where a 찜기 puts him when there is no built node to ask (the steamer's default spawn_offset).
const JJIGI_SPAWN_OFFSET: Vector3 = Vector3(1.6, 0.5, 0.0)

static var _taken: bool = false


## Every id --start-at accepts, in the layout's order.
static func start_ids(layout: MapLayoutScript) -> Array[String]:
	var out: Array[String] = []
	for section: MapSectionScript in layout.sections:
		for checkpoint: Resource in section.checkpoints:
			out.append(checkpoint.id)
		for placement: Resource in section.jjigi:
			out.append(placement.id)
	return out


## {"id", "screenshot", "error"} from the user arguments; all "" when neither option is given (or in a
## release build). With an error, "id" is "".
static func parse(args: PackedStringArray, layout: MapLayoutScript, debug_build: bool) -> Dictionary:
	var out: Dictionary = {"id": "", "screenshot": "", "error": ""}
	if not debug_build:
		return out
	var given: bool = false
	var id: String = ""
	for arg: String in args:
		if arg.begins_with(START_PREFIX):
			given = true
			id = arg.trim_prefix(START_PREFIX)
		elif arg.begins_with(SCREENSHOT_PREFIX):
			out["screenshot"] = arg.trim_prefix(SCREENSHOT_PREFIX)
	if given:
		if start_ids(layout).has(id):
			out["id"] = id
		else:
			out["error"] = "--start-at: unknown id '%s'. Known ids: %s" % [id, ", ".join(start_ids(layout))]
	elif out["screenshot"] != "":
		out["error"] = "--screenshot needs --start-at=<id>"
	return out


## The request of this run, once: later calls get an empty one.
static func take_request(layout: MapLayoutScript) -> Dictionary:
	if _taken:
		return {"id": "", "screenshot": "", "error": ""}
	_taken = true
	return parse(OS.get_cmdline_user_args(), layout, OS.is_debug_build())


## Resets `state` to a new game whose respawn point is `id` (a known one). `flow` is the set-up MapFlow.
## Nothing is written to disk.
static func apply(state: GameStateScript, flow: Node, id: String) -> void:
	var layout: MapLayoutScript = flow.get("layout")
	var placed: Array[LayoutGeometryScript.Placed] = flow.get("placed")
	state.reset()
	state.prologue_intro_seen = true
	state.prologue_complete = true
	state.tutorial_prompt_shown = true
	var tutorial: MapSectionScript = flow.call("tutorial_section")
	var section: MapSectionScript = layout.section_of_respawn(id)
	if layout.sections.find(section) > layout.sections.find(tutorial):
		state.tutorial_done = true
		for skill_id: String in tutorial.skip_grants:
			state.unlock_skill(skill_id, tutorial.skip_source)
	var checkpoint: Resource = layout.find_checkpoint(id)
	var point: Resource = checkpoint if checkpoint != null else layout.find_jjigi(id)
	var host: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, point.platform_id)
	# The data checkpoints on the way up to here count as reached, so walking back never moves the respawn.
	for other_section: MapSectionScript in layout.sections:
		for other: Resource in other_section.checkpoints:
			var on: LayoutGeometryScript.Placed = LayoutGeometryScript.find(placed, other.platform_id)
			if other.id != id and on != null and on.index < host.index:
				state.reached_checkpoints.append(other.id)
	if checkpoint != null:
		state.set_checkpoint_snapshot(id, LayoutGeometryScript.checkpoint_position(placed, checkpoint))
		return
	var builder: Node = flow.get("builder")
	var steamer: Node = builder.get("jjigi_nodes").get(id) if builder != null else null
	var at: Vector3 = steamer.call("spawn_point") if steamer != null \
		else LayoutGeometryScript.jjigi_position(placed, point) + JJIGI_SPAWN_OFFSET
	state.use_jjigi(id, at)


## Waits a few frames, saves the main viewport as a PNG and quits (exit 1 when it cannot).
static func screenshot_and_quit(tree: SceneTree, path: String) -> void:
	if DisplayServer.get_name() == "headless":
		printerr("--screenshot needs a real window (run without --headless)")
		tree.quit(1)
		return
	for i: int in SCREENSHOT_WAIT_FRAMES:
		await tree.process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var error: Error = tree.root.get_texture().get_image().save_png(path)
	if error != OK:
		printerr("--screenshot: cannot save '%s' (%s)" % [path, error_string(error)])
		tree.quit(1)
		return
	print("Screenshot saved: ", ProjectSettings.globalize_path(path))
	tree.quit(0)
