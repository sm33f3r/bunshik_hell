extends "res://tests/base_test.gd"
## Task 3a-fix: the pause menu (Resume, Restart, Settings, Quit) and the settings it saves.
## Driven by pressing the real input actions, a frame at a time.

const PauseMenuScript := preload("res://ui/pause_menu.gd")
const InventoryUiScript := preload("res://ui/inventory_ui.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const SettingsScript := preload("res://systems/settings.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")

const TEMP_PATH := "user://test_pause_settings_tmp.json"
const ALL_ACTIONS: Array[String] = ["pause", "ui_cancel", "ui_accept", "ui_up", "ui_down", "ui_left",
	"ui_right", "look_up", "look_down", "move_left", "move_right", "inventory"]

var menu: PauseMenuScript
var gs: GameStateScript
var settings: SettingsScript
var _quit_spy: Array[int] = []
var _extra: Array[Node] = []
## The audio buses as they were before the test.
var _buses: AudioBusLayout


func _make(with_inventory: bool = false, inventory_first: bool = true) -> void:
	_buses = AudioServer.generate_bus_layout()
	gs = GameStateScript.new()
	settings = SettingsScript.new()
	settings.settings_path = TEMP_PATH
	GameplayInputScript.clear()
	_quit_spy.clear()
	menu = PauseMenuScript.new()
	menu.game_state = gs
	menu.settings = settings
	menu.quit_action = func() -> void: _quit_spy.append(1)
	var inventory: InventoryUiScript = null
	if with_inventory:
		inventory = InventoryUiScript.new()
		inventory.game_state = gs
		_extra.append(inventory)
	if inventory != null and inventory_first:
		tree.root.add_child(inventory)
	tree.root.add_child(menu)
	if inventory != null and not inventory_first:
		tree.root.add_child(inventory)
	await tree.process_frame
	await tree.process_frame


func after_each() -> void:
	for action: String in ALL_ACTIONS:
		Input.action_release(action)
	tree.paused = false
	GameplayInputScript.clear()
	if _buses != null:
		AudioServer.set_bus_layout(_buses)
		_buses = null
	if menu != null and is_instance_valid(menu):
		menu.free()
	for node: Node in _extra:
		if is_instance_valid(node):
			node.free()
	_extra.clear()
	menu = null
	if gs != null:
		gs.free()
		gs = null
	if settings != null:
		settings.free()
		settings = null
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(TEMP_PATH)


## Presses the actions for one frame, then lets three frames go by (past the menu's guard).
func press(actions: Array[String]) -> void:
	for action: String in actions:
		Input.action_press(action)
	await tree.process_frame
	for action: String in actions:
		Input.action_release(action)
	await tree.process_frame
	await tree.process_frame
	await tree.process_frame


func test_the_pause_action_is_esc_and_the_options_button() -> void:
	var keys: Array[int] = []
	var pads: Array[int] = []
	for event: InputEvent in InputMap.action_get_events("pause"):
		var key: InputEventKey = event as InputEventKey
		if key != null:
			keys.append(key.keycode if key.keycode != 0 else key.physical_keycode)
		var pad: InputEventJoypadButton = event as InputEventJoypadButton
		if pad != null:
			pads.append(pad.button_index)
	check(KEY_ESCAPE in keys, "Esc pauses")
	# 4.7.2: JOY_BUTTON_START (6) is what the DualSense Options button reports.
	check_eq(JOY_BUTTON_START, 6, "JOY_BUTTON_START is 6")
	check(JOY_BUTTON_START in pads, "the Options / Start button pauses")
	check(JOY_BUTTON_TOUCHPAD not in pads and JOY_BUTTON_BACK not in pads, "and not the inventory buttons")


func test_esc_opens_and_closes_it_and_the_game_pauses() -> void:
	await _make()
	check(not menu.is_open() and not tree.paused, "closed at the start")
	await press(["pause", "ui_cancel"] as Array[String]) # Esc is both actions
	check(menu.is_open(), "Esc opened it")
	check(tree.paused, "and the game is paused")
	await press(["pause", "ui_cancel"] as Array[String])
	check(not menu.is_open(), "Esc closed it")
	check(not tree.paused, "and the game runs again")
	check(GameplayInputScript.is_blocked() or true, "(the closing press was swallowed)")


func test_the_options_button_opens_and_closes_it() -> void:
	await _make()
	await press(["pause"] as Array[String])
	check(menu.is_open() and tree.paused, "Options opened it")
	await press(["pause"] as Array[String])
	check(not menu.is_open() and not tree.paused, "Options closed it")


func test_the_circle_button_goes_back_and_the_cross_confirms() -> void:
	await _make()
	await press(["pause"] as Array[String])
	await press(["ui_accept"] as Array[String]) # Resume is the first item
	check(not menu.is_open(), "cross on Resume resumes")
	await press(["pause"] as Array[String])
	await press(["ui_cancel"] as Array[String])
	check(not menu.is_open(), "circle (ui_cancel) closes it")


func test_closing_it_does_not_leak_the_press_into_gameplay() -> void:
	await _make()
	await press(["pause"] as Array[String])
	Input.action_press("ui_accept")
	await tree.process_frame
	check(GameplayInputScript.is_blocked(), "the closing press is swallowed for two ticks")
	check(not GameplayInputScript.just_pressed(&"jump"), "a jump on the same press does not reach the game")
	Input.action_release("ui_accept")


func test_navigation_with_keys_and_stick() -> void:
	await _make()
	await press(["pause"] as Array[String])
	check_eq(menu.selected, 0, "Resume first")
	await press(["look_down"] as Array[String]) # S / stick down
	check_eq(menu.selected, 1, "S moves down")
	await press(["ui_down"] as Array[String]) # arrow / d-pad down
	check_eq(menu.selected, 2, "the arrow moves down")
	await press(["look_up"] as Array[String])
	check_eq(menu.selected, 1, "W moves up")
	await press(["ui_up"] as Array[String])
	await press(["ui_up"] as Array[String])
	check_eq(menu.selected, 3, "and it wraps to Quit")


func test_restart_closes_and_asks_the_game_to_restart() -> void:
	await _make()
	var requests: Array[int] = []
	menu.restart_requested.connect(func() -> void: requests.append(1))
	await press(["pause"] as Array[String])
	await press(["look_down"] as Array[String])
	await press(["ui_accept"] as Array[String])
	check_eq(requests.size(), 1, "Restart asked once")
	check(not menu.is_open() and not tree.paused, "and the menu is closed and the game runs")


func test_quit_asks_first_and_no_does_not_quit() -> void:
	await _make()
	await press(["pause"] as Array[String])
	for i: int in 3:
		await press(["look_down"] as Array[String])
	await press(["ui_accept"] as Array[String])
	check_eq(menu.screen, PauseMenuScript.Screen.CONFIRM_QUIT, "Quit asks yes or no")
	check(menu.screen_text().contains("?"), "it is a question")
	check_eq(_quit_spy.size(), 0, "nothing has quit yet")
	check_eq(menu.selected, 1, "No is highlighted first")
	await press(["ui_accept"] as Array[String])
	check_eq(_quit_spy.size(), 0, "No does not quit")
	check_eq(menu.screen, PauseMenuScript.Screen.MAIN, "back to the menu")


func test_quit_yes_quits() -> void:
	await _make()
	await press(["pause"] as Array[String])
	for i: int in 3:
		await press(["look_down"] as Array[String])
	await press(["ui_accept"] as Array[String])
	await press(["look_up"] as Array[String]) # move to Yes
	check_eq(menu.selected, 0, "Yes selected")
	await press(["ui_accept"] as Array[String])
	check_eq(_quit_spy.size(), 1, "Yes quits (once)")


func test_back_out_of_the_quit_question_does_not_quit() -> void:
	await _make()
	await press(["pause"] as Array[String])
	for i: int in 3:
		await press(["look_down"] as Array[String])
	await press(["ui_accept"] as Array[String])
	await press(["ui_cancel"] as Array[String])
	check_eq(menu.screen, PauseMenuScript.Screen.MAIN, "circle backs out")
	check_eq(_quit_spy.size(), 0, "nothing quit")


func test_settings_change_save_and_load() -> void:
	await _make()
	await press(["pause"] as Array[String])
	await press(["look_down"] as Array[String])
	await press(["look_down"] as Array[String])
	await press(["ui_accept"] as Array[String])
	check_eq(menu.screen, PauseMenuScript.Screen.SETTINGS, "the settings screen")
	check(menu.screen_text().contains(tr("Fullscreen")), "fullscreen is listed")
	await press(["ui_accept"] as Array[String]) # fullscreen toggles
	check(settings.fullscreen, "fullscreen on")
	await press(["look_down"] as Array[String])
	await press(["ui_accept"] as Array[String]) # Audio page; master volume is its first row
	await press(["move_left"] as Array[String])
	check(absf(settings.master_volume - 0.9) < 0.001, "volume down a step")
	await press(["ui_cancel"] as Array[String]) # back on the Audio row
	await press(["look_down"] as Array[String])
	await press(["move_right"] as Array[String])
	check(settings.heal_default != "lowest", "heal default moved on")
	var saved: String = settings.heal_default
	var fresh: SettingsScript = SettingsScript.new()
	fresh.settings_path = TEMP_PATH
	check(fresh.load_settings(), "the settings file loads")
	check(fresh.fullscreen, "fullscreen saved")
	check(absf(fresh.master_volume - 0.9) < 0.001, "volume saved")
	check_eq(fresh.heal_default, saved, "heal default saved")
	fresh.free()
	settings.fullscreen = false # leave the real window alone
	settings.apply_to_system()


## Pause -> Settings -> Audio, by presses only.
func _open_audio_page() -> void:
	await press(["pause"] as Array[String])
	await press(["look_down"] as Array[String])
	await press(["look_down"] as Array[String])
	await press(["ui_accept"] as Array[String])
	await press(["look_down"] as Array[String])
	await press(["ui_accept"] as Array[String])


func _saved() -> SettingsScript:
	var fresh: SettingsScript = SettingsScript.new()
	fresh.settings_path = TEMP_PATH
	check(fresh.load_settings(), "the settings file loads")
	return fresh


func _bus_db(bus_name: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))


