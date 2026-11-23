extends CanvasLayer
## The icon HUD, top-left: hearts, sauce, 나트륨 (each an icon and a number), then the coat (only
## while it is on), the current sauce's colour, and the container's slots with an icon per held
## item. Nothing here is an instruction. Icons are HudIcon data (data/hud/icons/), looked up by id.
##
## Laid out for 1920x1080. It sits in the top-left corner, clear of the subtitle box (bottom
## centre) and the wiggle meter (right), under the inventory, the popup and the pause menu.

const GameStateScript := preload("res://systems/game_state.gd")
const HudIconScript := preload("res://ui/hud_icon.gd")
const HudIconViewScript := preload("res://ui/hud_icon_view.gd")
const HudIconCatalogScript := preload("res://ui/hud_icon_catalog.gd")

const MARGIN: Vector2 = Vector2(28.0, 22.0)
const ICON_SIZE: float = 48.0
const FONT_SIZE: int = 38
const COLUMN_GAP: int = 30
## The save icon (top right, icon only, no text) stays this long after a save, then fades out. 🟡
const SAVE_FLASH_S: float = 1.8
const SAVE_FADE_S: float = 0.5
const SAVE_ICON_SIZE: float = 54.0

## Injected by tests; else the GameState autoload.
var game_state: GameStateScript
## Injected by tests; else the SaveSystem autoload.
var save_system: Node

var _hearts_label: Label
var _sauce_label: Label
var _sodium_label: Label
var _coat_icon: HudIconViewScript
var _sauce_type_icon: HudIconViewScript
var _slots_row: HBoxContainer
var _slot_frames: Array[PanelContainer] = []
var _slot_icons: Array[HudIconViewScript] = []
var _last_signature: String = ""
var _save_icon: HudIconViewScript
var _save_left: float = 0.0


func _ready() -> void:
	layer = 10
	if game_state == null:
		game_state = get_node_or_null("/root/GameState") as GameStateScript
	var column: VBoxContainer = VBoxContainer.new()
	column.position = MARGIN
	column.add_theme_constant_override("separation", 12)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)

	var stats: HBoxContainer = HBoxContainer.new()
	stats.add_theme_constant_override("separation", COLUMN_GAP)
	stats.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(stats)
	_hearts_label = _stat(stats, "heart")
	_sauce_label = _stat(stats, "sauce_drop")
	_sodium_label = _stat(stats, "salt_crystal")

	var extras: HBoxContainer = HBoxContainer.new()
	extras.add_theme_constant_override("separation", 16)
	extras.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(extras)
	_coat_icon = HudIconViewScript.new(ICON_SIZE * 0.85)
	_coat_icon.icon = HudIconCatalogScript.icon("coat")
	extras.add_child(_coat_icon)
	_sauce_type_icon = HudIconViewScript.new(ICON_SIZE * 0.7)
	_sauce_type_icon.icon = HudIconCatalogScript.icon("sauce_type")
	extras.add_child(_sauce_type_icon)
	_save_icon = HudIconViewScript.new(SAVE_ICON_SIZE)
	_save_icon.icon = HudIconCatalogScript.icon("save_disk")
	_save_icon.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_save_icon.offset_left = -MARGIN.x - SAVE_ICON_SIZE
	_save_icon.offset_right = -MARGIN.x
	_save_icon.offset_top = MARGIN.y
	_save_icon.offset_bottom = MARGIN.y + SAVE_ICON_SIZE
	_save_icon.visible = false
	add_child(_save_icon)
	if save_system == null:
		save_system = get_node_or_null("/root/SaveSystem")
	if save_system != null and save_system.has_signal("saved"):
		save_system.connect("saved", flash_save_icon)
	_slots_row = HBoxContainer.new()
	_slots_row.add_theme_constant_override("separation", 8)
	_slots_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	extras.add_child(_slots_row)
	refresh()


func _process(delta: float) -> void:
	refresh()
	_step_save_icon(delta)


## The small save icon flashes (a save was written). Icon only: no text.
func flash_save_icon() -> void:
	_save_left = SAVE_FLASH_S
	if _save_icon != null:
		_save_icon.visible = true
		_save_icon.modulate.a = 1.0


