extends "res://tests/base_test.gd"

const ReactionTableScript := preload("res://systems/reaction_table.gd")
const TABLE_PATH: String = "res://data/reaction_table.tres"


func _table() -> ReactionTableScript:
	return load(TABLE_PATH) as ReactionTableScript


func _expect(attack: String, material: String, reaction: String, damage: int) -> void:
	var r: Dictionary = _table().lookup(attack, material)
	check_eq(r["reaction"], reaction, "%s x %s reaction" % [attack, material])
	check_eq(r["damage"], damage, "%s x %s damage" % [attack, material])


func test_table_loads() -> void:
	check(_table() != null, "reaction_table.tres loads as ReactionTable")


func test_soft_entries() -> void:
	_expect("landing", "soft", "damage", 1)
	_expect("stomp", "soft", "kill", 0)
	_expect("roll", "soft", "damage", 1)
	_expect("slam", "soft", "kill", 0)


func test_tall_rigid_entries() -> void:
	_expect("landing", "tall_rigid", "bounce_off", 0)
	_expect("stomp", "tall_rigid", "damage", 1)
	_expect("roll", "tall_rigid", "knock_over", 0)
	_expect("slam", "tall_rigid", "kill", 0)


func test_unknown_pairs_get_a_sensible_default() -> void:
	_expect("landing", "no_such_material", "absorb", 0)
	_expect("no_such_attack", "soft", "absorb", 0)
	_expect("", "", "absorb", 0)


func test_lookup_always_returns_both_keys() -> void:
	var table: ReactionTableScript = ReactionTableScript.new()
	# Malformed entries must fall back to the default, never crash.
	table.entries = {"odd": {"landing": "not a dictionary", "stomp": {"reaction": 5}}}
	for attack: String in ["landing", "stomp", "roll"]:
		var r: Dictionary = table.lookup(attack, "odd")
		check_eq(r["reaction"], "absorb", "malformed %s falls back" % attack)
		check_eq(r["damage"], 0, "malformed %s damage" % attack)
