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
## Container, items or popup contents changed.
signal inventory_changed
signal coat_changed(on: bool)
## The "container is full" popup opened for this item id / closed again.
signal popup_opened(item_id: String)
signal popup_closed
## An item left the inventory and should appear on the ground at the 떡's feet.
signal item_dropped(item_id: String)

enum Pickup { PICKED, NO_CONTAINER, FULL, UNKNOWN }

const ItemCatalogScript := preload("res://systems/item_catalog.gd")
const HealthItemDefScript := preload("res://items/health_item_def.gd")
const ContainerDefScript := preload("res://items/container_def.gd")
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
## Id of the held container (empty = none: carried items cannot be picked up).
var container_id: String = ""
## Slots of the held container; 0 with no container.
var inventory_capacity: int = 0
## Stable string item ids, in pickup order (oldest first). One item per slot.
var items: Array[String] = []
## Coat (from 콩고물): blocks the damage of the next hit only.
var coat: bool = false
## Item id the "full" popup is asking about; empty = no popup open.
var popup_item_id: String = ""
## Last 찜기 used. Empty id = no checkpoint yet.
var checkpoint_id: String = ""
var checkpoint_position: Vector3 = Vector3.ZERO
## Id of the selected sauce type (see data/sauce_types.tres).
var sauce_type_id: String = DEFAULT_SAUCE_TYPE
## Ids of enemy defs defeated at least once. Drives "unlock on first defeat".
var defeated_enemies: Array[String] = []

var _popup_on_used: Callable


func reset() -> void:
	hearts = START_HEARTS
	sauce = START_SAUCE
	sodium = START_SODIUM
	skills = DEFAULT_SKILLS.duplicate()
	container_id = ""
	inventory_capacity = 0
	items = []
	coat = false
	close_popup()
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


## A hit that the coat may absorb. Returns true if the coat blocked the damage (the coat is
## used up). Knockback and invulnerability are the caller's business, not decided here.
func take_hit(half_hearts: int) -> bool:
	if half_hearts > 0 and coat:
		_set_coat(false)
		return true
	take_damage(half_hearts)
	return false


func can_heal() -> bool:
	return hearts > 0 and hearts < MAX_HEARTS


## Sesame oil (and anything that only heals if hurt): heals and returns true only if the
## 떡 is hurt, so an unhurt 떡 does not use it up.
func heal_if_hurt(half_hearts: int) -> bool:
	if not can_heal():
		return false
	heal(half_hearts)
	return true


# --- Container, items, popup -----------------------------------------------------------

func has_container() -> bool:
	return container_id != ""


func container_name() -> String:
	var def: ContainerDefScript = ItemCatalogScript.container(container_id)
	return def.display_name if def != null else ""


func is_full() -> bool:
	return items.size() >= inventory_capacity


## Equips a container if none is held. Returns false (the pickup stays on the ground) if one
## is already held or the id is unknown.
func try_equip_container(id: String) -> bool:
	if has_container():
		return false
	var def: ContainerDefScript = ItemCatalogScript.container(id)
	if def == null:
		return false
	container_id = id
	inventory_capacity = maxi(def.capacity, 0)
	inventory_changed.emit()
	return true


## Debug: no container, no items, no coat.
func clear_inventory() -> void:
	container_id = ""
	inventory_capacity = 0
	items = []
	close_popup()
	_set_coat(false)
	inventory_changed.emit()


## Carried health items NEVER heal on touch. PICKED: it is in the inventory now.
## NO_CONTAINER: nowhere to put it. FULL: no room (the caller opens the popup).
func try_pickup_item(id: String) -> Pickup:
	if ItemCatalogScript.health_item(id) == null:
		return Pickup.UNKNOWN
	if not has_container():
		return Pickup.NO_CONTAINER
	if is_full():
		return Pickup.FULL
	items.append(id)
	inventory_changed.emit()
	return Pickup.PICKED


## True if using this item would change nothing: hearts full AND it gives no coat (or a
## coat is already on), or the 떡 is dead.
func would_do_nothing(id: String) -> bool:
	var def: HealthItemDefScript = ItemCatalogScript.health_item(id)
	if def == null or hearts <= 0:
		return true
	var heals: bool = hearts < MAX_HEARTS and def.heal_half_hearts > 0
	var gives_coat: bool = def.grants_coat and not coat
	return not heals and not gives_coat


