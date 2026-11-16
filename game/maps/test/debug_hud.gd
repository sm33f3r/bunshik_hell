extends CanvasLayer
## Text-only debug HUD for the test room.

const GameStateScript := preload("res://systems/game_state.gd")
const DdeokScript := preload("res://player/ddeok.gd")

@export var player: DdeokScript

var _label: Label
var _game_state: GameStateScript


func _ready() -> void:
	_label = get_node_or_null("Text") as Label
	_game_state = get_node_or_null("/root/GameState") as GameStateScript


func _process(_delta: float) -> void:
	if _label == null or _game_state == null:
		return
	var unlocked: Array[String] = []
	var locked: Array[String] = []
	for id: String in _game_state.skills:
		if _game_state.skills[id]:
			unlocked.append(id)
		else:
			locked.append(id)
	var lines: Array[String] = [
		"Hearts: %s / %s  (%d / %d half-hearts)" % [
			format_hearts(_game_state.hearts), format_hearts(_game_state.MAX_HEARTS),
			_game_state.hearts, _game_state.MAX_HEARTS],
		"Sauce: %d / %d    Sodium: %d / %d" % [
			_game_state.sauce, _game_state.MAX_SAUCE, _game_state.sodium, _game_state.MAX_SODIUM],
		"Skills: " + " ".join(unlocked),
		"Locked: " + " ".join(locked),
		"State: " + (player.state_name() if player != null else "-"),
		"Checkpoint: " + (_game_state.checkpoint_id if _game_state.checkpoint_id != "" else "-"),
		"",
		"A/D move  Space jump  S drop-through / stomp  Shift roll / slam  W use steamer",
	]
	if OS.is_debug_build():
		lines.append("1 unlock roll+slam  2 relock  3 respawn dummies  4 -1 heart")
	_label.text = "\n".join(lines)


## 13 half-hearts -> "6.5", 14 -> "7".
static func format_hearts(half_hearts: int) -> String:
	var whole: int = half_hearts / 2
	return "%d.5" % whole if half_hearts % 2 == 1 else "%d" % whole