func save_icon_visible() -> bool:
	return _save_icon != null and _save_icon.visible


func _step_save_icon(delta: float) -> void:
	if _save_icon == null or _save_left <= 0.0:
		return
	_save_left = maxf(_save_left - delta, 0.0)
	_save_icon.modulate.a = clampf(_save_left / SAVE_FADE_S, 0.0, 1.0)
	if _save_left == 0.0:
		_save_icon.visible = false


## One "icon  number" pair; returns the number's label.
func _stat(parent: Control, icon_id: String) -> Label:
	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(box)
	var view: HudIconViewScript = HudIconViewScript.new(ICON_SIZE)
	view.icon = HudIconCatalogScript.icon(icon_id)
	box.add_child(view)
	var label: Label = Label.new()
	label.add_theme_font_size_override("font_size", FONT_SIZE)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(label)
	return label


# --- What it shows (also what the tests read) ---------------------------------------------------------

## 13 half-hearts -> "6.5", 14 -> "7".
static func format_hearts(half_hearts: int) -> String:
	var whole: int = half_hearts / 2
	return "%d.5" % whole if half_hearts % 2 == 1 else "%d" % whole


func hearts_text() -> String:
	return "%s/%s" % [format_hearts(game_state.hearts), format_hearts(game_state.MAX_HEARTS)]


func sauce_text() -> String:
	return "%d/%d" % [game_state.sauce, game_state.MAX_SAUCE]


func sodium_text() -> String:
	return "%d/%d" % [game_state.sodium, game_state.MAX_SODIUM]


func coat_visible() -> bool:
	return _coat_icon != null and _coat_icon.visible


## Colour of the sauce type in use.
func sauce_type_color() -> Color:
	return _sauce_type_icon.tint if _sauce_type_icon != null else Color(0, 0, 0, 0)


## One entry per slot of the container: the held item's id, or "" for an empty slot. Empty list
## with no container.
func slot_item_ids() -> Array[String]:
	var out: Array[String] = []
	if game_state == null or not game_state.has_container():
		return out
	for i: int in game_state.inventory_capacity:
		out.append(game_state.items[i] if i < game_state.items.size() else "")
	return out


## How many slot frames are on screen.
func slot_count() -> int:
	return _slot_frames.size()


## Id of the icon drawn in slot `i` ("" for an empty slot).
func slot_icon_id(i: int) -> String:
	if i < 0 or i >= _slot_icons.size() or _slot_icons[i].icon == null:
		return ""
	return _slot_icons[i].icon.id


# --- Updating ---------------------------------------------------------------------------------------

func refresh() -> void:
	if game_state == null or _hearts_label == null:
		return
	var slots: Array[String] = slot_item_ids()
	var sauce_color: Color = game_state.current_sauce_type().color
	var signature: String = "%s|%s|%s|%s|%s|%s" % [hearts_text(), sauce_text(), sodium_text(),
		game_state.coat, sauce_color.to_html(), ",".join(slots)]
	if signature == _last_signature:
		return
	_last_signature = signature
	_hearts_label.text = hearts_text()
	_sauce_label.text = sauce_text()
	_sodium_label.text = sodium_text()
	_coat_icon.visible = game_state.coat
	_sauce_type_icon.tint = sauce_color
	_rebuild_slots(slots)


func _rebuild_slots(slots: Array[String]) -> void:
	for frame: PanelContainer in _slot_frames:
		_slots_row.remove_child(frame)
		frame.queue_free()
	_slot_frames.clear()
	_slot_icons.clear()
	for id: String in slots:
		var frame: PanelContainer = PanelContainer.new()
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = Color(0, 0, 0, 0.45)
		style.border_color = Color(1, 1, 1, 0.8)
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(4)
		frame.add_theme_stylebox_override("panel", style)
		var view: HudIconViewScript = HudIconViewScript.new(ICON_SIZE * 0.8)
		view.icon = HudIconCatalogScript.item_icon(id) if id != "" else null
		frame.add_child(view)
		_slots_row.add_child(frame)
		_slot_frames.append(frame)
		_slot_icons.append(view)
