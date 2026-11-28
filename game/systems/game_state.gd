extends Node
## Autoload "GameState": hearts, sauce, sodium, skills and inventory placeholder.
## Hearts are stored in HALF-heart units (14 = 7 hearts).

signal hearts_changed(hearts: int, max_hearts: int)
signal sauce_changed(sauce: int, max_sauce: int)
signal sodium_changed(sodium: int, max_sodium: int)
signal skill_unlocked(skill_id: String)
signal died
signal checkpoint_changed(id: String)
## A 찜기 was used for the first time (its placement id).
signal jjigi_used(id: String)
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
const DropRollerScript := preload("res://systems/drop_roller.gd")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const SpawnPickScript := preload("res://systems/spawn_pick.gd")

const SAUCE_TYPES_PATH: String = "res://data/sauce_types.tres"
const DEFAULT_SAUCE_TYPE: String = "gochujang"

const MAX_HEARTS: int = 14
const START_HEARTS: int = 14
const MAX_SAUCE: int = 7
const START_SAUCE: int = 3
const MAX_SODIUM: int = 7
const START_SODIUM: int = 0

## What the respawn point is: a data checkpoint of the map, or a 찜기 that was used.
const RESPAWN_CHECKPOINT: String = "checkpoint"
const RESPAWN_JJIGI: String = "jjigi"

## Story flags. FLAG_DEFAULTS is the ONE place that says what a flag is before anything has set it.
## "ramen1_defeated" is true for now, so the kitchen door is open until the first 라면 exists:
## Task 3c-i-b changes this to false (and adds the flag to FLAGS_SET_BY_GAME).
const FLAG_DEFAULTS: Dictionary[String, bool] = {"ramen1_defeated": true}
## The flags the game's code can set (see ProgressGraph.door_problems). None yet.
const FLAGS_SET_BY_GAME: Array[String] = []
## DEBUG BUILDS ONLY: godot --path game -- --flag-off=ramen1_defeated reads that flag as not set (so
## its door is locked), whatever it is. Never saved.
const FLAG_OFF_PREFIX: String = "--flag-off="

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
## THE respawn point: whichever of (a data checkpoint reached, a 찜기 used) happened most recently.
## Empty id = none yet. `respawn_type` says which kind it is (RESPAWN_CHECKPOINT / RESPAWN_JJIGI).
## (The fields keep their old "checkpoint" names: a lot of map code reads them.)
var checkpoint_id: String = ""
var checkpoint_position: Vector3 = Vector3.ZERO
var respawn_type: String = RESPAWN_CHECKPOINT
## Placement ids of the 찜기 already used (each gives its one heal and save, once). Saved.
var used_jjigi: Array[String] = []
## Ids of every data checkpoint reached, so one is never "reached" again and an earlier one never
## replaces a later respawn point. Saved.
var reached_checkpoints: Array[String] = []
## Id of the map he is in ("map01", "test_room"; see MapCatalog). Saved.
var current_map: String = ""
## The tutorial was finished (or skipped past). Saved.
var tutorial_done: bool = false
## DDEOK, off-chain only for now (ChainBridge is a stub). Saved.
var ddeok: int = 0
## Id of the selected sauce type (see data/sauce_types.tres).
var sauce_type_id: String = DEFAULT_SAUCE_TYPE
## Ids of enemy defs defeated at least once. Drives "unlock on first defeat".
var defeated_enemies: Array[String] = []
## Rolls enemy drops and counts the bad-luck streak per enemy type. Not saved.
var drops: DropRollerScript = DropRollerScript.new()
## Kills BY THE 떡 per enemy type (def id). Drives every-Nth-kill drops. Survives his death and
## the prologue restart; cleared by reset() (new game). Not saved.
var kill_counts: Dictionary[String, int] = {}
## Map 1 prologue: the opening cutscene was shown (it never replays), and the prologue is done.
var prologue_intro_seen: bool = false
var prologue_complete: bool = false
## Map 1: the "tutorial or skip" prompt was shown. Once per new game. Saved.
var tutorial_prompt_shown: bool = false
## Which source gave each skill ("tutorial", a boss...), for skills unlocked with a source id. Saved.
var skill_sources: Dictionary[String, String] = {}
## The seed of this game (0 = not made yet: the first pick makes one). A new game has a new seed, so a
## "spawn choice" (a thing with several candidate spots, see SpawnEntry) may come out differently.
## Saved (additive key; save_version stays 1).
var game_seed: int = 0
## Spawn choice id -> the candidate spot id picked for this game. Made once, from the seed; saved, so
## reloads and respawns keep the spot. A new game starts with none.
var spawn_picks: Dictionary[String, String] = {}
## DEBUG / TESTS ONLY, never saved: choice id -> a spot id to use instead of the pick (see SpawnPick for
## the command-line way).
var debug_spawn_overrides: Dictionary[String, String] = {}
## Story flags that were set (id -> value); a flag not here has its FLAG_DEFAULTS value. They survive
## death and respawn. Saved (additive key; save_version stays 1).
var flags: Dictionary[String, bool] = {}
## DEBUG / TESTS ONLY, never saved: flag id -> a value to read instead.
var debug_flag_overrides: Dictionary[String, bool] = {}
## What he carried when he reached the current checkpoint or used the current 찜기 ({"sauce",
## "sodium"}); empty = none taken. Respawning puts these back. Saved only for a 찜기 (saves are
## made there); a data checkpoint's is not saved.
var checkpoint_snapshot: Dictionary = {}

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
	respawn_type = RESPAWN_CHECKPOINT
	used_jjigi = []
	reached_checkpoints = []
	current_map = ""
	tutorial_done = false
	ddeok = 0
	sauce_type_id = DEFAULT_SAUCE_TYPE
	defeated_enemies = []
	drops.reset()
	kill_counts.clear()
	prologue_intro_seen = false
	prologue_complete = false
	tutorial_prompt_shown = false
	skill_sources = {}
	checkpoint_snapshot = {}
	game_seed = 0
	spawn_picks = {}
	debug_spawn_overrides = {}
	flags = {}
	debug_flag_overrides = {}
	_emit_all()


