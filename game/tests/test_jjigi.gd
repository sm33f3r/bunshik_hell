extends "res://tests/base_test.gd"
## Task 3b-iii: the real 찜기 (ONE full heal and ONE auto-save, once), the single respawn point, and
## the save that carries it. Fresh GameState / SaveSystem / Steamer instances; nothing here relies on
## the autoloads, and every file goes to a temp folder, never the player's slot.

const GameStateScript := preload("res://systems/game_state.gd")
const SaveSystemScript := preload("res://systems/save_system.gd")
const SteamerScript := preload("res://items/steamer.gd")
const JjigiDefScript := preload("res://items/jjigi_def.gd")
const MapCatalogScript := preload("res://systems/map_catalog.gd")
const MapLayoutScript := preload("res://maps/layout/map_layout.gd")
const HudScript := preload("res://ui/hud.gd")

const TEMP_DIR := "user://test_jjigi"
const MAP_DEF := "res://data/jjigi/jjigi_map.tres"
const TEST_ROOM_DEF := "res://data/jjigi/jjigi_test_room.tres"

var _nodes: Array[Object] = []


func after_each() -> void:
	for node: Object in _nodes:
		if is_instance_valid(node):
			if node is Node and (node as Node).is_inside_tree():
				(node as Node).queue_free()
			else:
				node.free()
	_nodes.clear()
	for file: String in ["slot.json", "slot.json.tmp", "slot.json.bak", "other.json"]:
		DirAccess.remove_absolute(TEMP_DIR + "/" + file)
	DirAccess.remove_absolute(TEMP_DIR)


func _gs() -> GameStateScript:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	return gs


func _saves() -> SaveSystemScript:
	var saves: SaveSystemScript = SaveSystemScript.new()
	saves.save_path = TEMP_DIR + "/slot.json"
	_nodes.append(saves)
	return saves


func _steamer(id: String, def: JjigiDefScript, saves: SaveSystemScript = null) -> SteamerScript:
	var steamer: SteamerScript = SteamerScript.new()
	_nodes.append(steamer)
	steamer.steamer_id = id
	steamer.def = def
	steamer.save_system = saves
	steamer.position = Vector3(10.0, 0.0, 0.0)
	return steamer


func _write(path: String, text: String) -> void:
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _text(path: String) -> String:
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	return file.get_as_text() if file != null else ""


# --- The data ---------------------------------------------------------------------------------------

func test_jjigi_def_fields_and_the_two_real_defs() -> void:
	var fresh: JjigiDefScript = JjigiDefScript.new()
	check_eq(fresh.heals_once, true, "heals once by default")
	check_eq(fresh.saves, true, "saves by default")
	check_eq(fresh.debug_unlimited, false, "never unlimited by default")
	check_eq(fresh.id, "", "has an id field")
	check(fresh.steam_amount > 0 and fresh.steam_lifetime_s > 0.0 and fresh.feedback_time > 0.0, "🟡 visual numbers live in the def")
	var map_def: JjigiDefScript = load(MAP_DEF) as JjigiDefScript
	check(map_def != null, "the map def loads")
	check_eq(map_def.id, "jjigi_map", "its id")
	check(map_def.heals_once and map_def.saves and not map_def.debug_unlimited, "the map's: once, saves, not unlimited")
	var room_def: JjigiDefScript = load(TEST_ROOM_DEF) as JjigiDefScript
	check(room_def.debug_unlimited, "the test room's def says debug_unlimited explicitly")


func test_provides_follows_the_flags() -> void:
	var def: JjigiDefScript = JjigiDefScript.new()
	check_eq(def.provides(false), true, "the first time")
	check_eq(def.provides(true), false, "never again")
	def.debug_unlimited = true
	check_eq(def.provides(true), true, "unless explicitly unlimited")


