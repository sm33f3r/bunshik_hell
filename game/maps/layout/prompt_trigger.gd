extends Resource
## A hint (and sometimes a skill grant) that fires once per life when he stands inside `rect`.
## Text may hold {action_id} placeholders; they become the glyph name of that action on the device in
## use (never hard-coded key text). `{action}` stands for the `action` field.

@export var id: String = ""
@export var platform_id: String = ""
## x: metres from the platform's left edge. y: metres above its top. size: width and height.
@export var rect: Rect2 = Rect2(0.0, 0.0, 4.0, 6.0)
@export var text: String = ""
@export var action: String = ""
## How long the hint stays up (seconds).
@export var show_s: float = 6.0
## A skill granted when this fires, the source id it is recorded under, and the toast text.
@export var grants_skill: String = ""
@export var grant_source: String = "tutorial"
@export var toast: String = ""
## Which beat of the tutorial this belongs to ("a".."e").
@export var beat: String = ""
