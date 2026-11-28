extends "res://tests/map1_base.gd"
## Task 3c-i-a-bugs, real Map 1 scene: a session that starts past the prologue (a loaded save, a
## --start-at state) sets the anger stage silently: she says nothing and no subtitle comes up.
## The save goes to a temp file, never the player's slot.

const DirectorScript := preload("res://prologue/prologue_director.gd")
const DebugStartScript := preload("res://systems/debug_start.gd")
const GameStateScript := preload("res://systems/game_state.gd")

const TEMP_SAVE := "user://test_past_prologue/slot.json"
const START_ID := "kitchen_front_start"

var saves: Node
var real_path: String = ""


func after_each() -> void:
	if saves != null:
		saves.set("save_path", real_path)
		saves = null
	for file: String in ["slot.json", "slot.json.tmp", "slot.json.bak"]:
		DirAccess.remove_absolute(TEMP_SAVE.get_base_dir() + "/" + file)
	DirAccess.remove_absolute(TEMP_SAVE.get_base_dir())
	await super()


## Watches the freshly loaded map for a while: nothing is said, and the stage and count are the end's.
func check_silent_start(why: String) -> void:
	var director: DirectorScript = map.get("director")
	for i: int in 120:
		if director.line_text != "" or (map.get("ui").get("_subtitle_box") as Control).visible:
			break
		await tree.physics_frame
	check_eq(director.state, DirectorScript.State.COMPLETE, why + ": the prologue is over")
	check_eq(director.line_text, "", why + ": no line queued")
	check_eq(director.lines_shown.keys(), [], why + ": no line was played")
	check_eq(director.reaction_log.size(), 0, why + ": no reaction")
	check(not (map.get("ui").get("_subtitle_box") as Control).visible, why + ": no subtitle")
	check_eq(director.stage, director.data.stages.size() - 1, why + ": the last anger stage")
	check_eq(director.count, director.data.stab_target, why + ": the full stab count")


func open_map() -> void:
	room = (load(MAP_SCENE) as PackedScene).instantiate() as Node3D
	tree.root.add_child(room)
	map = room
	player = room.get_node("Player") as CharacterBody3D
	await frames(1)
	flow = map.get("flow")


func test_loading_a_save_with_key_0_is_silent() -> void:
	gs = tree.root.get_node("GameState")
	gs.call("reset")
	gs.set("prologue_intro_seen", true)
	saves = tree.root.get_node("SaveSystem")
	real_path = saves.get("save_path")
	saves.set("save_path", TEMP_SAVE)
	var past: GameStateScript = GameStateScript.new()
	past.prologue_intro_seen = true
	past.prologue_complete = true
	past.current_map = "map01"
	check(saves.call("save_game", past), "the save was written")
	past.free()
	await open_map()
	var old: Node3D = room
	await key_event(KEY_0)
	check(await until(func() -> bool: return tree.current_scene != null, 60), "the save's map was loaded")
	old.queue_free()
	room = tree.current_scene as Node3D
	map = room
	player = room.get_node("Player") as CharacterBody3D
	await check_silent_start("key 0")


## The command line cannot be given from inside a test, so this applies the --start-at state the way
## the map does and then loads the map on it.
func test_a_start_at_state_is_silent() -> void:
	gs = tree.root.get_node("GameState")
	gs.call("reset")
	gs.set("prologue_intro_seen", true)
	await open_map()
	DebugStartScript.apply(gs, flow, START_ID)
	room.queue_free()
	await tree.process_frame
	await open_map()
	check_eq(gs.checkpoint_id, START_ID, "starting where asked")
	await check_silent_start("--start-at")


func test_debug_key_8_still_plays_the_stage_3_line() -> void:
	await open_prompt()
	var director: DirectorScript = map.get("director")
	check(director.lines_shown.has("stage_3_enter"), "key 8 finishes the prologue as before")
	check_eq(director.stage, director.data.stages.size() - 1, "the last anger stage")