func test_debug_unlimited_is_only_in_the_test_room() -> void:
	var layout: MapLayoutScript = load("res://maps/layout/map_flow.gd").LAYOUT_PATH as MapLayoutScript \
		if false else load("res://data/maps/ep01/map01_layout.tres") as MapLayoutScript
	var placements: int = 0
	for section: Resource in layout.sections:
		for placement: Resource in section.jjigi:
			placements += 1
			check(placement.def != null and not placement.def.debug_unlimited, "%s is not unlimited" % placement.id)
			check(placement.def.heals_once and placement.def.saves, "%s heals once and saves" % placement.id)
	check(placements >= 1, "Map 1 has its 찜기 (%d)" % placements)
	var room: Node = (load("res://maps/test/test_room.tscn") as PackedScene).instantiate()
	_nodes.append(room)
	var in_room: int = 0
	for steamer: Node in room.get_node("Steamers").get_children():
		in_room += 1
		check(steamer.get("def") != null and steamer.get("def").debug_unlimited, "%s is explicitly unlimited" % steamer.name)
	check_eq(in_room, 2, "the test room has its two")


func test_every_placement_id_is_unique_and_stable() -> void:
	var layout: MapLayoutScript = load("res://data/maps/ep01/map01_layout.tres") as MapLayoutScript
	var ids: Array[String] = []
	for section: Resource in layout.sections:
		for placement: Resource in section.jjigi:
			check(placement.id != "", "has an id")
			check(not ids.has(placement.id), "unique: " + placement.id)
			ids.append(placement.id)
		for checkpoint: Resource in section.checkpoints:
			check(not ids.has(checkpoint.id), "a checkpoint id is not a 찜기 id: " + checkpoint.id)
	check(ids.has("map01_dining_mid"), "the dining room's is called map01_dining_mid")


# --- Using it ---------------------------------------------------------------------------------------

func test_the_first_use_heals_fully_and_saves_the_second_does_nothing() -> void:
	var gs: GameStateScript = _gs()
	var saves: SaveSystemScript = _saves()
	var steamer: SteamerScript = _steamer("jj_a", load(MAP_DEF) as JjigiDefScript, saves)
	gs.take_damage(9)
	check_eq(steamer.activate(gs), true, "the first use works")
	check_eq(gs.hearts, 14, "full hearts")
	check(FileAccess.file_exists(saves.save_path), "the save file was written")
	check(gs.is_jjigi_used("jj_a"), "marked used")
	check_eq(gs.checkpoint_id, "jj_a", "it is the respawn point")
	check_eq(gs.respawn_type, "jjigi", "of the 찜기 kind")
	# A second use: nothing at all.
	DirAccess.remove_absolute(saves.save_path)
	gs.take_damage(6)
	check_eq(steamer.activate(gs), false, "the second use is refused")
	check_eq(gs.hearts, 8, "no heal")
	check(not FileAccess.file_exists(saves.save_path), "no save")
	check_eq(gs.used_jjigi, ["jj_a"] as Array[String], "still used once")


func test_a_dead_player_cannot_use_it_and_nothing_is_spent() -> void:
	var gs: GameStateScript = _gs()
	var saves: SaveSystemScript = _saves()
	var steamer: SteamerScript = _steamer("jj_a", load(MAP_DEF) as JjigiDefScript, saves)
	gs.take_damage(14)
	check_eq(steamer.activate(gs), false, "refused while dead")
	check(not gs.is_jjigi_used("jj_a"), "not used up")
	check(not FileAccess.file_exists(saves.save_path), "nothing saved")


func test_each_jjigi_has_its_own_one_use() -> void:
	var gs: GameStateScript = _gs()
	var def: JjigiDefScript = load(MAP_DEF) as JjigiDefScript
	var a: SteamerScript = _steamer("jj_a", def)
	var b: SteamerScript = _steamer("jj_b", def)
	b.position = Vector3(40.0, 0.0, 0.0)
	gs.take_damage(4)
	check(a.activate(gs), "a")
	gs.take_damage(4)
	check(b.activate(gs), "b is a different one")
	check_eq(gs.checkpoint_id, "jj_b", "the later one is the respawn point")
	check(not a.activate(gs), "a stays spent")


