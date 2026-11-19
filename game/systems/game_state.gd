extends Node
## Autoload "GameState": hearts, sauce, sodium, skills and inventory placeholder.
## Hearts are stored in HALF-heart units (14 = 7 hearts).

signal hearts_changed(hearts: int, max_hearts: int)
signal sauce_changed(sauce: int, max_sauce: int)
signal sodium_changed(sodium: int, max_sodium: int)
signal skill_unlocked(skill_id: String)
signal died
signal checkpoint_changed(id: String)
signal sauce_type_changed(id: String)

const SauceTypeListScript := preload("res://systems/sauce_type_list.gd")
const SauceTypeScript := preload("res://systems/sauce_type.gd")

const SAUCE_TYPES_PATH: String = "res://data/sauce_types.tres"
const DEFAULT_SAUCE_TYPE: String = "gochujang"

const MAX_HEARTS: int = 14
const START_HEARTS: int = 14
const MAX_SAUCE: int = 7
const START_SAUCE: int = 3
const MAX_SODIUM: int = 7
const START_SODIUM: int = 0

const DEFAULT_SKILLS: Dictionary[String, bool] = {
	"move": true,
	"jump": true,
	"landing": true,
	"stomp": true,
	"roll": false,
	"slam": false,
	"sauce_flick": false,
	"double_jump": false,
	"sauce_spin": false,
	"sauce_sniper": false,
}

var hearts: int = START_HEARTS
var sauce: int = START_SAUCE
var sodium: int = START_SODIUM
var skills: Dictionary[String, bool] = DEFAULT_SKILLS.duplicate()
## No container yet, so capacity is 0. Placeholder only; no UI.
var inventory_capacity: int = 0
## Stable string item ids.
var items: Array[String] = []
## Last 찜기 used. Empty id = no checkpoint yet.
var checkpoint_id: String = ""
var checkpoint_position: Vector3 = Vector3.ZERO
## Id of the selected sauce type (see data/sauce_types.tres).
var sauce_type_id: String = DEFAULT_SAUCE_TYPE
## Ids of enemy defs defeated at least once. Drives "unlock on first defeat".
var defeated_enemies: Array[String] = []


func reset() -> void:
	hearts = START_HEARTS
	sauce = START_SAUCE
	sodium = START_SODIUM
	skills = DEFAULT_SKILLS.duplicate()
	inventory_capacity = 0
	items = []
	checkpoint_id = ""
	checkpoint_position = Vector3.ZERO
	sauce_type_id = DEFAULT_SAUCE_TYPE
	defeated_enemies = []
	_emit_all()


func is_dead() -> bool:
	return hearts <= 0


func take_damage(half_hearts: int) -> void:
	if half_hearts <= 0:
		return
	var before: int = hearts
	hearts = clampi(hearts - half_hearts, 0, MAX_HEARTS)
	if hearts != before:
		hearts_changed.emit(hearts, MAX_HEARTS)
	if before > 0 and hearts == 0:
		died.emit()


## Does nothing at 0 hearts: a dead 떡 is only brought back by respawn().
func heal(half_hearts: int) -> void:
	if half_hearts <= 0 or hearts <= 0:
		return
	var before: int = hearts
	hearts = clampi(hearts + half_hearts, 0, MAX_HEARTS)
	if hearts != before:
		hearts_changed.emit(hearts, MAX_HEARTS)


func set_checkpoint(id: String, at: Vector3) -> void:
	checkpoint_id = id
	checkpoint_position = at
	checkpoint_changed.emit(id)


## Using a 찜기: full heal and it becomes the checkpoint. Refused (false) while dead.
func use_steamer(id: String, at: Vector3) -> bool:
	if is_dead():
		return false
	set_checkpoint(id, at)
	heal(MAX_HEARTS)
	return true


## Brings a dead 떡 back with full hearts. Returns where to put him (the last checkpoint).
func respawn() -> Vector3:
	if hearts != MAX_HEARTS:
		hearts = MAX_HEARTS
		hearts_changed.emit(hearts, MAX_HEARTS)
	return checkpoint_position


func add_sauce(n: int) -> void:
	if n <= 0:
		return
	var before: int = sauce
	sauce = clampi(sauce + n, 0, MAX_SAUCE)
	if sauce != before:
		sauce_changed.emit(sauce, MAX_SAUCE)


func spend_sauce(n: int) -> bool:
	if n < 0 or n > sauce:
		return false
	if n == 0:
		return true
	sauce -= n
	sauce_changed.emit(sauce, MAX_SAUCE)
	return true


## Ids of every sauce type, in cycle order.
func sauce_type_ids() -> Array[String]:
	var list: SauceTypeListScript = load(SAUCE_TYPES_PATH) as SauceTypeListScript
	return list.ids() if list != null else ([] as Array[String])


## The selected type's data, or null if the id is unknown.
func current_sauce_type() -> SauceTypeScript:
	var list: SauceTypeListScript = load(SAUCE_TYPES_PATH) as SauceTypeListScript
	return list.find(sauce_type_id) if list != null else null


