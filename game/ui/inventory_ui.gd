extends CanvasLayer
## Gray-box inventory screen and the "container is full" popup. Runs while the game is
## paused (process_mode ALWAYS) and pauses the tree while either is open.
## Input is polled, not event-driven, so scripted tests can drive it with Input.action_press().
##   Confirm / cancel are the ui_accept / ui_cancel actions (project.godot): Enter or Space / ✕
##   (JOY_BUTTON_A, the south button) confirms; Esc / ○ (JOY_BUTTON_B, the east button) cancels.
##   Inventory screen: `inventory` opens/closes. W/S, arrows, d-pad, stick move; confirm uses the
##   selected item; `drop_item` (□) drops it; cancel closes.
##   Popup: left/right or up/down chooses; confirm applies the chosen option (use it now / drop it);
##   `drop_item` or cancel = drop it and close.
##   Whatever closes a menu, the closing press must not reach the game: see GameplayInputScript (systems/gameplay_input.gd).

const GameStateScript := preload("res://systems/game_state.gd")
const ItemCatalogScript := preload("res://systems/item_catalog.gd")
const GameplayInputScript := preload("res://systems/gameplay_input.gd")

## Input is ignored for this many frames after something opens, so the press that caused it
## (a jump into an item, the inventory key itself) cannot also answer it.
const OPEN_GUARD_FRAMES: int = 2

## Injected by tests; falls back to the GameState autoload in _ready().
var game_state: GameStateScript
var screen_open: bool = false
var selected: int = 0
## 0 = "use it now", 1 = "drop it".
var popup_choice: int = 1
var message: String = ""

var _guard: int = 0
var _dim: ColorRect
var _screen_label: Label
var _popup_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 20
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.6)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.visible = false
	add_child(_dim)
	_screen_label = _make_label(Vector2(560, 240))
	_popup_label = _make_label(Vector2(380, 380))
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript
	if game_state != null:
		game_state.popup_opened.connect(_on_popup_opened)
		game_state.popup_closed.connect(_on_popup_closed)
		game_state.inventory_changed.connect(_refresh)
	_refresh()


func _make_label(at: Vector2) -> Label:
	var label: Label = Label.new()
	label.position = at
	label.visible = false
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(label)
	return label


func _process(_delta: float) -> void:
	if game_state == null:
		return
	if _guard > 0:
		_guard -= 1
		return
	if game_state.popup_open():
		_process_popup()
	elif screen_open:
		_process_screen()
	elif Input.is_action_just_pressed("inventory") and not game_state.is_dead() and not _tree_paused():
		open_screen()


# --- Inventory screen -------------------------------------------------------------------

func open_screen() -> void:
	screen_open = true
	selected = 0
	message = ""
	_guard = OPEN_GUARD_FRAMES
	_set_paused(true)
	_refresh()


func close_screen() -> void:
	screen_open = false
	_guard = OPEN_GUARD_FRAMES
	GameplayInputScript.swallow()
	_set_paused(false)
	_refresh()


func _process_screen() -> void:
	if Input.is_action_just_pressed("inventory") or Input.is_action_just_pressed("ui_cancel"):
		close_screen()
		return
	if not game_state.has_container():
		return
	var slots: int = maxi(game_state.inventory_capacity, 1)
	if _pressed_up():
		selected = posmod(selected - 1, slots)
		message = ""
		_refresh()
	elif _pressed_down():
		selected = posmod(selected + 1, slots)
		message = ""
		_refresh()
	elif Input.is_action_just_pressed("ui_accept"):
		use_selected()
	elif Input.is_action_just_pressed("drop_item"):
		drop_selected()


func use_selected() -> bool:
	if selected >= game_state.items.size():
		return false
	if not game_state.use_item_at(selected):
		message = tr("That would do nothing right now.")
		_refresh()
		return false
	message = ""
	selected = mini(selected, maxi(game_state.items.size() - 1, 0))
	_refresh()
	return true


func drop_selected() -> bool:
	if selected >= game_state.items.size():
		return false
	game_state.drop_item_at(selected)
	message = ""
	selected = mini(selected, maxi(game_state.inventory_capacity - 1, 0))
	_refresh()
	return true


# --- Popup ------------------------------------------------------------------------------

