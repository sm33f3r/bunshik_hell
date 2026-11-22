extends "res://tests/base_test.gd"
## Task 3a-polish: the Settings "Controls" page, the clean game screen, debug key 9, and the icon HUD.

const GameStateScript := preload("res://systems/game_state.gd")
const SettingsScript := preload("res://systems/settings.gd")
const PauseMenuScript := preload("res://ui/pause_menu.gd")
const ControlsListingScript := preload("res://systems/controls_listing.gd")
const HudScript := preload("res://ui/hud.gd")
const HudIconScript := preload("res://ui/hud_icon.gd")
const HudIconCatalogScript := preload("res://ui/hud_icon_catalog.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")

const MAP_SCENE: String = "res://maps/ep01/map01_bunsikjip/map01.tscn"
const ROOM_SCENE: String = "res://maps/test/test_room.tscn"
const GAME_ACTIONS: Array[String] = [
	"move_left", "move_right", "look_up", "look_down", "jump", "roll",
	"sauce_attack", "special", "sauce_next", "sauce_prev", "heal",
	"inventory", "drop_item", "pause", "aim_left", "aim_right", "aim_up", "aim_down",
	"ui_accept", "ui_cancel",
]
## Words that mean a line tells the player which button to press.
const INSTRUCTION_WORDS: Array[String] = ["skip", "<->", "jump", "enter", "mouse", "press", "move", "wasd", "space"]

var _extra: Array[Node] = []


func after_each() -> void:
	for node: Node in _extra:
		if is_instance_valid(node):
			node.queue_free()
	_extra.clear()
	GameplayInputScript.clear()
	tree.paused = false
	await tree.process_frame


# --- Controls page --------------------------------------------------------------------------------

func test_the_controls_page_lists_every_action_of_the_input_map() -> void:
	var rows: Array[Dictionary] = ControlsListingScript.rows()
	var ids: Array[String] = []
	for row: Dictionary in rows:
		ids.append(row["action"])
	for action: String in GAME_ACTIONS:
		check(action in ids, "missing from the Controls page: " + action)
	# Nothing but the menu pair of the built-in ui_* actions.
	for id: String in ids:
		check(not id.begins_with("ui_") or id == "ui_accept" or id == "ui_cancel", "unexpected " + id)
	for action: StringName in InputMap.get_actions():
		var id: String = String(action)
		if not id.begins_with("ui_"):
			check(id in ids, "an input-map action is missing: " + id)


func test_every_row_shows_the_real_bindings() -> void:
	for row: Dictionary in ControlsListingScript.rows():
		var id: String = row["action"]
		var has_pad: bool = false
		var has_keys: bool = false
		for event: InputEvent in InputMap.action_get_events(id):
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_pad = true
			else:
				has_keys = true
		check_eq(row["controller"] != "-", has_pad, "%s controller column" % id)
		check_eq(row["keyboard"] != "-", has_keys, "%s keyboard column" % id)
	for row: Dictionary in ControlsListingScript.rows():
		if row["action"] == "jump":
			check("Space" in String(row["keyboard"]), "jump shows Space")
			check("✕" in String(row["controller"]), "jump shows ✕")
		if row["action"] == "inventory":
			check("Tab" in String(row["keyboard"]), "inventory shows Tab")
			check("Touchpad" in String(row["controller"]), "inventory shows the touchpad")


func test_the_page_follows_the_input_map_when_a_binding_changes() -> void:
	InputMap.add_action("zz_test_action")
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_F9
	InputMap.action_add_event("zz_test_action", key)
	var pad: InputEventJoypadButton = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_Y
	InputMap.action_add_event("zz_test_action", pad)
	var found: Dictionary = {}
	for row: Dictionary in ControlsListingScript.rows():
		if row["action"] == "zz_test_action":
			found = row
	InputMap.erase_action("zz_test_action")
	check(not found.is_empty(), "a new action appears without any code change")
	check_eq(found.get("keyboard"), "F9", "its key")
	check("△" in String(found.get("controller", "")), "its button")


func _menu() -> PauseMenuScript:
	GameplayInputScript.clear()
	var menu: PauseMenuScript = PauseMenuScript.new()
	menu.game_state = GameStateScript.new()
	var settings: SettingsScript = SettingsScript.new()
	settings.settings_path = "user://test_controls_page_tmp.json"
	menu.settings = settings
	menu.quit_action = func() -> void: pass
	tree.root.add_child(menu)
	_extra.append(menu)
	return menu


func test_settings_leads_to_a_read_only_controls_page() -> void:
	var menu: PauseMenuScript = _menu()
	menu.open()
	menu.choose_main(PauseMenuScript.ITEM_SETTINGS)
	check_eq(menu.screen, PauseMenuScript.Screen.SETTINGS, "in settings")
	check("Controls" in menu.screen_text(), "settings lists Controls")
	menu.change_setting(PauseMenuScript.SETTING_CONTROLS, 1)
	check_eq(menu.screen, PauseMenuScript.Screen.SETTINGS, "left / right does nothing to it")
	menu.screen = PauseMenuScript.Screen.CONTROLS
	var text: String = menu.screen_text()
	for row: Dictionary in ControlsListingScript.rows():
		check(String(row["keyboard"]) in text and String(row["controller"]) in text, "page shows " + row["action"])
	check_eq(menu.screen, PauseMenuScript.Screen.CONTROLS, "stays read-only")