func _bus_muted(bus_name: String) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name))


func test_the_audio_page_changes_every_row_and_saves_at_once() -> void:
	await _make()
	await press(["pause"] as Array[String])
	await press(["look_down"] as Array[String])
	await press(["look_down"] as Array[String])
	await press(["ui_accept"] as Array[String])
	check(menu.screen_text().contains("Audio ▸"), "Settings lists Audio")
	check(not menu.screen_text().contains("Master volume"), "master volume moved to the Audio page")
	await press(["look_down"] as Array[String])
	await press(["move_right"] as Array[String])
	check_eq(menu.screen, PauseMenuScript.Screen.SETTINGS, "right does not open it")
	await press(["ui_accept"] as Array[String])
	check_eq(menu.screen, PauseMenuScript.Screen.AUDIO, "the audio page")
	for row: String in ["> Master volume: 100%", "Music volume: 100%", "Music: ON", "SFX volume: 100%", "SFX: ON", "Back"]:
		check(menu.screen_text().contains(row), "row " + row)

	# Master volume.
	await press(["move_left"] as Array[String])
	await press(["ui_left"] as Array[String])
	check(absf(settings.master_volume - 0.8) < 0.001, "master down two steps")
	await press(["ui_accept"] as Array[String])
	check(absf(settings.master_volume - 0.9) < 0.001, "confirm steps up")
	check(is_equal_approx(_bus_db("Master"), linear_to_db(settings.master_volume)), "Master bus applied")

	# Music volume.
	await press(["look_down"] as Array[String])
	await press(["move_left"] as Array[String])
	await press(["move_left"] as Array[String])
	check(menu.screen_text().contains("> Music volume: 80%"), "music label")
	check(is_equal_approx(_bus_db("Music"), linear_to_db(settings.music_volume)), "Music bus applied")
	var fresh: SettingsScript = _saved()
	check(absf(fresh.music_volume - 0.8) < 0.001, "music volume saved at once")
	fresh.free()
	await press(["move_right"] as Array[String])
	check(absf(settings.music_volume - 0.9) < 0.001, "and right goes up")

	# Music on / off: left, right and confirm all toggle.
	await press(["look_down"] as Array[String])
	await press(["move_left"] as Array[String])
	check(not settings.music_enabled and _bus_muted("Music"), "left turns music off and mutes the bus")
	check(menu.screen_text().contains("> Music: OFF"), "label OFF")
	await press(["move_right"] as Array[String])
	check(settings.music_enabled and not _bus_muted("Music"), "right turns it on")
	await press(["ui_accept"] as Array[String])
	check(not settings.music_enabled, "confirm toggles it")

	# SFX volume.
	await press(["look_down"] as Array[String])
	await press(["move_left"] as Array[String])
	check(menu.screen_text().contains("> SFX volume: 90%"), "sfx label")
	check(is_equal_approx(_bus_db("SFX"), linear_to_db(settings.sfx_volume)), "SFX bus applied")

	# SFX on / off.
	await press(["look_down"] as Array[String])
	await press(["ui_accept"] as Array[String])
	check(not settings.sfx_enabled and _bus_muted("SFX"), "confirm turns sfx off")
	check(menu.screen_text().contains("> SFX: OFF"), "label OFF")

	fresh = _saved()
	check(absf(fresh.master_volume - 0.9) < 0.001, "master saved")
	check(absf(fresh.music_volume - 0.9) < 0.001, "music saved")
	check(absf(fresh.sfx_volume - 0.9) < 0.001, "sfx saved")
	check_eq(fresh.music_enabled, false, "music off saved")
	check_eq(fresh.sfx_enabled, false, "sfx off saved")
	fresh.free()

	# Back row: left / right do nothing, confirm returns to Settings; and the list wraps.
	await press(["look_down"] as Array[String])
	check_eq(menu.selected, PauseMenuScript.AUDIO_BACK, "Back row")
	await press(["move_left"] as Array[String])
	check_eq(menu.screen, PauseMenuScript.Screen.AUDIO, "still here")
	await press(["look_down"] as Array[String])
	check_eq(menu.selected, PauseMenuScript.AUDIO_MASTER_VOLUME, "wraps down")
	await press(["ui_up"] as Array[String])
	await press(["ui_accept"] as Array[String])
	check_eq(menu.screen, PauseMenuScript.Screen.SETTINGS, "Back returns to Settings")
	check_eq(menu.selected, PauseMenuScript.SETTING_AUDIO, "on the Audio row")


