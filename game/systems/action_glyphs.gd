extends RefCounted
## The name of the button or key an action is bound to, on the device in use (keyboard and mouse,
## or the controller). Read from the input map through ControlsListing, so a rebound action shows its
## new binding and no key text is ever typed into the game's own text.

const ControlsListingScript := preload("res://systems/controls_listing.gd")


## First binding of `action` on the controller (pad = true) or on keyboard / mouse (pad = false). If
## the action has none on that device, its first binding on the other one; if it has none at all, the
## action's own id.
static func glyph(action: String, pad: bool) -> String:
	if not InputMap.has_action(action):
		return action
	var fallback: String = ""
	for event: InputEvent in InputMap.action_get_events(action):
		var text: String = ControlsListingScript.event_text(event)
		if text == "":
			continue
		var is_pad: bool = event is InputEventJoypadButton or event is InputEventJoypadMotion
		if is_pad == pad:
			return text
		if fallback == "":
			fallback = text
	return fallback if fallback != "" else action


## Replaces every {action_id} in `text` with that action's glyph; {action} stands for `action`.
static func fill(text: String, action: String, pad: bool) -> String:
	var regex: RegEx = RegEx.new()
	regex.compile("\\{([a-z_]+)\\}")
	var out: String = text
	for found: RegExMatch in regex.search_all(text):
		var id: String = found.get_string(1)
		out = out.replace(found.get_string(0), glyph(action if id == "action" else id, pad))
	return out
