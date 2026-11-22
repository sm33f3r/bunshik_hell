extends CanvasLayer
## The prologue's screen furniture, built in code: the subtitle box (bottom), the wiggle meter,
## the "eaten" blackout from the top with the game-over text, the skip hint and the dev-only
## "Map 1 continues here" note. Laid out for 1920x1080 (the project's base size).

const SUBTITLE_FONT_SIZE: int = 52
const BOX_SIZE: Vector2 = Vector2(1500.0, 140.0)

var _subtitle_box: PanelContainer
var _subtitle: Label
var _meter_root: Control
var _meter_alt_fill: ColorRect
var _meter_time_fill: ColorRect
var _meter_label: Label
var _blackout: ColorRect
var _game_over: Label
var _skip_hint: Label
var _dev_note: Label


func _ready() -> void:
	layer = 15
	_subtitle_box = PanelContainer.new()
	_subtitle_box.position = Vector2(960.0 - BOX_SIZE.x * 0.5, 1080.0 - BOX_SIZE.y - 60.0)
	_subtitle_box.custom_minimum_size = BOX_SIZE
	_subtitle_box.size = BOX_SIZE
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.0, 0.0, 0.0, 0.62)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(18)
	_subtitle_box.add_theme_stylebox_override("panel", style)
	_subtitle_box.visible = false
	add_child(_subtitle_box)
	_subtitle = Label.new()
	_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle.add_theme_font_size_override("font_size", SUBTITLE_FONT_SIZE)
	_subtitle.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	_subtitle.add_theme_constant_override("shadow_offset_x", 2)
	_subtitle.add_theme_constant_override("shadow_offset_y", 2)
	_subtitle_box.add_child(_subtitle)

	_meter_root = Control.new()
	_meter_root.position = Vector2(660.0, 700.0)
	_meter_root.size = Vector2(600.0, 110.0)
	_meter_root.visible = false
	add_child(_meter_root)
	_meter_label = Label.new()
	_meter_label.text = "WIGGLE!  A <-> D"
	_meter_label.add_theme_font_size_override("font_size", 40)
	_meter_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	_meter_label.add_theme_constant_override("shadow_offset_x", 2)
	_meter_label.add_theme_constant_override("shadow_offset_y", 2)
	_meter_root.add_child(_meter_label)
	_meter_alt_fill = _make_bar(Vector2(0.0, 56.0), Color(0.95, 0.8, 0.2))
	_meter_time_fill = _make_bar(Vector2(0.0, 84.0), Color(0.85, 0.25, 0.2))

	_blackout = ColorRect.new()
	_blackout.color = Color.BLACK
	_blackout.position = Vector2.ZERO
	_blackout.size = Vector2(1920.0, 0.0)
	_blackout.visible = false
	add_child(_blackout)
	_game_over = Label.new()
	_game_over.add_theme_font_size_override("font_size", 90)
	_game_over.add_theme_color_override("font_color", Color(0.9, 0.2, 0.15))
	_game_over.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_game_over.position = Vector2(0.0, 440.0)
	_game_over.size = Vector2(1920.0, 120.0)
	_game_over.visible = false
	add_child(_game_over)

	_skip_hint = Label.new()
	_skip_hint.text = "Skip: Jump / Enter"
	_skip_hint.position = Vector2(1560.0, 1000.0)
	_skip_hint.add_theme_font_size_override("font_size", 30)
	_skip_hint.visible = false
	add_child(_skip_hint)
	_dev_note = Label.new()
	_dev_note.text = "[dev] Map 1 continues here (Task 3b)"
	_dev_note.position = Vector2(560.0, 480.0)
	_dev_note.add_theme_font_size_override("font_size", 44)
	_dev_note.add_theme_color_override("font_color", Color(1.0, 0.95, 0.4))
	_dev_note.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	_dev_note.add_theme_constant_override("shadow_offset_x", 2)
	_dev_note.add_theme_constant_override("shadow_offset_y", 2)
	_dev_note.visible = false
	add_child(_dev_note)


func _make_bar(at: Vector2, color: Color) -> ColorRect:
	var back: ColorRect = ColorRect.new()
	back.color = Color(0.0, 0.0, 0.0, 0.6)
	back.position = at
	back.size = Vector2(600.0, 22.0)
	_meter_root.add_child(back)
	var fill: ColorRect = ColorRect.new()
	fill.color = color
	fill.position = Vector2.ZERO
	fill.size = Vector2(0.0, 22.0)
	back.add_child(fill)
	return fill


## An empty text hides the box.
func set_subtitle(text: String) -> void:
	if _subtitle == null:
		return
	_subtitle.text = text
	_subtitle_box.visible = text != ""


func subtitle_text() -> String:
	return _subtitle.text if _subtitle != null else ""


func set_wiggle(shown: bool, alternation_progress: float, time_progress: float) -> void:
	if _meter_root == null:
		return
	_meter_root.visible = shown
	_meter_alt_fill.size.x = 600.0 * clampf(alternation_progress, 0.0, 1.0)
	_meter_time_fill.size.x = 600.0 * clampf(1.0 - time_progress, 0.0, 1.0)


func wiggle_visible() -> bool:
	return _meter_root != null and _meter_root.visible


## The screen blacks out from the top: 0 = clear, 1 = fully black.
func set_blackout(progress: float, game_over_text: String = "") -> void:
	if _blackout == null:
		return
	var p: float = clampf(progress, 0.0, 1.0)
	_blackout.visible = p > 0.0
	_blackout.size.y = 1080.0 * p
	_game_over.visible = game_over_text != "" and p >= 1.0
	_game_over.text = game_over_text


func blackout_progress() -> float:
	return _blackout.size.y / 1080.0 if _blackout != null else 0.0


func set_skip_hint(shown: bool) -> void:
	if _skip_hint != null:
		_skip_hint.visible = shown


func set_dev_note(shown: bool) -> void:
	if _dev_note != null:
		_dev_note.visible = shown


func dev_note_visible() -> bool:
	return _dev_note != null and _dev_note.visible