## The spot of a spawn choice for this game: a debug override, else the one picked before (saved), else
## a new pick from the game's seed (kept from then on). `spot_ids` are the candidate ids of the choice.
## A saved pick that is no longer a candidate is picked again.
func spawn_pick(choice_id: String, spot_ids: Array[String]) -> String:
	if spot_ids.is_empty():
		return ""
	var forced: String = debug_spawn_overrides.get(choice_id, SpawnPickScript.cmdline_override(choice_id))
	if forced != "" and spot_ids.has(forced):
		return forced
	var kept: String = spawn_picks.get(choice_id, "")
	if kept != "" and spot_ids.has(kept):
		return kept
	if game_seed == 0:
		game_seed = SpawnPickScript.new_seed()
	var picked: String = spot_ids[SpawnPickScript.pick_index(game_seed, choice_id, spot_ids.size())]
	spawn_picks[choice_id] = picked
	return picked


func has_flag(id: String) -> bool:
	if debug_flag_overrides.has(id):
		return debug_flag_overrides[id]
	if OS.is_debug_build() and OS.get_cmdline_user_args().has(FLAG_OFF_PREFIX + id):
		return false
	return flags.get(id, FLAG_DEFAULTS.get(id, false))


func set_flag(id: String, value: bool = true) -> void:
	if id != "":
		flags[id] = value


## One kill BY THE 떡 of this enemy type. Returns the drops it earns from the every-Nth-kill
## rule ([{"kind", "amount"}] or empty). Uses no randomness. Kills that are not his are not
## passed in here.
func periodic_drop(def: EnemyDefScript) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if def == null or def.id == "":
		return out
	var count: int = kill_counts.get(def.id, 0) + 1
	kill_counts[def.id] = count
	if def.every_nth_kill > 0 and def.every_nth_drop != "" and count % def.every_nth_kill == 0:
		out.append({"kind": def.every_nth_drop, "amount": 1})
	return out


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


