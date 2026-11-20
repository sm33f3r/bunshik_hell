class_name DropRoller
extends RefCounted
## Rolls enemy drops. Seedable (rng.seed) so tests are deterministic.
## Rule: each drop entry rolls its own chance. After `def.drop_guarantee_after` kills in a row
## of one enemy TYPE (its def id) that dropped nothing, the next kill is guaranteed to drop
## (the entry with the highest chance; the first one on a tie). Types with no entries never drop.

const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const DropEntryScript := preload("res://systems/drop_entry.gd")

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## def id -> kills in a row that dropped nothing.
var _dry_kills: Dictionary[String, int] = {}


func _init() -> void:
	rng.randomize()


## Forget every bad-luck streak.
func reset() -> void:
	_dry_kills.clear()


func dry_kills(enemy_id: String) -> int:
	return _dry_kills.get(enemy_id, 0)


## One kill of this enemy type. Returns [{"kind": String, "amount": int}, ...] (maybe empty).
func roll(def: EnemyDefScript) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if def == null or def.drops.is_empty():
		return out
	var entries: Array[DropEntryScript] = []
	for entry: DropEntryScript in def.drops:
		if entry != null and entry.amount > 0:
			entries.append(entry)
	if entries.is_empty():
		return out
	for entry: DropEntryScript in entries:
		if rng.randf() < entry.chance:
			out.append({"kind": entry.kind, "amount": entry.amount})
	if out.is_empty() and dry_kills(def.id) >= def.drop_guarantee_after:
		var best: DropEntryScript = entries[0]
		for entry: DropEntryScript in entries:
			if entry.chance > best.chance:
				best = entry
		out.append({"kind": best.kind, "amount": best.amount})
	if out.is_empty():
		_dry_kills[def.id] = dry_kills(def.id) + 1
	else:
		_dry_kills[def.id] = 0
	return out
