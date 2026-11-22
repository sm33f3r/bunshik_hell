extends CanvasLayer
## The pause menu: Resume, Restart, Settings, Quit. Opens with Esc (the `pause` action) or the
## controller's Options button (JOY_BUTTON_START, which is what the DualSense Options button
## reports). Runs while the game is paused (process_mode ALWAYS) and pauses the whole tree while it
## is open, so the cutscene, the wiggle and every stab freeze and then carry on where they were.
##
## Input is polled, like the inventory, so scripted tests can drive it with Input.action_press():
##   up / down: W, S, the arrows, the d-pad, the stick.  left / right: A, D, the arrows (settings).
##   confirm: Enter, Space, ✕ (ui_accept).  back: Esc, Options, ○ (ui_cancel).
## The inventory and the "container is full" popup own the game while they are open: Esc then
## closes THEM and never opens this menu. Whatever closes a menu must not reach the game (see
## GameplayInput), so closing swallows the press.
##
## "Restart" emits restart_requested after closing: the map decides what the last checkpoint is
## (in the prologue, the 맛있겠다 moment). "Quit" asks yes/no first, then calls quit_action.

signal restart_requested
signal opened
signal closed

enum Screen { NONE, MAIN, SETTINGS, CONFIRM_QUIT }

const GameStateScript := preload("res://systems/game_state.gd")
const SettingsScript := preload("res://systems/settings.gd")
const ItemCatalogScript := preload("res://systems/item_catalog.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")

## Input is ignored for this many frames after something opens or changes screen.
const GUARD_FRAMES: int = 2
const VOLUME_STEP: float = 0.1
const MAIN_ITEMS: int = 4
const SETTINGS_ITEMS: int = 4
const ITEM_RESUME: int = 0
const ITEM_RESTART: int = 1
const ITEM_SETTINGS: int = 2
const ITEM_QUIT: int = 3
const SETTING_FULLSCREEN: int = 0
const SETTING_VOLUME: int = 1
const SETTING_HEAL: int = 2
const SETTING_BACK: int = 3

## Injected by tests; fall back to the autoloads in _ready().
var game_state: GameStateScript
var settings: SettingsScript
## Called when the player confirms "Quit". Tests swap it for a spy.
var quit_action: Callable
var screen: Screen = Screen.NONE
var selected: int = 0
## How many times quit_action has been called.
var quit_count: int = 0

var _guard: int = 0
var _dim: ColorRect
var _label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.7)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	add_child(_dim)
	_label = Label.new()
	_label.position = Vector2(620.0, 260.0)
	_label.visible = false
	_label.add_theme_font_size_override("font_size", 44)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	_label.add_theme_constant_override("shadow_offset_x", 2)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(_label)
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript
	if settings == null:
		settings = get_node_or_null("/root/Settings") as SettingsScript
	if not quit_action.is_valid():
		quit_action = Callable(self, "_quit_game")
	_refresh()


func is_open() -> bool:
	return screen != Screen.NONE


func _process(_delta: float) -> void:
	if _guard > 0:
		_guard -= 1
		return
	if screen == Screen.NONE:
		if Input.is_action_just_pressed("pause") and _can_open():
			open()
		return
	match screen:
		Screen.MAIN:
			_process_main()
		Screen.SETTINGS:
			_process_settings()
		Screen.CONFIRM_QUIT:
			_process_confirm()


## Not while something else owns the game: the inventory and the popup pause the tree, and a press
## that has just closed one of them is blocked (that Esc closed the inventory, nothing more).
func _can_open() -> bool:
	if GameplayInputScript.is_blocked():
		return false
	if is_inside_tree() and get_tree().paused:
		return false
	if game_state != null and (game_state.popup_open() or game_state.is_dead()):
		return false
	return true


func open() -> void:
	if screen != Screen.NONE:
		return
	_go(Screen.MAIN)
	_set_paused(true)
	opened.emit()


func close() -> void:
	if screen == Screen.NONE:
		return
	screen = Screen.NONE
	_guard = GUARD_FRAMES
	GameplayInputScript.swallow()
	_set_paused(false)
	_refresh()
	closed.emit()


func _go(new_screen: Screen, new_selected: int = 0) -> void:
	screen = new_screen
	selected = new_selected
	_guard = GUARD_FRAMES
	_refresh()


# --- Main screen -------------------------------------------------------------------------------

func _process_main() -> void:
	if _back_pressed():
		close()
	elif _up_pressed():
		selected = posmod(selected - 1, MAIN_ITEMS)
		_refresh()
	elif _down_pressed():
		selected = posmod(selected + 1, MAIN_ITEMS)
		_refresh()
	elif Input.is_action_just_pressed("ui_accept"):
		choose_main(selected)


