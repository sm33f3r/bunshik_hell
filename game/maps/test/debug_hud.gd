extends CanvasLayer
## Text-only debug HUD for the test room.

const GameStateScript := preload("res://systems/game_state.gd")
const DdeokScript := preload("res://player/ddeok.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const ItemCatalogScript := preload("res://systems/item_catalog.gd")

## How long the "no sauce" cue stays on the sauce readout (seconds).
const REFUSED_CUE_TIME: float = 0.5

const HudScript := preload("res://ui/hud.gd")
const UsableObjectScript := preload("res://items/usable_object.gd")

@export var player: DdeokScript
## The test room shows the debug text; the game scenes switch it off. Debug key 9 toggles it.
@export var shown_by_default: bool = true

var _label: Label
var _game_state: GameStateScript
var _refused_left: float = 0.0
var _natrium_refused_left: float = 0.0


func _ready() -> void:
	add_to_group("debug_hud")
	_label = get_node_or_null("Text") as Label
	if _label != null:
		_label.visible = shown_by_default
	_game_state = get_node_or_null("/root/GameState") as GameStateScript
	if player != null:
		player.sauce_refused.connect(_on_sauce_refused)
		player.special_refused.connect(_on_special_refused)


func _on_sauce_refused() -> void:
	_refused_left = REFUSED_CUE_TIME


func _on_special_refused() -> void:
	_natrium_refused_left = REFUSED_CUE_TIME


## Debug key 9.
func toggle_visible() -> void:
	if _label != null:
		_label.visible = not _label.visible


func text_visible() -> bool:
	return _label != null and _label.visible


func _process(delta: float) -> void:
	if _label == null or _game_state == null:
		return
	if not _label.visible:
		return
	_refused_left = maxf(_refused_left - delta, 0.0)
	_natrium_refused_left = maxf(_natrium_refused_left - delta, 0.0)
	var unlocked: Array[String] = []
	var locked: Array[String] = []
	for id: String in _game_state.skills:
		if _game_state.skills[id]:
			unlocked.append(id)
		else:
			locked.append(id)
	var flick_unlocked: bool = _game_state.has_skill("sauce_flick")
	var cooldown: float = player.sauce_cooldown_left() if player != null else 0.0
	var sauce_line: String = "Sauce: %d / %d" % [_game_state.sauce, _game_state.MAX_SAUCE]
	if _refused_left > 0.0:
		sauce_line += "   << NOT ENOUGH SAUCE >>"
	var natrium_line: String = "Sodium (나트륨): %d / %d" % [_game_state.sodium, _game_state.MAX_SODIUM]
	if _natrium_refused_left > 0.0:
		natrium_line += "   << NOT ENOUGH 나트륨 >>"
	var lines: Array[String] = [
		"Hearts: %s / %s  (%d / %d half-hearts)" % [
			format_hearts(_game_state.hearts), format_hearts(_game_state.MAX_HEARTS),
			_game_state.hearts, _game_state.MAX_HEARTS],
		_coat_line(),
		_container_line(),
		sauce_line,
		natrium_line,
		_special_line(),
		_status_line(),
		"Sauce type: %s    Flick: %s    Cooldown: %.2f s" % [
			_game_state.sauce_type_id, "unlocked" if flick_unlocked else "locked", cooldown],
		"Skills: " + " ".join(unlocked),
		"Locked: " + " ".join(locked),
		"State: " + (player.state_name() if player != null else "-"),
		"Checkpoint: " + (_game_state.checkpoint_id if _game_state.checkpoint_id != "" else "-"),
		_fried_line(),
	]
	if _game_state.popup_open():
		lines.insert(0, tr("POPUP: Your %s is full - use %s now or drop it? (see the popup)") % [
			_game_state.container_name(), _game_state.popup_item_id])
	for node: Node in get_tree().get_nodes_in_group("prologue_map"):
		if node.has_method("debug_lines"):
			lines.append("")
			lines.append_array(node.call("debug_lines"))
	if OS.is_debug_build():
		lines.append("1 unlock roll+slam  2 relock + clear inventory  3 respawn dummies, items, oil, objects  4 -1 heart  5 unlock flick  6 defeat noodle dummy  7 give container  9 hide / show this text")
	_label.text = "\n".join(lines)


func _coat_line() -> String:
	return "Coat: " + ("ON (blocks the next hit's damage)" if _game_state.coat else "off")


## "Container: Starter container 2/3 [콩고물, 꿀]" or "Container: none".
func _container_line() -> String:
	if not _game_state.has_container():
		return "Container: none (carried items cannot be picked up)"
	var names: Array[String] = []
	for id: String in _game_state.items:
		var def: Variant = ItemCatalogScript.health_item(id)
		names.append(def.display_name if def != null else id)
	return "Container: %s %d/%d [%s]" % [_game_state.container_name(),
		_game_state.items.size(), _game_state.inventory_capacity, ", ".join(names)]


## "Special: Water bottle (nearest of 2 in range)" or "Special: -".
func _special_line() -> String:
	if player == null or player.special_target == null:
		return "Special: - (nothing in range)"
	var target: UsableObjectScript = player.special_target
	var line: String = "Special: %s - costs %d 나트륨" % [target.display_name(), target.cost()]
	if player.special_candidates > 1:
		line += "  (nearest of %d in range)" % player.special_candidates
	if _game_state.sodium < target.cost():
		line += "  - not enough 나트륨"
	return line


## "Pinned: NoodleTable 2.4 s" and "Swelling: NoodleDummy 1.1 s" for every enemy in that state.
func _status_line() -> String:
	var pinned: Array[String] = []
	var swelling: Array[String] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: EnemyBaseScript = node as EnemyBaseScript
		if enemy == null or not enemy.alive:
			continue
		if enemy.pin_left > 0.0:
			pinned.append("%s %.1f s" % [enemy.name, enemy.pin_left])
		if enemy.swelling:
			swelling.append("%s %.1f s" % [enemy.name, enemy.swell_left])
	return "Pinned: %s    Swelling: %s" % [
		", ".join(pinned) if not pinned.is_empty() else "-",
		", ".join(swelling) if not swelling.is_empty() else "-"]


## "Fried: FriedSmall=fresh FriedMedium=broken ..." for every enemy made of fried food.
func _fried_line() -> String:
	var parts: Array[String] = []
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		var enemy: EnemyBaseScript = node as EnemyBaseScript
		if enemy != null and enemy.def != null and enemy.def.material == "fried":
			parts.append("%s=%s" % [enemy.name, enemy.stage_name()])
	return "Fried: " + (" ".join(parts) if not parts.is_empty() else "-")


## 13 half-hearts -> "6.5", 14 -> "7".
static func format_hearts(half_hearts: int) -> String:
	return HudScript.format_hearts(half_hearts)