func _on_popup_opened(item_id: String) -> void:
	_guard = OPEN_GUARD_FRAMES
	popup_choice = 1 if game_state.would_do_nothing(item_id) else 0
	_set_paused(true)
	_refresh()


func _on_popup_closed() -> void:
	_guard = OPEN_GUARD_FRAMES
	GameplayInputScript.swallow()
	_set_paused(false)
	_refresh()


func _process_popup() -> void:
	if Input.is_action_just_pressed("drop_item") or Input.is_action_just_pressed("ui_cancel") \
			or Input.is_action_just_pressed("inventory"):
		game_state.resolve_popup(false) # closing the popup = drop it
		return
	if _pressed_up() or _pressed_down() or Input.is_action_just_pressed("ui_left") \
			or Input.is_action_just_pressed("ui_right") or Input.is_action_just_pressed("move_left") \
			or Input.is_action_just_pressed("move_right"):
		popup_choice = 1 - popup_choice
		_refresh()
	elif Input.is_action_just_pressed("ui_accept"):
		confirm_popup()


## Applies the highlighted choice. "Use it now" is refused while greyed out.
func confirm_popup() -> void:
	if popup_choice == 0:
		game_state.resolve_popup(true)
	else:
		game_state.resolve_popup(false)


# --- Shared -----------------------------------------------------------------------------

func _pressed_up() -> bool:
	return Input.is_action_just_pressed("look_up") or Input.is_action_just_pressed("ui_up")


func _pressed_down() -> bool:
	return Input.is_action_just_pressed("look_down") or Input.is_action_just_pressed("ui_down")


## Another menu (the pause menu) already owns the game: do not open on top of it.
func _tree_paused() -> bool:
	return is_inside_tree() and get_tree().paused


func _set_paused(on: bool) -> void:
	if is_inside_tree():
		get_tree().paused = on


func _item_line(id: String) -> String:
	var def: Variant = ItemCatalogScript.health_item(id)
	if def == null:
		return "?"
	var line: String = "%s  (%s)" % [def.display_name,
		tr("heals %s heart(s)") % GameStateScript.format_hearts(def.heal_half_hearts)]
	if def.grants_coat:
		line += " + " + tr("coat")
	return line


func screen_text() -> String:
	if not game_state.has_container():
		return tr("INVENTORY") + "\n\n" + tr("You have no container to carry things in.") \
			+ "\n\n" + tr("Inventory: close")
	var lines: Array[String] = [
		"%s - %s (%d/%d)" % [tr("INVENTORY"), game_state.container_name(),
			game_state.items.size(), game_state.inventory_capacity],
		"",
	]
	for i: int in game_state.inventory_capacity:
		var text: String = _item_line(game_state.items[i]) if i < game_state.items.size() else tr("(empty)")
		lines.append("%s %d. %s" % [">" if i == selected else " ", i + 1, text])
	lines.append("")
	lines.append(tr("Confirm: use    Drop: drop    Inventory / Esc: close"))
	if message != "":
		lines.append(message)
	return "\n".join(lines)


func popup_text() -> String:
	var id: String = game_state.popup_item_id
	var use_label: String = tr("use it now")
	var drop_label: String = tr("drop it")
	var grey: bool = game_state.would_do_nothing(id)
	var question: String = tr("Your {container} is full. Do you want to {use} or {drop}?").format({
		"container": game_state.container_name(), "use": use_label, "drop": drop_label})
	var use_line: String = "%s %s%s" % ["[>]" if popup_choice == 0 else "[ ]", use_label,
		"  (" + tr("nothing to heal") + ")" if grey else ""]
	var drop_line: String = "%s %s" % ["[>]" if popup_choice == 1 else "[ ]", drop_label]
	return "%s\n(%s)\n\n%s\n%s" % [question, _item_line(id), use_line, drop_line]


func _refresh() -> void:
	if _screen_label == null or game_state == null:
		return
	var popup: bool = game_state.popup_open()
	_dim.visible = screen_open or popup
	_screen_label.visible = screen_open and not popup
	_popup_label.visible = popup
	if _screen_label.visible:
		_screen_label.text = screen_text()
	if popup:
		_popup_label.text = popup_text()