func test_only_the_debug_flag_allows_unlimited_use_and_it_does_not_save() -> void:
	var gs: GameStateScript = _gs()
	var saves: SaveSystemScript = _saves()
	var steamer: SteamerScript = _steamer("jj_room", load(TEST_ROOM_DEF) as JjigiDefScript, saves)
	for round: int in 3:
		gs.take_damage(6)
		check(steamer.activate(gs), "use %d works" % (round + 1))
		check_eq(gs.hearts, 14, "healed again")
	check(not FileAccess.file_exists(saves.save_path), "the test room's does not touch the save")
	check(not steamer.is_spent(), "and never looks used")


func test_a_def_that_does_not_save_does_not_save() -> void:
	var gs: GameStateScript = _gs()
	var saves: SaveSystemScript = _saves()
	var def: JjigiDefScript = JjigiDefScript.new()
	def.saves = false
	check(_steamer("jj_x", def, saves).activate(gs), "used")
	check(not FileAccess.file_exists(saves.save_path), "no file")


func test_using_it_stops_the_steam_and_the_look_changes() -> void:
	var gs: GameStateScript = _gs()
	var steamer: SteamerScript = _steamer("jj_look", load(MAP_DEF) as JjigiDefScript)
	steamer.game_state = gs
	tree.root.add_child(steamer)
	await tree.process_frame
	check(steamer.steam_on(), "steaming before")
	check(not steamer.is_spent(), "not spent before")
	gs.take_damage(2)
	check(steamer.activate(gs), "used")
	check(not steamer.steam_on(), "the steam is off")
	check(steamer.is_spent(), "and it is spent")
	steamer.queue_free()


# --- The respawn point ------------------------------------------------------------------------------

func test_the_respawn_point_is_the_most_recent_of_checkpoint_and_jjigi() -> void:
	var gs: GameStateScript = _gs()
	gs.set_checkpoint_snapshot("cp_1", Vector3(1, 0, 0))
	gs.use_jjigi("jj_1", Vector3(2, 0, 0))
	check_eq([gs.checkpoint_id, gs.respawn_type], ["jj_1", "jjigi"], "checkpoint, then 찜기: the 찜기")
	check_eq(gs.respawn(), Vector3(2, 0, 0), "he comes back there")
	gs.set_checkpoint_snapshot("cp_2", Vector3(3, 0, 0))
	check_eq([gs.checkpoint_id, gs.respawn_type], ["cp_2", "checkpoint"], "then a checkpoint: the checkpoint")
	check_eq(gs.respawn(), Vector3(3, 0, 0), "he comes back there")
	check(gs.is_jjigi_used("jj_1"), "the 찜기 is still used up")
	gs.use_jjigi("jj_2", Vector3(4, 0, 0))
	check_eq(gs.respawn(), Vector3(4, 0, 0), "and a later 찜기 again")


func test_respawning_at_a_jjigi_restores_what_he_had_when_he_used_it() -> void:
	var gs: GameStateScript = _gs()
	gs.add_sodium(2)
	gs.spend_sauce(1) # 2 sauce
	gs.take_damage(8)
	gs.use_jjigi("jj_1", Vector3(2, 0, 0))
	check_eq(gs.hearts, 14, "healed")
	gs.add_sodium(4)
	gs.add_sauce(5)
	gs.take_damage(14)
	gs.respawn()
	check_eq(gs.hearts, 14, "full hearts")
	check_eq(gs.sodium, 2, "나트륨 as it was at use time")
	check_eq(gs.sauce, 2, "sauce as it was at use time")


func test_respawning_never_heals_or_saves_through_the_jjigi_again() -> void:
	var gs: GameStateScript = _gs()
	var saves: SaveSystemScript = _saves()
	var steamer: SteamerScript = _steamer("jj_1", load(MAP_DEF) as JjigiDefScript, saves)
	steamer.activate(gs)
	DirAccess.remove_absolute(saves.save_path)
	var used_signals: Array[String] = []
	gs.jjigi_used.connect(func(id: String) -> void: used_signals.append(id))
	gs.take_damage(14)
	gs.respawn()
	check(not FileAccess.file_exists(saves.save_path), "respawning wrote no save")
	check(used_signals.is_empty(), "and did not use the 찜기 again")
	check_eq(gs.used_jjigi, ["jj_1"] as Array[String], "used list unchanged")


