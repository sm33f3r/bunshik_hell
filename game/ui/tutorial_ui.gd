extends CanvasLayer
## The screen furniture of Map 1's tutorial, built in code: the "tutorial or skip" prompt, the small
## hint at the top, the "new skill" toast and the black fade used when the tutorial is skipped.
## Laid out for 1920x1080 (the project's base size). It runs while the game is paused, because the
## prompt pauses the tree (like the inventory and the popup). All text comes in from outside (data).

const FONT_SHADOW := Color(0, 0, 0, 1)

var _dim: ColorRect
var _prompt_box: PanelContainer
var _prompt_label: Label
var _hint_box: PanelContainer
var _hint_label: Label
var _toast_label: Label
var _fade: ColorRect
var _hint_left: float = 0.0
var _toast_left: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 22
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dim.visible = false
	add_child(_dim)

	_prompt_box = _make_box(Vector2(960.0 - 520.0, 540.0 - 130.0), Vector2(1040.0, 260.0), 0.82)
	_prompt_label = _make_label(_prompt_box, 56)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_hint_box = _make_box(Vector2(960.0 - 650.0, 36.0), Vector2(1300.0, 84.0), 0.62)
	_hint_label = _make_label(_hint_box, 40)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_toast_label = Label.new()
	_toast_label.position = Vector2(0.0, 170.0)
	_toast_label.size = Vector2(1920.0, 90.0)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_font_size_override("font_size", 58)
	_toast_label.add_theme_color_override("font_color", Color(1.0, 0.93, 0.35))
	_toast_label.add_theme_color_override("font_shadow_color", FONT_SHADOW)
	_toast_label.add_theme_constant_override("shadow_offset_x", 3)
	_toast_label.add_theme_constant_override("shadow_offset_y", 3)
	_toast_label.visible = false
	add_child(_toast_label)

	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.visible = false
	add_child(_fade)


func _make_box(at: Vector2, box_size: Vector2, alpha: float) -> PanelContainer:
	var box: PanelContainer = PanelContainer.new()
	box.position = at
	box.custom_minimum_size = box_size
	box.size = box_size
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, alpha)
	style.set_corner_radius_all(16)
	style.set_content_margin_all(18)
	box.add_theme_stylebox_override("panel", style)
	box.visible = false
	add_child(box)
	return box


func _make_label(parent: Control, font_size: int) -> Label:
	var label: Label = Label.new()
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", FONT_SHADOW)
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _process(delta: float) -> void:
	if _hint_left > 0.0:
		_hint_left -= delta
		if _hint_left <= 0.0:
			clear_hint()
	if _toast_left > 0.0:
		_toast_left -= delta
		if _toast_left <= 0.0 and _toast_label != null:
			_toast_label.visible = false


# --- The prompt ---------------------------------------------------------------------------------

func show_prompt(text: String) -> void:
	_prompt_label.text = text
	_prompt_box.visible = true
	_dim.visible = true


func hide_prompt() -> void:
	_prompt_box.visible = false
	_dim.visible = false


func prompt_visible() -> bool:
	return _prompt_box != null and _prompt_box.visible


func prompt_text() -> String:
	return _prompt_label.text if _prompt_label != null else ""


# --- The hint -----------------------------------------------------------------------------------

func show_hint(text: String, seconds: float) -> void:
	_hint_label.text = text
	_hint_box.visible = text != ""
	_hint_left = seconds


func clear_hint() -> void:
	_hint_left = 0.0
	if _hint_box != null:
		_hint_box.visible = false
		_hint_label.text = ""


func hint_visible() -> bool:
	return _hint_box != null and _hint_box.visible


func hint_text() -> String:
	return _hint_label.text if _hint_label != null else ""


# --- The toast ----------------------------------------------------------------------------------

func show_toast(text: String, seconds: float = 3.5) -> void:
	_toast_label.text = text
	_toast_label.visible = text != ""
	_toast_left = seconds


func toast_visible() -> bool:
	return _toast_label != null and _toast_label.visible


func toast_text() -> String:
	return _toast_label.text if _toast_label != null else ""


# --- The fade -----------------------------------------------------------------------------------

## 0 = clear, 1 = black.
func set_fade(alpha: float) -> void:
	var a: float = clampf(alpha, 0.0, 1.0)
	_fade.color = Color(0, 0, 0, a)
	_fade.visible = a > 0.0


func fade_alpha() -> float:
	return _fade.color.a if _fade != null and _fade.visible else 0.0