func choose_main(item: int) -> void:
	match item:
		ITEM_RESUME:
			close()
		ITEM_RESTART:
			close()
			restart_requested.emit()
		ITEM_SETTINGS:
			_go(Screen.SETTINGS)
		ITEM_QUIT:
			_go(Screen.CONFIRM_QUIT, 1) # "No" is highlighted first


# --- Settings screen ----------------------------------------------------------------------------

func _process_settings() -> void:
	if _back_pressed():
		_go(Screen.MAIN, ITEM_SETTINGS)
	elif _up_pressed():
		selected = posmod(selected - 1, SETTINGS_ITEMS)
		_refresh()
	elif _down_pressed():
		selected = posmod(selected + 1, SETTINGS_ITEMS)
		_refresh()
	elif _left_pressed():
		change_setting(selected, -1)
	elif _right_pressed():
		change_setting(selected, 1)
	elif Input.is_action_just_pressed("ui_accept"):
		if selected == SETTING_BACK:
			_go(Screen.MAIN, ITEM_SETTINGS)
		else:
			change_setting(selected, 1)


## Changes one setting by a step (-1 / +1), applies it, and saves it.
func change_setting(item: int, step: int) -> void:
	if settings == null:
		return
	match item:
		SETTING_FULLSCREEN:
			settings.set_fullscreen(not settings.fullscreen)
		SETTING_VOLUME:
			settings.set_master_volume(snappedf(settings.master_volume + VOLUME_STEP * float(step), 0.01))
		SETTING_HEAL:
			settings.cycle_heal_default(step)
		_:
			return
	settings.apply_to_system()
	settings.save_settings()
	_refresh()


# --- Quit confirmation -----------------------------------------------------------------------------

func _process_confirm() -> void:
	if _back_pressed():
		_go(Screen.MAIN, ITEM_QUIT)
	elif _up_pressed() or _down_pressed() or _left_pressed() or _right_pressed():
		selected = 1 - selected
		_refresh()
	elif Input.is_action_just_pressed("ui_accept"):
		if selected == 0:
			confirm_quit()
		else:
			_go(Screen.MAIN, ITEM_QUIT)


func confirm_quit() -> void:
	quit_count += 1
	if quit_action.is_valid():
		quit_action.call()


func _quit_game() -> void:
	get_tree().quit()


# --- Shared --------------------------------------------------------------------------------------------

func _back_pressed() -> bool:
	return Input.is_action_just_pressed("ui_cancel") or Input.is_action_just_pressed("pause")


func _up_pressed() -> bool:
	return Input.is_action_just_pressed("look_up") or Input.is_action_just_pressed("ui_up")


func _down_pressed() -> bool:
	return Input.is_action_just_pressed("look_down") or Input.is_action_just_pressed("ui_down")


func _left_pressed() -> bool:
	return Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left")


func _right_pressed() -> bool:
	return Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right")


func _set_paused(on: bool) -> void:
	if is_inside_tree():
		get_tree().paused = on


func _heal_label(id: String) -> String:
	if id == "lowest":
		return tr("lowest")
	var def: Variant = ItemCatalogScript.health_item(id)
	return def.display_name if def != null else id


func screen_text() -> String:
	var lines: Array[String] = []
	match screen:
		Screen.MAIN:
			lines.append(tr("PAUSED"))
			lines.append("")
			var names: Array[String] = [tr("Resume"), tr("Restart"), tr("Settings"), tr("Quit")]
			for i: int in names.size():
				lines.append("%s %s" % [">" if i == selected else " ", names[i]])
			lines.append("")
			lines.append(tr("Confirm: choose    Back: resume"))
		Screen.SETTINGS:
			lines.append(tr("SETTINGS"))
			lines.append("")
			var on_off: String = tr("on") if settings != null and settings.fullscreen else tr("off")
			var percent: int = int(roundf((settings.master_volume if settings != null else 1.0) * 100.0))
			var heal: String = _heal_label(settings.heal_default) if settings != null else ""
			var rows: Array[String] = [
				"%s: %s" % [tr("Fullscreen"), on_off],
				"%s: %d%%" % [tr("Master volume"), percent],
				"%s: %s" % [tr("Heal default"), heal],
				tr("Back"),
			]
			for i: int in rows.size():
				lines.append("%s %s" % [">" if i == selected else " ", rows[i]])
			lines.append("")
			lines.append(tr("Left / right: change    Back: return"))
		Screen.CONFIRM_QUIT:
			lines.append(tr("Quit to the desktop?"))
			lines.append("")
			lines.append("%s %s" % [">" if selected == 0 else " ", tr("Yes")])
			lines.append("%s %s" % [">" if selected == 1 else " ", tr("No")])
	return "\n".join(lines)


func _refresh() -> void:
	if _label == null:
		return
	_dim.visible = screen != Screen.NONE
	_label.visible = screen != Screen.NONE
	if screen != Screen.NONE:
		_label.text = screen_text()