func test_a_checkpoint_behind_the_furthest_one_is_not_reached_again() -> void:
	var gs: GameStateScript = _gs()
	gs.set_checkpoint_snapshot("cp_1", Vector3.ZERO)
	gs.set_checkpoint_snapshot("cp_2", Vector3.ONE)
	check_eq(gs.reached_checkpoints, ["cp_1", "cp_2"] as Array[String], "every checkpoint reached is recorded, once")
	gs.set_checkpoint_snapshot("cp_2", Vector3.ONE)
	check_eq(gs.reached_checkpoints.size(), 2, "no duplicates")


# --- The save ---------------------------------------------------------------------------------------

func _busy_state() -> GameStateScript:
	var gs: GameStateScript = _gs()
	gs.unlock_skill("roll", "tutorial")
	gs.unlock_skill("slam", "tutorial")
	gs.unlock_skill("sauce_flick")
	gs.register_defeat("noodle_dummy", "")
	gs.try_equip_container("starter_container")
	gs.try_pickup_item("kongomul")
	gs.try_pickup_item("ggul")
	gs.take_damage(5)
	gs.add_sauce(2)
	gs.add_sodium(3)
	gs.ddeok = 42
	gs.current_map = "map01"
	gs.prologue_intro_seen = true
	gs.prologue_complete = true
	gs.tutorial_prompt_shown = true
	gs.tutorial_done = true
	gs.set_checkpoint_snapshot("cp_1", Vector3(5, 1, 0))
	gs.use_jjigi("jj_1", Vector3(12.5, 3.25, 0.0))
	gs.take_damage(3)
	return gs


func test_every_listed_key_round_trips_through_the_file() -> void:
	var saves: SaveSystemScript = _saves()
	var a: GameStateScript = _busy_state()
	check(saves.save_game(a), "saved: " + saves.last_error)
	var b: GameStateScript = _gs()
	check(saves.load_game(b), "loaded: " + saves.last_error)
	check_eq(b.skills, a.skills, "skills")
	check_eq(b.skill_sources, a.skill_sources, "and where they came from")
	check_eq(b.skill_sources.get("roll"), "tutorial", "(roll came from the tutorial)")
	check_eq(b.container_id, "starter_container", "container")
	check_eq(b.inventory_capacity, a.inventory_capacity, "capacity")
	check_eq(b.items, a.items, "inventory")
	check_eq(b.hearts, a.hearts, "hearts")
	check_eq(b.sauce, a.sauce, "sauce")
	check_eq(b.sodium, a.sodium, "나트륨")
	check_eq(b.ddeok, 42, "DDEOK")
	check_eq(b.current_map, "map01", "current map")
	check_eq(b.checkpoint_id, "jj_1", "respawn point id")
	check_eq(b.respawn_type, "jjigi", "respawn point type")
	check_eq(b.checkpoint_position, Vector3(12.5, 3.25, 0.0), "respawn point position")
	check_eq(b.checkpoint_snapshot, a.checkpoint_snapshot, "what he had when he used it")
	check_eq(b.used_jjigi, ["jj_1"] as Array[String], "used 찜기 ids")
	check_eq(b.reached_checkpoints, ["cp_1"] as Array[String], "reached checkpoint ids")
	check_eq(b.defeated_enemies, a.defeated_enemies, "first-defeat records")
	check(b.prologue_intro_seen and b.prologue_complete, "prologue flags")
	check(b.tutorial_prompt_shown and b.tutorial_done, "tutorial flags")


