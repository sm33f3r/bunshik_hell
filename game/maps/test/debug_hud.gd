extends CanvasLayer
## Text-only debug HUD for the test room.

const GameStateScript := preload("res://systems/game_state.gd")
const DdeokScript := preload("res://player/ddeok.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const ItemCatalogScript := preload("res://systems/item_catalog.gd")

## How long the "no sauce" cue stays on the sauce readout (seconds).
const REFUSED_CUE_TIME: float = 0.5

@export var player: DdeokScript

var _label: Label
var _game_state: GameStateScript
var _refused_left: float = 0.0


func _ready() -> void:
	_label = get_node_or_null("Text") as Label
	_game_state = get_node_or_null("/root/GameState") as GameStateScript
	if player != null:
		player.sauce_refused.connect(_on_sauce_refused)


func _on_sauce_refused() -> void:
	_refused_left = REFUSED_CUE_TIME


func _process(delta: float) -> void:
	if _label == null or _game_state == null:
		return
	_refused_left = maxf(_refused_left - delta, 0.0)
	var unlocked: Array[String] = []
	var locked: Array[String] = []
	for id: String in _game_state.skills:
		if _game_state.skills[id]:
			unlocked.append(id)
		else:
			locked.append(id)
	var flick_unlocked: bool = _game_state.has_skill("sauce_flick")
	var cooldown: float = player.sauce_cooldown_left() if player != null else 0.0
	var sauce_line: String = "Sauce: %d / %d    Sodium: %d / %d" % [
		_game_state.sauce, _game_state.MAX_SAUCE, _game_state.sodium, _game_state.MAX_SODIUM]
	if _refused_left > 0.0:
		sauce_line += "   << NOT ENOUGH SAUCE >>"
	var lines: Array[String] = [
		"Hearts: %s / %s  (%d / %d half-hearts)" % [
			format_hearts(_game_state.hearts), format_hearts(_game_state.MAX_HEARTS),
			_game_state.hearts, _game_state.MAX_HEARTS],
		_coat_line(),
		_container_line(),
		sauce_line,
		"Sauce type: %s    Flick: %s    Cooldown: %.2f s" % [
			_game_state.sauce_type_id, "unlocked" if flick_unlocked else "locked", cooldown],
		"Skills: " + " ".join(unlocked),
		"Locked: " + " ".join(locked),
		"State: " + (player.state_name() if player != null else "-"),
		"Checkpoint: " + (_game_state.checkpoint_id if _game_state.checkpoint_id != "" else "-"),
		_fried_line(),
		"",
		"A/D move  Space jump  S drop-through / stomp  Shift roll / slam  W use steamer  Mouse1 / X sauce",
	]
	if _game_state.popup_open():
		lines.insert(0, tr("POPUP: Your %s is full - use %s now or drop it? (see the popup)") % [
			_game_state.container_name(), _game_state.popup_item_id])
	if OS.is_debug_build():
		lines.append("1 unlock roll+slam  2 relock + clear inventory  3 respawn dummies, items, oil  4 -1 heart  5 unlock flick  6 defeat noodle dummy  7 give container")
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
	var whole: int = half_hearts / 2
	return "%d.5" % whole if half_hearts % 2 == 1 else "%d" % whole
