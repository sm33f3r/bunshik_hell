extends RefCounted
## The rows of the Settings "Controls" page, read from the input map (so rebinding later shows up
## here for free). Read-only. One row per action: its label, its keyboard / mouse bindings and its
## controller bindings.

## Shown names. An action not listed here shows its own id, so a new action is never missing.
const LABELS: Dictionary[String, String] = {
	"move_left": "Move left", "move_right": "Move right", "look_up": "Up / use steamer",
	"look_down": "Down / drop through", "jump": "Jump", "roll": "Roll / slam",
	"sauce_attack": "Sauce", "special": "Special", "sauce_next": "Next sauce",
	"sauce_prev": "Previous sauce", "heal": "Heal", "inventory": "Inventory",
	"drop_item": "Drop item", "pause": "Pause", "aim_left": "Aim left", "aim_right": "Aim right",
	"aim_up": "Aim up", "aim_down": "Aim down", "ui_accept": "Menu: confirm",
	"ui_cancel": "Menu: back",
}
## Controller buttons by index (Godot's JoyButton), named for a DualSense, with the Xbox name.
const PAD_BUTTONS: Dictionary[int, String] = {
	0: "✕ (A)", 1: "○ (B)", 2: "□ (X)", 3: "△ (Y)", 4: "Create (Back)", 5: "PS (Guide)",
	6: "Options (Start)", 7: "L3", 8: "R3", 9: "L1 (LB)", 10: "R1 (RB)",
	11: "D-pad up", 12: "D-pad down", 13: "D-pad left", 14: "D-pad right",
	20: "Touchpad",
}
const PAD_AXES: Dictionary[int, String] = {
	0: "Left stick", 1: "Left stick", 2: "Right stick", 3: "Right stick",
	4: "L2 (LT)", 5: "R2 (RT)",
}
const NONE_TEXT: String = "-"


## Every action of the game, in input-map order: the project's own actions and the two menu
## actions ui_accept / ui_cancel. The other built-in ui_* actions are not part of the game's controls.
static func action_ids() -> Array[String]:
	var out: Array[String] = []
	for action: StringName in InputMap.get_actions():
		var id: String = String(action)
		if id.begins_with("ui_") and id != "ui_accept" and id != "ui_cancel":
			continue
		out.append(id)
	return out


## [{"action", "label", "keyboard", "controller"}, ...]
static func rows() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: String in action_ids():
		var keyboard: Array[String] = []
		var pad: Array[String] = []
		for event: InputEvent in InputMap.action_get_events(id):
			var text: String = event_text(event)
			if text == "":
				continue
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				if not pad.has(text):
					pad.append(text)
			elif not keyboard.has(text):
				keyboard.append(text)
		out.append({
			"action": id,
			"label": LABELS.get(id, id),
			"keyboard": " / ".join(keyboard) if not keyboard.is_empty() else NONE_TEXT,
			"controller": " / ".join(pad) if not pad.is_empty() else NONE_TEXT,
		})
	return out


static func event_text(event: InputEvent) -> String:
	var key: InputEventKey = event as InputEventKey
	if key != null:
		if key.physical_keycode != KEY_NONE:
			return key.as_text_physical_keycode()
		return key.as_text_keycode()
	var mouse: InputEventMouseButton = event as InputEventMouseButton
	if mouse != null:
		match mouse.button_index:
			MOUSE_BUTTON_LEFT: return "Mouse left"
			MOUSE_BUTTON_RIGHT: return "Mouse right"
			MOUSE_BUTTON_MIDDLE: return "Mouse middle"
			MOUSE_BUTTON_WHEEL_UP: return "Wheel up"
			MOUSE_BUTTON_WHEEL_DOWN: return "Wheel down"
		return "Mouse button %d" % mouse.button_index
	var button: InputEventJoypadButton = event as InputEventJoypadButton
	if button != null:
		return PAD_BUTTONS.get(button.button_index, "Button %d" % button.button_index)
	var motion: InputEventJoypadMotion = event as InputEventJoypadMotion
	if motion != null:
		return _axis_text(motion)
	return ""


static func _axis_text(motion: InputEventJoypadMotion) -> String:
	var axis_name: String = PAD_AXES.get(motion.axis, "Axis %d" % motion.axis)
	if motion.axis >= 4:
		return axis_name
	var horizontal: bool = motion.axis == 0 or motion.axis == 2
	var direction: String
	if horizontal:
		direction = "left" if motion.axis_value < 0.0 else "right"
	else:
		direction = "up" if motion.axis_value < 0.0 else "down"
	return "%s %s" % [axis_name, direction]