## A respawn point without a snapshot (the prologue's own, the test room's start).
func set_checkpoint(id: String, at: Vector3) -> void:
	_set_respawn(id, at, RESPAWN_CHECKPOINT)
	if id != "" and not reached_checkpoints.has(id):
		reached_checkpoints.append(id)
	checkpoint_changed.emit(id)


## A map checkpoint: respawning here gives full hearts and the sauce and 나트륨 he has right now.
func set_checkpoint_snapshot(id: String, at: Vector3) -> void:
	set_checkpoint(id, at)
	checkpoint_snapshot = {"sauce": sauce, "sodium": sodium}


func is_jjigi_used(id: String) -> bool:
	return id != "" and used_jjigi.has(id)


## Using a 찜기: full heal; it is marked used; it becomes the respawn point, with the sauce and
## 나트륨 he has right now. Refused (false, nothing changes) while dead, and when this 찜기 was used
## already unless `repeatable` (the debug_unlimited test-room 찜기). The save is the caller's step.
func use_jjigi(id: String, at: Vector3, repeatable: bool = false) -> bool:
	if is_dead():
		return false
	if is_jjigi_used(id) and not repeatable:
		return false
	_set_respawn(id, at, RESPAWN_JJIGI)
	checkpoint_snapshot = {"sauce": sauce, "sodium": sodium}
	if id != "" and not used_jjigi.has(id):
		used_jjigi.append(id)
	checkpoint_changed.emit(id)
	heal(MAX_HEARTS)
	jjigi_used.emit(id)
	return true


func _set_respawn(id: String, at: Vector3, type: String) -> void:
	checkpoint_id = id
	checkpoint_position = at
	respawn_type = type
	checkpoint_snapshot = {}


## Brings a dead 떡 back with full hearts, and with the sauce and 나트륨 of the respawn point's
## snapshot when it has one. Returns where to put him. Never re-runs a 찜기's heal or save.
func respawn() -> Vector3:
	if hearts != MAX_HEARTS:
		hearts = MAX_HEARTS
		hearts_changed.emit(hearts, MAX_HEARTS)
	if not checkpoint_snapshot.is_empty():
		var kept_sauce: int = clampi(_to_int(checkpoint_snapshot.get("sauce"), sauce), 0, MAX_SAUCE)
		var kept_sodium: int = clampi(_to_int(checkpoint_snapshot.get("sodium"), sodium), 0, MAX_SODIUM)
		if kept_sauce != sauce:
			sauce = kept_sauce
			sauce_changed.emit(sauce, MAX_SAUCE)
		if kept_sodium != sodium:
			sodium = kept_sodium
			sodium_changed.emit(sodium, MAX_SODIUM)
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


