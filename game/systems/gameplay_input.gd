class_name GameplayInput
extends RefCounted
## Gameplay reads its button presses through here. When a menu (the popup, the inventory screen)
## closes, the press that closed it is still "just pressed" for the next physics tick or two:
## the cross is jump, the circle is roll, the square is the flick, Space is jump. Input.
## action_release() does not clear that, so the menu calls swallow() and gameplay ignores every
## fresh press for BLOCK_TICKS physics ticks. Held movement (get_axis) is not affected.

## Physics ticks after swallow() during which just_pressed() says no (2 ticks = 33 ms).
const BLOCK_TICKS: int = 2

static var _block_until_tick: int = 0


## Call when a menu closes.
static func swallow() -> void:
	_block_until_tick = Engine.get_physics_frames() + BLOCK_TICKS


## True while a closing press may still be reported.
static func is_blocked() -> bool:
	return Engine.get_physics_frames() < _block_until_tick


## Input.is_action_just_pressed(), except right after a menu closed.
static func just_pressed(action: StringName) -> bool:
	return not is_blocked() and Input.is_action_just_pressed(action)


## Forget any block (tests).
static func clear() -> void:
	_block_until_tick = 0
