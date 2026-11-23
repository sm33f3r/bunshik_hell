extends "res://tests/map1_base.gd"
## Task 3b-iii on the real Map 1 scene: the 찜기 in the middle of the dining room (one full heal and one
## auto-save, once), the single respawn point, and the save that brings him back. Everything is played
## with real input. The save goes to a temp file, never the player's slot.

const CheckpointDefScript := preload("res://maps/layout/checkpoint_def.gd")

const TEMP_DIR := "user://test_jjigi_run"
const TEMP_SAVE := "user://test_jjigi_run/slot.json"
const JJIGI_ID := "map01_dining_mid"

var saves: Node
var real_path: String = ""


func after_each() -> void:
	if saves != null:
		saves.set("save_path", real_path)
		saves = null
	for file: String in ["slot.json", "slot.json.tmp", "slot.json.bak"]:
		DirAccess.remove_absolute(TEMP_DIR + "/" + file)
	DirAccess.remove_absolute(TEMP_DIR)
	await super()


## Every save in this test goes to the temp file.
func use_temp_saves() -> void:
	saves = tree.root.get_node("SaveSystem")
	real_path = saves.get("save_path")
	saves.set("save_path", TEMP_SAVE)
	DirAccess.remove_absolute(TEMP_SAVE)


func saved_text() -> String:
	var file: FileAccess = FileAccess.open(TEMP_SAVE, FileAccess.READ)
	return file.get_as_text() if file != null else ""


func saved_game() -> Dictionary:
	var parsed: Variant = JSON.parse_string(saved_text())
	return (parsed as Dictionary).get("game", {}) if parsed is Dictionary else {}


## The dining room with the tutorial skipped, quiet (nothing walking about, no hazards).
func open_quiet_dining() -> Node3D:
	use_temp_saves()
	await open_dining()
	clear_enemies()
	hazards_off(["chopsticks.gd", "giant_foot.gd", "gum_patch.gd"])
	return flow.builder.jjigi_nodes[JJIGI_ID] as Node3D


## Stands him beside it and presses up.
func use_it(steamer: Node3D) -> void:
	await put_on("r_t8", 2.0)
	await frames(8) # the zone sees him a physics step after he arrives
	await tap("look_up")
	await frames(3)


func die_and_come_back() -> void:
	gs.call("take_damage", 14)
	check(await until(func() -> bool: return state() == "dead", 30), "he died")
	check(await until(func() -> bool: return state() != "dead" and gs.hearts == 14, 240), "and came back")
	await frames(10)


func test_walking_into_the_dining_room_jjigi_hurt_heals_saves_and_stops_the_steam() -> void:
	var steamer: Node3D = await open_quiet_dining()
	check(steamer != null, "the 찜기 is in the dining room")
	check(steamer.call("steam_on"), "it steams")
	check(not steamer.call("is_spent"), "and looks fresh")
	check(not FileAccess.file_exists(TEMP_SAVE), "no save yet")
	gs.call("take_damage", 9)
	await use_it(steamer)
	check_eq(gs.hearts, 14, "full hearts")
	check(FileAccess.file_exists(TEMP_SAVE), "the save file was written")
	var game: Dictionary = saved_game()
	check((game.get("used_jjigi", []) as Array).has(JJIGI_ID), "and it says this 찜기 is used")
	check_eq(int(game.get("hearts", -1)), 14, "with the full hearts in it")
	check(not steamer.call("steam_on"), "the steam is off")
	check(steamer.call("is_spent"), "it looks used")
	check_eq(gs.checkpoint_id, JJIGI_ID, "it is the respawn point")
	check_eq(gs.respawn_type, "jjigi", "of the 찜기 kind")
	check(gs.has_skill("roll"), "(the tutorial's skills are in the save too)")


func test_dying_later_respawns_at_the_jjigi_with_full_hearts_and_what_he_had() -> void:
	var steamer: Node3D = await open_quiet_dining()
	gs.call("add_sodium", 2)
	gs.call("take_damage", 6)
	var sauce_then: int = gs.sauce
	await use_it(steamer)
	check_eq(gs.hearts, 14, "used")
	gs.call("spend_sauce", 2)
	gs.call("add_sodium", 3)
	await put_on("r_t10", 3.0)
	DirAccess.remove_absolute(TEMP_SAVE)
	await die_and_come_back()
	var spawn: Vector3 = steamer.call("spawn_point")
	check(absf(player.global_position.x - spawn.x) < 1.0 and on_top_of("r_t8"), "back at the 찜기: " + describe())
	check_eq(gs.sodium, 2, "with the 나트륨 he had when he used it")
	check_eq(gs.sauce, sauce_then, "and the sauce")
	check(not FileAccess.file_exists(TEMP_SAVE), "respawning saved nothing")
	check_eq((gs.used_jjigi as Array).size(), 1, "and used nothing")
	check(steamer.call("is_spent") and not steamer.call("steam_on"), "it stays spent")


func test_touching_it_again_does_nothing() -> void:
	var steamer: Node3D = await open_quiet_dining()
	await use_it(steamer)
	DirAccess.remove_absolute(TEMP_SAVE)
	gs.call("take_damage", 4)
	await put_on("r_t10", 3.0)
	await use_it(steamer)
	await frames(10)
	check_eq(gs.hearts, 10, "no heal the second time")
	check(not FileAccess.file_exists(TEMP_SAVE), "no save the second time")
	check(not steamer.call("steam_on"), "no steam")
	check_eq(gs.checkpoint_id, JJIGI_ID, "still the respawn point")
	var prompt: Label3D = steamer.get_node("Prompt") as Label3D
	check(not prompt.visible, "and it shows no prompt")