func test_the_controls_page_opens_and_closes_with_the_buttons() -> void:
	var menu: PauseMenuScript = _menu()
	menu.open()
	menu.choose_main(PauseMenuScript.ITEM_SETTINGS)
	menu.selected = PauseMenuScript.SETTING_CONTROLS
	for i: int in 4:
		await tree.process_frame
	Input.action_press("ui_accept")
	await tree.process_frame
	Input.action_release("ui_accept")
	check_eq(menu.screen, PauseMenuScript.Screen.CONTROLS, "confirm opens it")
	for i: int in 4:
		await tree.process_frame
	Input.action_press("ui_cancel")
	await tree.process_frame
	Input.action_release("ui_cancel")
	check_eq(menu.screen, PauseMenuScript.Screen.SETTINGS, "back returns to settings")
	check_eq(menu.selected, PauseMenuScript.SETTING_CONTROLS, "on the Controls row")


# --- A clean game screen ----------------------------------------------------------------------------

func _visible_label_texts(root: Node) -> Array[String]:
	var out: Array[String] = []
	for node: Node in root.find_children("*", "Label", true, false):
		var label: Label = node as Label
		if label.is_visible_in_tree() and label.text.strip_edges() != "":
			out.append(label.text)
	return out


func test_map_1_shows_no_instruction_text() -> void:
	var map: Node = (load(MAP_SCENE) as PackedScene).instantiate()
	tree.root.add_child(map)
	_extra.append(map)
	for i: int in 3:
		await tree.process_frame
	var texts: Array[String] = _visible_label_texts(map)
	for text: String in texts:
		for word: String in INSTRUCTION_WORDS:
			check(not word in text.to_lower(), "instruction text on screen: \"%s\"" % text)
	var debug_hud: Node = map.get_node("DebugHud")
	check(not debug_hud.call("text_visible"), "the debug text is hidden in the game")
	var wiggle_label_ok: bool = true
	for node: Node in map.find_children("*", "Label", true, false):
		if "<->" in (node as Label).text or "Skip" in (node as Label).text:
			wiggle_label_ok = false
	check(wiggle_label_ok, "no controls in the wiggle meter or a skip hint")
	check(map.get_node_or_null("Hud") != null, "the icon HUD is there")


func test_key_9_toggles_the_debug_text_and_the_other_keys_still_work() -> void:
	var map: Node = (load(MAP_SCENE) as PackedScene).instantiate()
	tree.root.add_child(map)
	_extra.append(map)
	await tree.process_frame
	var debug_hud: Node = map.get_node("DebugHud")
	var keys: Node = map.get_node("DebugKeys")
	var gs: Node = tree.root.get_node("GameState")
	check(not debug_hud.call("text_visible"), "hidden at the start")
	_press(keys, KEY_9)
	check(debug_hud.call("text_visible"), "key 9 shows it")
	_press(keys, KEY_9)
	check(not debug_hud.call("text_visible"), "key 9 hides it again")
	var hearts_before: int = gs.hearts
	_press(keys, KEY_4)
	check_eq(gs.hearts, hearts_before - 2, "key 4 still works with the text hidden")
	gs.reset()


func _press(target: Node, keycode: Key) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = keycode
	event.pressed = true
	target.call("_unhandled_key_input", event)


func test_the_test_room_may_show_the_debug_text_by_default() -> void:
	var room: Node = (load(ROOM_SCENE) as PackedScene).instantiate()
	tree.root.add_child(room)
	_extra.append(room)
	await tree.process_frame
	check(room.get_node("DebugHud").call("text_visible"), "shown in the test room")
	for text: String in _visible_label_texts(room.get_node("DebugHud")):
		check(not "Space jump" in text and not "Mouse1" in text, "no controls line in the debug text")
	check(room.get_node_or_null("Hud") != null, "the icon HUD is in the test room too")


# --- Icon HUD -----------------------------------------------------------------------------------------

func _hud(gs: GameStateScript) -> HudScript:
	var hud: HudScript = HudScript.new()
	hud.game_state = gs
	tree.root.add_child(hud)
	_extra.append(hud)
	return hud


func test_the_hud_shows_hearts_with_halves() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var hud: HudScript = _hud(gs)
	check_eq(hud.hearts_text(), "7/7", "full")
	gs.take_damage(1)
	hud.refresh()
	check_eq(hud.hearts_text(), "6.5/7", "13 half-hearts is 6.5")
	check_eq(hud._hearts_label.text, "6.5/7", "and it is what the label says")
	gs.take_damage(2)
	hud.refresh()
	check_eq(hud._hearts_label.text, "5.5/7", "5.5")
	gs.free()