func test_used_jjigi_stay_used_after_a_reload() -> void:
	var saves: SaveSystemScript = _saves()
	var a: GameStateScript = _gs()
	var steamer: SteamerScript = _steamer("jj_1", load(MAP_DEF) as JjigiDefScript, saves)
	a.take_damage(8)
	steamer.activate(a)
	var b: GameStateScript = _gs()
	check(saves.load_game(b), "loaded")
	check(b.is_jjigi_used("jj_1"), "still used")
	b.take_damage(6)
	check_eq(_steamer("jj_1", load(MAP_DEF) as JjigiDefScript, saves).activate(b), false, "and does nothing again")
	check_eq(b.hearts, 8, "no heal after the reload")


func test_the_kill_counter_enemy_positions_and_props_are_not_saved() -> void:
	var saves: SaveSystemScript = _saves()
	var a: GameStateScript = _busy_state()
	a.kill_counts["mandu"] = 7
	a.kill_counts["gimbap"] = 3
	check(saves.save_game(a), "saved")
	var text: String = _text(saves.save_path)
	for forbidden: String in ["kill_counts", "enemy_pos", "\"enemies\"", "props", "falling", "landed"]:
		check(not forbidden in text.replace("defeated_enemies", ""), "no '%s' in the save" % forbidden)
	var b: GameStateScript = _gs()
	check(saves.load_game(b), "loaded")
	check(b.kill_counts.is_empty(), "the kill counter starts again")
	check(b.defeated_enemies.has("noodle_dummy"), "(first-defeat records are saved)")


func test_an_old_format_save_loads_with_defaults() -> void:
	var saves: SaveSystemScript = _saves()
	_write(saves.save_path, JSON.stringify({"save_version": 1, "game": {
		"hearts": 6, "sauce": 4, "sodium": 1, "skills": {"roll": true},
		"checkpoint_id": "steamer_far", "checkpoint_position": [3, 1, 0]}}))
	var gs: GameStateScript = _gs()
	check(saves.load_game(gs), "loaded: " + saves.last_error)
	check_eq(gs.hearts, 6, "the old keys load")
	check_eq(gs.checkpoint_id, "steamer_far", "respawn id")
	check_eq(gs.respawn_type, "checkpoint", "type defaults to checkpoint")
	check(gs.used_jjigi.is_empty() and gs.reached_checkpoints.is_empty(), "no used 찜기, no reached checkpoints")
	check_eq(gs.current_map, "", "no map recorded")
	check_eq(gs.ddeok, 0, "no DDEOK")
	check(not gs.tutorial_done and not gs.tutorial_prompt_shown, "tutorial flags false")
	check(gs.skill_sources.is_empty() and gs.checkpoint_snapshot.is_empty(), "no sources, no snapshot")
	check_eq(saves.load_for_play(gs), MapCatalogScript.scene_path("map01"), "an old save means the default map")
	check_eq(gs.current_map, "map01", "and says so afterwards")


func test_bad_new_keys_fall_back_to_defaults() -> void:
	var gs: GameStateScript = _gs()
	gs.from_dict({"used_jjigi": "x", "reached_checkpoints": [1, "ok", "ok", ""], "current_map": 5,
		"respawn_type": "wat", "ddeok": -9, "tutorial_done": "yes", "skill_sources": {"roll": 3, "nope": "x"},
		"respawn_snapshot": 4})
	check(gs.used_jjigi.is_empty(), "wrong type: empty")
	check_eq(gs.reached_checkpoints, ["ok"] as Array[String], "only good strings, once")
	check_eq(gs.current_map, "", "map ignored")
	check_eq(gs.respawn_type, "checkpoint", "unknown type: checkpoint")
	check_eq(gs.ddeok, 0, "never negative")
	check(not gs.tutorial_done, "not a bool: false")
	check(gs.skill_sources.is_empty(), "sources need a real skill and a string")


func test_missing_and_corrupt_files_are_treated_as_no_save() -> void:
	var saves: SaveSystemScript = _saves()
	var gs: GameStateScript = _gs()
	gs.take_damage(4)
	check(not saves.has_save(), "no file")
	check_eq(saves.load_for_play(gs), "", "missing: no map to go to")
	check(saves.last_error != "", "and it says why")
	check_eq(gs.hearts, 10, "state untouched")
	var bad: Array[String] = ["", "not json {", "[1]", "{\"save_version\": 1}", "{\"save_version\": 1, \"game\": 5}",
		"{\"save_version\": 1, \"game\": {\"hearts\": 2", "{\"save_version\": 99, \"game\": {}}"]
	for text: String in bad:
		_write(saves.save_path, text)
		check_eq(saves.load_for_play(gs), "", "refused: " + text)
		check(not saves.load_game(gs), "load_game refuses too: " + text)
	check_eq(gs.hearts, 10, "still untouched")