func test_a_later_checkpoint_is_the_respawn_point_after_the_jjigi() -> void:
	var steamer: Node3D = await open_quiet_dining()
	await use_it(steamer)
	check_eq(gs.respawn_type, "jjigi", "the 찜기 first")
	var later: CheckpointDefScript = CheckpointDefScript.new()
	later.id = "map01_test_later"
	later.platform_id = "r_t12"
	later.along_m = 3.0
	flow.get("_checkpoints").append(later)
	await put_on("r_t12", 3.0)
	await frames(5)
	check_eq(gs.checkpoint_id, "map01_test_later", "the checkpoint reached last wins")
	check_eq(gs.respawn_type, "checkpoint", "of the checkpoint kind")
	gs.call("spend_sauce", 1)
	await put_on("r_t13", 3.0)
	DirAccess.remove_absolute(TEMP_SAVE)
	await die_and_come_back()
	check(on_top_of("r_t12"), "back on the checkpoint's table, not at the 찜기: " + describe())
	check(not FileAccess.file_exists(TEMP_SAVE), "and nothing was saved")
	check(steamer.call("is_spent"), "the 찜기 stays used")
	# Standing on an earlier checkpoint's table again does not take the respawn point back.
	await put_on("dining_1", 6.0)
	await frames(5)
	check_eq(gs.checkpoint_id, "map01_test_later", "a checkpoint behind is not reached again")


func test_save_then_reload_through_the_load_function_gives_the_same_game() -> void:
	var steamer: Node3D = await open_quiet_dining()
	gs.call("try_equip_container", "starter_container")
	gs.call("try_pickup_item", "ggul")
	gs.call("add_sodium", 2)
	gs.ddeok = 17
	gs.call("take_damage", 5)
	await use_it(steamer)
	var at: Vector3 = gs.checkpoint_position
	var items: Array[String] = gs.items.duplicate()
	var sauce: int = gs.sauce
	check(FileAccess.file_exists(TEMP_SAVE), "saved")
	# Leave the game: the room goes, the state is wiped.
	room.queue_free()
	await tree.process_frame
	room = null
	gs.call("reset")
	check(not gs.prologue_complete and gs.items.is_empty(), "(a fresh state)")
	var path: String = saves.call("load_for_play")
	check_eq(path, MAP_SCENE, "the load function names Map 1")
	check_eq(gs.current_map, "map01", "same map")
	check_eq(gs.checkpoint_position, at, "the respawn point is back")
	room = (load(path) as PackedScene).instantiate() as Node3D
	tree.root.add_child(room)
	map = room
	player = room.get_node("Player") as CharacterBody3D
	flow = map.get("flow")
	await frames(40)
	check(absf(player.global_position.x - at.x) < 1.0 and on_top_of("r_t8"), "he stands at the saved respawn point: " + describe())
	check(gs.prologue_complete and gs.prologue_intro_seen, "prologue flags")
	check(gs.tutorial_done and gs.tutorial_prompt_shown, "tutorial flags")
	check(gs.has_skill("roll") and gs.has_skill("slam"), "skills")
	check_eq(gs.skill_sources.get("roll"), "tutorial", "and where they came from")
	check_eq(gs.items, items, "inventory")
	check_eq(gs.container_id, "starter_container", "container")
	check_eq(gs.hearts, 14, "hearts")
	check_eq(gs.sauce, sauce, "sauce")
	check_eq(gs.sodium, 2, "나트륨")
	check_eq(gs.ddeok, 17, "DDEOK")
	check(gs.is_jjigi_used(JJIGI_ID), "the 찜기 is still used")
	var again: Node3D = flow.builder.jjigi_nodes[JJIGI_ID] as Node3D
	check(again.call("is_spent") and not again.call("steam_on"), "and looks used after the reload")
	# It still gives nothing.
	gs.call("take_damage", 4)
	await tap("look_up")
	await frames(3)
	check_eq(gs.hearts, 10, "no heal after the reload")
	# And dying brings him back there.
	await die_and_come_back()
	check(absf(player.global_position.x - at.x) < 1.0, "respawns at the 찜기 after the reload: " + describe())


func test_debug_key_0_loads_the_save_and_goes_to_its_map() -> void:
	var steamer: Node3D = await open_quiet_dining()
	gs.call("take_damage", 5)
	await use_it(steamer)
	var at: Vector3 = gs.checkpoint_position
	gs.call("reset") # he is "somewhere else" with nothing
	tree.current_scene = room # a real game's map is the current scene; the key swaps it
	var old_room: Node = room
	await key_event(KEY_0)
	check(await until(func() -> bool: return tree.current_scene != null and tree.current_scene != old_room, 120), "the scene changed")
	room = tree.current_scene as Node3D
	map = room
	player = room.get_node("Player") as CharacterBody3D
	await frames(30)
	check_eq(gs.current_map, "map01", "the saved map")
	check(gs.is_jjigi_used(JJIGI_ID) and gs.prologue_complete, "the saved state")
	check(absf(player.global_position.x - at.x) < 1.0, "at the saved respawn point: " + describe())


func test_the_hud_flashes_the_save_icon_when_the_jjigi_saves() -> void:
	var steamer: Node3D = await open_quiet_dining()
	var hud: Node = room.get_node("Hud")
	check(not hud.call("save_icon_visible"), "not showing")
	await use_it(steamer)
	check(hud.call("save_icon_visible"), "the small save icon shows")
	await frames(150)
	check(not hud.call("save_icon_visible"), "and goes away again")
