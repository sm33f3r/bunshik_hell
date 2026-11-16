class_name ReactionTable
extends Resource
## The food-reaction table: attack x material -> {reaction, damage}.
## One Resource, so every enemy reads the same rules. Nothing hardcodes "X kills Y".

const ATTACK_LANDING: String = "landing"
const ATTACK_STOMP: String = "stomp"
const ATTACK_ROLL: String = "roll"
const ATTACK_SLAM: String = "slam"

const REACTION_DAMAGE: String = "damage"
const REACTION_KILL: String = "kill"
const REACTION_BOUNCE_OFF: String = "bounce_off"
const REACTION_KNOCK_OVER: String = "knock_over"
const REACTION_HURT_PLAYER: String = "hurt_player"
## Spec §8.1 "absorb" (no effect). Also the answer for any pair the table does not know.
const REACTION_ABSORB: String = "absorb"

## material -> attack -> {"reaction": String, "damage": int}
@export var entries: Dictionary = {}


## Always returns {"reaction": String, "damage": int}. Unknown material or attack: absorb, 0.
func lookup(attack: String, material: String) -> Dictionary:
	var by_attack: Variant = entries.get(material)
	if by_attack is Dictionary:
		var entry: Variant = (by_attack as Dictionary).get(attack)
		if entry is Dictionary:
			var reaction: Variant = (entry as Dictionary).get("reaction")
			var damage: Variant = (entry as Dictionary).get("damage", 0)
			if reaction is String and damage is int:
				return {"reaction": reaction, "damage": damage}
	return {"reaction": REACTION_ABSORB, "damage": 0}