func test_a_save_naming_an_unknown_map_goes_nowhere_and_changes_nothing() -> void:
	var saves: SaveSystemScript = _saves()
	_write(saves.save_path, JSON.stringify({"save_version": 1, "game": {"hearts": 2, "current_map": "../../evil"}}))
	var gs: GameStateScript = _gs()
	check_eq(saves.load_for_play(gs), "", "no scene for it")
	check_eq(gs.hearts, 14, "state untouched")
	check_eq(MapCatalogScript.scene_path("../../evil"), "", "an id never becomes a path")


func test_load_for_play_gives_the_saved_maps_scene() -> void:
	var saves: SaveSystemScript = _saves()
	var a: GameStateScript = _busy_state()
	saves.save_game(a)
	var b: GameStateScript = _gs()
	var path: String = saves.load_for_play(b)
	check_eq(path, "res://maps/ep01/map01_bunsikjip/map01.tscn", "Map 1")
	check(ResourceLoader.exists(path), "and it exists")
	a.current_map = "test_room"
	saves.save_game(a)
	check_eq(saves.load_for_play(b), "res://maps/test/test_room.tscn", "the test room too")


func test_saving_replaces_the_old_file_and_leaves_no_temp_file() -> void:
	var saves: SaveSystemScript = _saves()
	var gs: GameStateScript = _gs()
	check(saves.save_game(gs), "first save")
	gs.take_damage(6)
	check(saves.save_game(gs), "second save over the first: " + saves.last_error)
	var other: GameStateScript = _gs()
	check(saves.load_game(other), "loads")
	check_eq(other.hearts, 8, "the second save is what is there")
	check(not FileAccess.file_exists(saves.save_path + ".tmp"), "no .tmp left")
	check(not FileAccess.file_exists(saves.save_path + ".bak"), "no .bak left")


func test_a_failed_write_leaves_the_old_save_alone() -> void:
	var saves: SaveSystemScript = _saves()
	var gs: GameStateScript = _gs()
	check(saves.save_game(gs), "first save")
	var before: String = _text(saves.save_path)
	DirAccess.make_dir_recursive_absolute(saves.save_path + ".tmp") # the temp file cannot be opened
	gs.take_damage(6)
	check(not saves.save_game(gs), "the save fails (and does not crash)")
	check(saves.last_error != "", "it says why")
	check_eq(_text(saves.save_path), before, "the old save is untouched")
	DirAccess.remove_absolute(saves.save_path + ".tmp")


func test_saving_announces_itself_for_the_hud_icon() -> void:
	var saves: SaveSystemScript = _saves()
	var count: Array[int] = [0]
	saves.saved.connect(func() -> void: count[0] += 1)
	saves.save_game(_gs())
	check_eq(count[0], 1, "one signal per save")
	DirAccess.remove_absolute(saves.save_path)
	saves.load_game(_gs())
	check_eq(count[0], 1, "loading is not saving")


func test_the_hud_flashes_a_save_icon_and_it_goes_away() -> void:
	var gs: GameStateScript = _gs()
	var saves: SaveSystemScript = _saves()
	var hud: HudScript = HudScript.new()
	hud.game_state = gs
	hud.save_system = saves
	tree.root.add_child(hud)
	_nodes.append(hud)
	await tree.process_frame
	check(not hud.save_icon_visible(), "hidden at first")
	saves.save_game(gs)
	check(hud.save_icon_visible(), "shown after a save")
	hud._step_save_icon(HudScript.SAVE_FLASH_S + 0.1)
	check(not hud.save_icon_visible(), "gone after a moment")