## Returns false for an unknown skill id. Unlocking an already unlocked skill is a no-op (the first
## source stays). `source` says where it came from ("tutorial", ...); empty = not recorded.
func unlock_skill(skill_id: String, source: String = "") -> bool:
	if not skills.has(skill_id):
		return false
	if not skills[skill_id]:
		skills[skill_id] = true
		if source != "":
			skill_sources[skill_id] = source
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
		"respawn_type": respawn_type,
		"respawn_snapshot": checkpoint_snapshot.duplicate() if respawn_type == RESPAWN_JJIGI else {},
		"used_jjigi": used_jjigi.duplicate(),
		"reached_checkpoints": reached_checkpoints.duplicate(),
		"current_map": current_map,
		"tutorial_done": tutorial_done,
		"tutorial_prompt_shown": tutorial_prompt_shown,
		"skill_sources": skill_sources.duplicate(),
		"ddeok": ddeok,
		"sauce_type": sauce_type_id,
		"defeated_enemies": defeated_enemies.duplicate(),
		"prologue_intro_seen": prologue_intro_seen,
		"prologue_complete": prologue_complete,
		"game_seed": game_seed,
		"spawn_picks": spawn_picks.duplicate(),
		"flags": flags.duplicate(),
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
	checkpoint_snapshot = {}
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
	# Added after save_version 1 shipped: older saves simply lack these keys.
	prologue_intro_seen = data.get("prologue_intro_seen") is bool and data["prologue_intro_seen"]
	prologue_complete = data.get("prologue_complete") is bool and data["prologue_complete"]
	# Added with the real 찜기 (still save_version 1: new keys, defaults when absent).
	respawn_type = RESPAWN_CHECKPOINT
	if data.get("respawn_type") == RESPAWN_JJIGI:
		respawn_type = RESPAWN_JJIGI
	used_jjigi = _string_list(data.get("used_jjigi"))
	reached_checkpoints = _string_list(data.get("reached_checkpoints"))
	current_map = data["current_map"] if data.get("current_map") is String else ""
	tutorial_done = data.get("tutorial_done") is bool and data["tutorial_done"]
	tutorial_prompt_shown = data.get("tutorial_prompt_shown") is bool and data["tutorial_prompt_shown"]
	ddeok = maxi(_to_int(data.get("ddeok"), 0), 0)
	skill_sources = {}
	var saved_sources: Variant = data.get("skill_sources")
	if saved_sources is Dictionary:
		for skill_id: Variant in saved_sources:
			if skill_id is String and skills.has(skill_id) and saved_sources[skill_id] is String:
				skill_sources[skill_id] = saved_sources[skill_id]
	# Added with the spawn choices (still save_version 1: new keys, defaults when absent). The squirts of the
	# 간장 bottle and whether it lies down are NOT saved: that starts over with every life.
	game_seed = maxi(_to_int(data.get("game_seed"), 0), 0)
	spawn_picks = {}
	var saved_picks: Variant = data.get("spawn_picks")
	if saved_picks is Dictionary:
		for choice_id: Variant in saved_picks:
			if choice_id is String and choice_id != "" and saved_picks[choice_id] is String and saved_picks[choice_id] != "":
				spawn_picks[choice_id] = saved_picks[choice_id]
	flags = {}
	var saved_flags: Variant = data.get("flags")
	if saved_flags is Dictionary:
		for flag_id: Variant in saved_flags:
			if flag_id is String and flag_id != "" and saved_flags[flag_id] is bool:
				flags[flag_id] = saved_flags[flag_id]
	# The sauce and 나트륨 he had when he used the 찜기 he respawns at. (A data checkpoint's is not saved.)
	checkpoint_snapshot = {}
	var saved_snapshot: Variant = data.get("respawn_snapshot")
	if respawn_type == RESPAWN_JJIGI and saved_snapshot is Dictionary:
		checkpoint_snapshot = {
		"sauce": clampi(_to_int(saved_snapshot.get("sauce"), sauce), 0, MAX_SAUCE),
		"sodium": clampi(_to_int(saved_snapshot.get("sodium"), sodium), 0, MAX_SODIUM),
		}
	_emit_all()


func _emit_all() -> void:
	inventory_changed.emit()
	coat_changed.emit(coat)
	hearts_changed.emit(hearts, MAX_HEARTS)
	sauce_changed.emit(sauce, MAX_SAUCE)
	sodium_changed.emit(sodium, MAX_SODIUM)


## The strings of an array from a save, without duplicates; anything else gives an empty list.
static func _string_list(value: Variant) -> Array[String]:
	var out: Array[String] = []
	if value is Array:
		for entry: Variant in value:
			if entry is String and entry != "" and not out.has(entry):
				out.append(entry)
	return out


## JSON numbers arrive as floats, so accept int and float.
static func _to_int(value: Variant, fallback: int) -> int:
	if value is int:
		return value
	if value is float and is_finite(value):
		return int(value)
	return fallback