## step +1 = next, -1 = previous; wraps. With one type (or an unknown id) nothing changes.
func cycle_sauce_type(step: int) -> void:
	var ids: Array[String] = sauce_type_ids()
	if ids.size() < 2:
		return
	var index: int = ids.find(sauce_type_id)
	if index < 0:
		index = 0
	var next_id: String = ids[posmod(index + step, ids.size())]
	if next_id != sauce_type_id:
		sauce_type_id = next_id
		sauce_type_changed.emit(sauce_type_id)


## Call when an enemy dies. The FIRST defeat of this enemy id unlocks `unlock_skill_id`
## (if not empty); later defeats do nothing. Returns true only on that first defeat.
func register_defeat(enemy_id: String, unlock_skill_id: String = "") -> bool:
	if enemy_id == "" or defeated_enemies.has(enemy_id):
		return false
	defeated_enemies.append(enemy_id)
	if unlock_skill_id != "":
		unlock_skill(unlock_skill_id)
	return true


func add_sodium(n: int) -> void:
	if n <= 0:
		return
	var before: int = sodium
	sodium = clampi(sodium + n, 0, MAX_SODIUM)
	if sodium != before:
		sodium_changed.emit(sodium, MAX_SODIUM)


func spend_sodium(n: int) -> bool:
	if n < 0 or n > sodium:
		return false
	if n == 0:
		return true
	sodium -= n
	sodium_changed.emit(sodium, MAX_SODIUM)
	return true


func has_skill(skill_id: String) -> bool:
	return skills.get(skill_id, false)


## Returns false for an unknown skill id. Unlocking an already unlocked skill is a no-op.
func unlock_skill(skill_id: String) -> bool:
	if not skills.has(skill_id):
		return false
	if not skills[skill_id]:
		skills[skill_id] = true
		skill_unlocked.emit(skill_id)
	return true


func to_dict() -> Dictionary:
	return {
		"hearts": hearts,
		"sauce": sauce,
		"sodium": sodium,
		"skills": skills.duplicate(),
		"inventory_capacity": inventory_capacity,
		"items": items.duplicate(),
		"checkpoint_id": checkpoint_id,
		"checkpoint_position": [checkpoint_position.x, checkpoint_position.y, checkpoint_position.z],
		"sauce_type": sauce_type_id,
		"defeated_enemies": defeated_enemies.duplicate(),
	}


## Tolerant: unknown keys and unknown skill ids are ignored, wrong types fall back to defaults.
func from_dict(data: Dictionary) -> void:
	hearts = clampi(_to_int(data.get("hearts"), START_HEARTS), 0, MAX_HEARTS)
	sauce = clampi(_to_int(data.get("sauce"), START_SAUCE), 0, MAX_SAUCE)
	sodium = clampi(_to_int(data.get("sodium"), START_SODIUM), 0, MAX_SODIUM)
	inventory_capacity = maxi(_to_int(data.get("inventory_capacity"), 0), 0)

	skills = DEFAULT_SKILLS.duplicate()
	var saved_skills: Variant = data.get("skills")
	if saved_skills is Dictionary:
		for id: Variant in saved_skills:
			if id is String and skills.has(id) and saved_skills[id] is bool:
				skills[id] = saved_skills[id]

	items = []
	var saved_items: Variant = data.get("items")
	if saved_items is Array:
		for item: Variant in saved_items:
			if item is String:
				items.append(item)

	var saved_id: Variant = data.get("checkpoint_id")
	checkpoint_id = saved_id if saved_id is String else ""
	checkpoint_position = Vector3.ZERO
	var saved_pos: Variant = data.get("checkpoint_position")
	if saved_pos is Array and (saved_pos as Array).size() == 3:
		var p: Array = saved_pos
		var ok: bool = true
		for v: Variant in p:
			ok = ok and (v is float or v is int) and is_finite(float(v))
		if ok:
			checkpoint_position = Vector3(float(p[0]), float(p[1]), float(p[2]))

	# Added after save_version 1 shipped: older saves simply lack these keys.
	sauce_type_id = DEFAULT_SAUCE_TYPE
	var saved_type: Variant = data.get("sauce_type")
	if saved_type is String and sauce_type_ids().has(saved_type):
		sauce_type_id = saved_type
	defeated_enemies = []
	var saved_defeats: Variant = data.get("defeated_enemies")
	if saved_defeats is Array:
		for enemy_id: Variant in saved_defeats:
			if enemy_id is String and enemy_id != "" and not defeated_enemies.has(enemy_id):
				defeated_enemies.append(enemy_id)
	_emit_all()


func _emit_all() -> void:
	hearts_changed.emit(hearts, MAX_HEARTS)
	sauce_changed.emit(sauce, MAX_SAUCE)
	sodium_changed.emit(sodium, MAX_SODIUM)


## JSON numbers arrive as floats, so accept int and float.
static func _to_int(value: Variant, fallback: int) -> int:
	if value is int:
		return value
	if value is float and is_finite(value):
		return int(value)
	return fallback