## Heals and sets the coat. A coat that is already on does not stack.
func apply_item(id: String) -> bool:
	var def: HealthItemDefScript = ItemCatalogScript.health_item(id)
	if def == null:
		return false
	heal(def.heal_half_hearts)
	if def.grants_coat:
		_set_coat(true)
	return true


## Inventory screen: use the item in this slot. Refused (false, nothing used) if it would do
## nothing. Unlike the heal button this works at full hearts, so a 콩고물 can give its coat.
func use_item_at(index: int) -> bool:
	if index < 0 or index >= items.size() or would_do_nothing(items[index]):
		return false
	var id: String = items[index]
	items.remove_at(index)
	apply_item(id)
	inventory_changed.emit()
	return true


## Inventory screen: drop the item in this slot. Returns its id ("" if the slot is empty).
func drop_item_at(index: int) -> String:
	if index < 0 or index >= items.size():
		return ""
	var id: String = items[index]
	items.remove_at(index)
	inventory_changed.emit()
	item_dropped.emit(id)
	return id


## Slot indices in the order the heal button would use them: least healing first; ties:
## no coat before coat; then the oldest pickup. Unknown ids are left out.
func heal_order() -> Array[int]:
	var order: Array[int] = []
	for i: int in items.size():
		if ItemCatalogScript.health_item(items[i]) != null:
			order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool:
		var da: HealthItemDefScript = ItemCatalogScript.health_item(items[a])
		var db: HealthItemDefScript = ItemCatalogScript.health_item(items[b])
		if da.heal_half_hearts != db.heal_half_hearts:
			return da.heal_half_hearts < db.heal_half_hearts
		if da.grants_coat != db.grants_coat:
			return not da.grants_coat
		return a < b)
	return order


## The heal button. `preferred` is the Settings default: an item id wins when held (oldest
## first); "lowest" or an item that is not held means the normal order. At full hearts (or
## dead) it does nothing and uses nothing up. Returns the used item id ("" if none).
func heal_button(preferred: String = "lowest") -> String:
	if not can_heal():
		return ""
	var order: Array[int] = heal_order()
	if order.is_empty():
		return ""
	var pick: int = order[0]
	if preferred != "lowest":
		for i: int in items.size():
			if items[i] == preferred and order.has(i):
				pick = i
				break
	var id: String = items[pick]
	items.remove_at(pick)
	apply_item(id)
	inventory_changed.emit()
	return id


func popup_open() -> bool:
	return popup_item_id != ""


## Opens the "your container is full" popup for an item. `on_used` runs if the player picks
## "use it now" (the pickup removes itself then). False if a popup is already open.
func open_popup(item_id: String, on_used: Callable = Callable()) -> bool:
	if popup_open() or ItemCatalogScript.health_item(item_id) == null:
		return false
	popup_item_id = item_id
	_popup_on_used = on_used
	popup_opened.emit(item_id)
	return true


## "Use it now" (use = true) or "drop it" (leave it on the ground). Using is refused, and the
## popup stays open, if it would do nothing. Closing the popup any other way = drop it.
func resolve_popup(use: bool) -> bool:
	if not popup_open():
		return false
	if use:
		if would_do_nothing(popup_item_id):
			return false
		apply_item(popup_item_id)
		var done: Callable = _popup_on_used
		close_popup()
		if done.is_valid():
			done.call()
		return true
	close_popup()
	return true


func close_popup() -> void:
	if not popup_open():
		return
	popup_item_id = ""
	_popup_on_used = Callable()
	popup_closed.emit()


func _set_coat(on: bool) -> void:
	if coat != on:
		coat = on
		coat_changed.emit(coat)


## 13 half-hearts -> "6.5", 14 -> "7".
static func format_hearts(half_hearts: int) -> String:
	var whole: int = half_hearts / 2
	return "%d.5" % whole if half_hearts % 2 == 1 else "%d" % whole


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
		"container_id": container_id,
		"coat": coat,
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
	# Added after save_version 1 shipped (additive): older saves lack these keys.
	container_id = ""
	var saved_container: Variant = data.get("container_id")
	if saved_container is String and ItemCatalogScript.is_container(saved_container):
		container_id = saved_container
		inventory_capacity = maxi(ItemCatalogScript.container(container_id).capacity, 0)
	coat = data.get("coat") is bool and data["coat"]
	close_popup()

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
	inventory_changed.emit()
	coat_changed.emit(coat)
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