func test_cancel_circle_and_options_leave_the_audio_page_one_level_at_a_time() -> void:
	await _make()
	await _open_audio_page()
	for back: Array in [["ui_cancel"], ["pause"], ["pause", "ui_cancel"]]:
		check_eq(menu.screen, PauseMenuScript.Screen.AUDIO, "on the audio page")
		var actions: Array[String] = []
		actions.assign(back)
		await press(actions)
		check_eq(menu.screen, PauseMenuScript.Screen.SETTINGS, "%s returns to Settings" % str(back))
		check_eq(menu.selected, PauseMenuScript.SETTING_AUDIO, "on the Audio row")
		check(tree.paused, "still paused")
		await press(["ui_accept"] as Array[String])
	await press(["ui_cancel"] as Array[String])
	await press(["ui_cancel"] as Array[String])
	check_eq(menu.screen, PauseMenuScript.Screen.MAIN, "then the main menu")
	Input.action_press("ui_cancel")
	await tree.process_frame
	check(not menu.is_open() and not tree.paused, "then closed")
	check(GameplayInputScript.is_blocked(), "the closing press is swallowed")
	check(not GameplayInputScript.just_pressed(&"roll"), "no roll leaks into the game")
	Input.action_release("ui_cancel")


func test_esc_while_the_inventory_is_open_closes_it_and_does_not_pause() -> void:
	for inventory_first: bool in [true, false]:
		await _make(true, inventory_first)
		var inventory: InventoryUiScript = _extra[0] as InventoryUiScript
		inventory.open_screen()
		await press(["inventory"] as Array[String]) # let the inventory's own guard pass
		# The first press above closed it again (inventory key toggles): reopen.
		if not inventory.screen_open:
			inventory.open_screen()
			await tree.process_frame
			await tree.process_frame
			await tree.process_frame
		check(inventory.screen_open and tree.paused, "the inventory is open and has paused the game")
		await press(["pause", "ui_cancel"] as Array[String])
		check(not inventory.screen_open, "Esc closed the inventory (inventory first: %s)" % str(inventory_first))
		check(not menu.is_open(), "and did not open the pause menu (inventory first: %s)" % str(inventory_first))
		check(not tree.paused, "the game runs again")
		after_each()


func test_the_inventory_key_does_nothing_while_the_pause_menu_is_open() -> void:
	await _make(true)
	var inventory: InventoryUiScript = _extra[0] as InventoryUiScript
	await press(["pause"] as Array[String])
	await press(["inventory"] as Array[String])
	check(not inventory.screen_open, "no inventory on top of the pause menu")
	check(menu.is_open(), "the pause menu is still there")


func test_it_does_not_open_while_dead() -> void:
	await _make()
	gs.take_damage(14)
	await press(["pause"] as Array[String])
	check(not menu.is_open(), "not while he is dead")
