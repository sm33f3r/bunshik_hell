extends RefCounted
## Remembers which hints were shown in this life, so none shows twice. A death starts a new life
## (reset); a fall back to the checkpoint does not.

var _shown: Dictionary = {}


func reset() -> void:
	_shown.clear()


func was_shown(trigger_id: String) -> bool:
	return _shown.has(trigger_id)


## zones: [{"def": PromptTrigger, "rect": Rect2 (world)}, ...]. `at` is the 떡's feet in the plane.
## Returns the triggers that fire now: those he stands in that have not shown yet.
func check(zones: Array, at: Vector2) -> Array[Resource]:
	var fired: Array[Resource] = []
	for zone: Dictionary in zones:
		var def: Resource = zone["def"]
		if _shown.has(def.id):
			continue
		if (zone["rect"] as Rect2).has_point(at):
			_shown[def.id] = true
			fired.append(def)
	return fired