func test_the_hud_numbers_follow_sauce_and_sodium() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var hud: HudScript = _hud(gs)
	check_eq(hud._sauce_label.text, "3/7", "sauce starts at 3")
	check_eq(hud._sodium_label.text, "0/7", "나트륨 starts at 0")
	gs.add_sauce(2)
	gs.add_sodium(4)
	hud.refresh()
	check_eq(hud._sauce_label.text, "5/7", "sauce 5")
	check_eq(hud._sodium_label.text, "4/7", "나트륨 4")
	gs.spend_sauce(5)
	gs.spend_sodium(4)
	hud.refresh()
	check_eq(hud._sauce_label.text, "0/7", "sauce 0")
	check_eq(hud._sodium_label.text, "0/7", "나트륨 0")
	gs.free()


func test_the_coat_icon_shows_only_while_the_coat_is_on() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var hud: HudScript = _hud(gs)
	check(not hud.coat_visible(), "no coat at the start")
	gs.try_equip_container("starter_container")
	gs.take_damage(4)
	gs.try_pickup_item("kongomul")
	gs.use_item_at(0)
	check(gs.coat, "the coat is on")
	hud.refresh()
	check(hud.coat_visible(), "the coat icon shows")
	gs.take_hit(2)
	hud.refresh()
	check(not gs.coat and not hud.coat_visible(), "gone once it has blocked a hit")
	gs.free()


func test_the_hud_shows_the_colour_of_the_current_sauce() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var hud: HudScript = _hud(gs)
	check_eq(hud.sauce_type_color().to_html(), gs.current_sauce_type().color.to_html(), "the sauce's colour")
	gs.free()


func test_the_hud_shows_container_slots_with_an_icon_per_item() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var hud: HudScript = _hud(gs)
	check_eq(hud.slot_count(), 0, "no container, no slots")
	gs.try_equip_container("starter_container")
	hud.refresh()
	check_eq(hud.slot_count(), 3, "three empty slots")
	for i: int in 3:
		check_eq(hud.slot_icon_id(i), "", "slot %d is empty" % i)
	gs.take_damage(6)
	gs.try_pickup_item("ggul")
	gs.try_pickup_item("kongomul")
	hud.refresh()
	check_eq(hud.slot_icon_id(0), "ggul", "slot 0 holds 꿀")
	check_eq(hud.slot_icon_id(1), "kongomul", "slot 1 holds 콩고물")
	check_eq(hud.slot_icon_id(2), "", "slot 2 is still empty")
	gs.use_item_at(0)
	hud.refresh()
	check_eq(hud.slot_icon_id(0), "kongomul", "used items leave the row")
	check_eq(hud.slot_icon_id(1), "", "the freed slot is empty")
	gs.free()


func test_an_unknown_item_gets_the_generic_icon() -> void:
	check_eq(HudIconCatalogScript.item_icon("../../etc/passwd").id, "item_generic", "never a file path")
	check_eq(HudIconCatalogScript.item_icon("ggul").id, "ggul", "a known item has its own")


func test_every_icon_is_data_with_a_recorded_provenance() -> void:
	for id: String in HudIconCatalogScript.ICON_PATHS:
		var icon: HudIconScript = HudIconCatalogScript.icon(id)
		check(icon != null, "icon resource loads: " + id)
		if icon == null:
			continue
		check_eq(icon.id, id, "id matches the catalog (" + id + ")")
		check_eq(icon.provenance, "agent-drawn placeholder", "provenance of " + id)
		check(icon.texture == null, "no third-party art in " + id)
	for id: String in ["heart", "sauce_drop", "salt_crystal", "coat"]:
		check(HudIconCatalogScript.icon(id) != null, "needs an icon: " + id)
	check(HudIconCatalogScript.icon("not_an_icon") == null, "unknown id gives null")
	var dir: DirAccess = DirAccess.open("res://data/hud/icons")
	var files: int = 0
	for file: String in dir.get_files():
		if file.ends_with(".tres"):
			files += 1
	check_eq(files, HudIconCatalogScript.ICON_PATHS.size(), "one resource per icon, none unlisted")


func test_the_hud_stays_clear_of_the_subtitle_box_and_the_wiggle_meter() -> void:
	var gs: GameStateScript = GameStateScript.new()
	var hud: HudScript = _hud(gs)
	gs.try_equip_container("starter_container")
	gs.add_sodium(7)
	gs.try_pickup_item("ggul")
	hud.refresh()
	await tree.process_frame
	await tree.process_frame
	var column: Control = hud.get_child(0) as Control
	var area: Rect2 = Rect2(column.position, column.get_combined_minimum_size())
	var subtitle: Rect2 = Rect2(960.0 - 750.0, 1080.0 - 140.0 - 60.0, 1500.0, 140.0)
	var meter: Rect2 = Rect2(1230.0, 330.0, 600.0, 110.0)
	check(not area.intersects(subtitle), "clear of the subtitle box")
	check(not area.intersects(meter), "clear of the wiggle meter")
	check(area.end.x < 960.0 and area.end.y < 200.0, "a compact corner block (%s)" % str(area))
	gs.free()
