class_name ReactionTable
extends Resource
## The food-reaction table: attack x material -> one or more {reaction, damage}.
## One Resource, so every enemy reads the same rules. Nothing hardcodes "X kills Y".
## A cell is either one {"reaction", "damage"} Dictionary or an Array of them
## (e.g. fried landing = bounce_off + deteriorate). Both forms work.

const ATTACK_LANDING: String = "landing"
const ATTACK_STOMP: String = "stomp"
const ATTACK_ROLL: String = "roll"
const ATTACK_SLAM: String = "slam"
const ATTACK_SAUCE: String = "sauce"

const REACTION_DAMAGE: String = "damage"
const REACTION_KILL: String = "kill"
const REACTION_BOUNCE_OFF: String = "bounce_off"
const REACTION_KNOCK_OVER: String = "knock_over"
const REACTION_HURT_PLAYER: String = "hurt_player"
## Spec §8.1 "absorb" (no effect). Also the answer for any pair the table does not know.
const REACTION_ABSORB: String = "absorb"
## One stage per hit: fresh -> broken -> crumbling -> soggy (soggy = dead).
const REACTION_DETERIORATE: String = "deteriorate"
## Permanently disables the enemy's ranged attack.
const REACTION_JAM: String = "jam"

## material -> attack -> {"reaction": String, "damage": int} or an Array of those
@export var entries: Dictionary = {}


## Every reaction for the pair, in order. Never empty: unknown pairs are [absorb, 0].
## Malformed items are skipped.
func lookup_all(attack: String, material: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var by_attack: Variant = entries.get(material)
	if by_attack is Dictionary:
		var cell: Variant = (by_attack as Dictionary).get(attack)
		if cell is Dictionary:
			_append_valid(out, cell)
		elif cell is Array:
			for item: Variant in cell:
				_append_valid(out, item)
	if out.is_empty():
		out.append({"reaction": REACTION_ABSORB, "damage": 0})
	return out


## The first reaction only: {"reaction": String, "damage": int}. Kept for older callers.
func lookup(attack: String, material: String) -> Dictionary:
	return lookup_all(attack, material)[0]


static func _append_valid(out: Array[Dictionary], item: Variant) -> void:
	if not item is Dictionary:
		return
	var reaction: Variant = (item as Dictionary).get("reaction")
	var damage: Variant = (item as Dictionary).get("damage", 0)
	if reaction is String and damage is int:
		out.append({"reaction": reaction, "damage": damage})
