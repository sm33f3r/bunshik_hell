extends "res://tests/base_test.gd"
## Task 3b-ii: the 김밥 slice train as data and rules: gimbap.tres, the reaction row for every attack,
## spill and break_line, the line that follows its leader, death and drops. The train is put into the
## scene tree (its slices are built in _ready) but nothing here waits for physics frames: the AI is
## driven by hand.

const TrainScene: PackedScene = preload("res://enemies/gimbap_train.tscn")
const EnemyDefScript := preload("res://enemies/enemy_def.gd")
const EnemyBaseScript := preload("res://enemies/enemy_base.gd")
const ReactionTableScript := preload("res://systems/reaction_table.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")

const DT: float = 1.0 / 60.0

var _nodes: Array[Object] = []


func after_each() -> void:
	for node: Object in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _def() -> EnemyDefScript:
	return load("res://data/enemies/gimbap.tres") as EnemyDefScript


func _train(count: int = 0) -> Node3D:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	var train: Node3D = TrainScene.instantiate() as Node3D
	train.set("slice_count", count)
	train.set("m_per_cm", 0.1745)
	tree.root.add_child(train)
	_nodes.append(train)
	for slice: Node3D in train.get("slices"):
		slice.set("game_state", gs)
	return train


func _slice(train: Node3D, index: int) -> Node3D:
	return (train.get("slices") as Array)[index] as Node3D


func test_gimbap_tres_holds_every_number() -> void:
	var def: EnemyDefScript = _def()
	check_eq(def.id, "gimbap", "id")
	check_eq(def.material, "segmented", "its own material row")
	check(def.max_hp >= 2, "a slice takes a couple of hits")
	check_eq(def.contact_damage_half_hearts, 2, "contact: 1 heart")
	check(def.walk_speed_mps > 0.0, "marching speed")
	check(def.slice_size_cm > 0.0 and def.slice_thickness_cm > 0.0 and def.slice_gap_cm >= 0.0, "slice size, thickness, gap")
	check(def.train_slices >= 3, "a line of slices (%d)" % def.train_slices)
	check(def.scatter_speed_mps > 0.0 and def.scatter_hop_mps > 0.0, "scatter speed and hop")
	check(def.spill_patch_width_cm > 0.0 and def.spill_patch_lifetime_s > 0.0 and def.spill_cooldown_s > 0.0, "the spill patch: width, life, cooldown")
	var kinds: Array[String] = []
	for entry in def.drops:
		kinds.append(entry.kind)
	check(kinds.has("sesame_oil"), "sometimes a 참기름 drop, through the existing drop system")
	check(EnemyBaseScript.DROP_SCENES.has("sesame_oil"), "which the drop table can spawn")


func test_the_reaction_row_for_every_attack() -> void:
	var table: ReactionTableScript = load("res://data/reaction_table.tres") as ReactionTableScript
	var expect: Dictionary = {
		"landing": "spill", "stomp": "damage", "roll": "break_line", "slam": "kill",
		"sauce": "damage", "heavy_object": "kill", "water": "absorb", "foot": "kill",
	}
	for attack: String in expect:
		var cell: Array[Dictionary] = table.lookup_all(attack, "segmented")
		check_eq(cell.size(), 1, "%s: one reaction" % attack)
		check_eq(cell[0]["reaction"], expect[attack], "%s x segmented" % attack)
	check(table.lookup("stomp", "segmented")["damage"] > 0, "a stomp hurts")
	check(table.lookup("sauce", "segmented")["damage"] > 0, "sauce hurts")
	check_eq(ReactionTableScript.REACTION_SPILL, "spill", "the new reaction names")
	check_eq(ReactionTableScript.REACTION_BREAK_LINE, "break_line", "break_line")


func test_a_train_is_a_line_led_by_the_uncut_end_piece() -> void:
	var train: Node3D = _train()
	var slices: Array = train.get("slices")
	check_eq(slices.size(), _def().train_slices, "the number of slices comes from the data")
	check((slices[0] as Node3D).get("is_end_piece"), "the first is the uncut end piece (꼬다리)")
	for i: int in range(1, slices.size()):
		check(not (slices[i] as Node3D).get("is_end_piece"), "slice %d is a plain slice" % i)
		check_eq((slices[i] as Node3D).get("train"), train, "slice %d belongs to the train" % i)
	var spacing: float = train.get("spacing_m")
	check(absf((slices[0] as Node3D).position.x - (slices[1] as Node3D).position.x - spacing) < 0.001, "evenly spaced behind the leader")
	check((slices[0] as Node3D).position.x > (slices[1] as Node3D).position.x, "behind it, against the way it walks")
	check_eq(_train(3).get("slices").size(), 3, "a spawn can ask for another length")


func test_each_slice_is_its_own_enemy_body() -> void:
	var train: Node3D = _train()
	for slice: Node3D in train.get("slices"):
		check(slice is CharacterBody3D and slice.is_in_group("enemies"), "%s is an enemy body" % slice.name)
		check_eq(slice.get("hp"), _def().max_hp, "with its own health")
		check_eq(slice.call("contact_damage"), 2, "and its own 1-heart contact")
	var first: Node3D = _slice(train, 0)
	var other: Node3D = _slice(train, 1)
	first.call("receive_attack", "stomp", 1.0)
	check(int(first.get("hp")) < _def().max_hp and int(other.get("hp")) == _def().max_hp, "hurting one does not hurt the others")


func test_landing_spills_a_slippery_patch_once_per_cooldown() -> void:
	var train: Node3D = _train()
	var slice: Node3D = _slice(train, 1)
	var before: int = tree.get_nodes_in_group("slippery_patches").size()
	var result: Dictionary = slice.call("receive_attack", "landing", 1.0)
	check_eq(result["reaction"], "spill", "landing: spill")
	check(slice.get("alive"), "the slice survives it")
	check_eq(tree.get_nodes_in_group("slippery_patches").size(), before + 1, "a patch is left")
	slice.call("receive_attack", "landing", 1.0)
	check_eq(tree.get_nodes_in_group("slippery_patches").size(), before + 1, "a second landing right away does not stack another")
	check_eq(slice.get("spills"), 1, "one spill")
	slice.set("spill_cooldown", 0.0)
	slice.call("receive_attack", "landing", 1.0)
	check_eq(slice.get("spills"), 2, "after the cooldown it spills again")
	for patch: Node in tree.get_nodes_in_group("slippery_patches"):
		patch.free()


func test_the_patch_matches_the_data_and_dries_up() -> void:
	var train: Node3D = _train()
	var slice: Node3D = _slice(train, 0)
	slice.call("receive_attack", "landing", 1.0)
	var patches: Array[Node] = tree.get_nodes_in_group("slippery_patches")
	check_eq(patches.size(), 1, "one patch")
	var patch: Area3D = patches[0] as Area3D
	check(absf(float(patch.get("width_m")) - _def().spill_patch_width_cm * 0.1745) < 0.01, "as wide as the data says")
	check_eq(float(patch.get("lifetime_s")), _def().spill_patch_lifetime_s, "and lasts as long")
	patch.set("age", _def().spill_patch_lifetime_s - 0.01)
	patch.call("_physics_process", 0.02)
	check(patch.is_queued_for_deletion(), "it dries up")
	patch.free()


func test_a_slippery_patch_makes_the_player_slide() -> void:
	var tuning: MovementTuningScript = load("res://data/movement_tuning.tres") as MovementTuningScript
	check(tuning.slip_acceleration_scale > 0.0 and tuning.slip_acceleration_scale < 1.0, "less grip when speeding up")
	check(tuning.slip_friction_scale > 0.0 and tuning.slip_friction_scale < tuning.slip_acceleration_scale, "and much less when braking")
	check(tuning.slip_linger_s > 0.0, "the slide lingers a moment")
	check(tuning.unset_fields().is_empty(), "no tuning field is left unset: " + str(tuning.unset_fields()))
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	var player: CharacterBody3D = (load("res://player/ddeok.tscn") as PackedScene).instantiate() as CharacterBody3D
	player.set("game_state", gs)
	tree.root.add_child(player)
	_nodes.append(player)
	gs.unlock_skill("jump")
	player.set("grounded", true)
	player.set("velocity", Vector3(tuning.max_speed, 0.0, 0.0))
	player.call("_step_free", DT, 0.0)
	var braked_normal: float = (player.get("velocity") as Vector3).x
	player.set("velocity", Vector3(tuning.max_speed, 0.0, 0.0))
	player.call("apply_slip", 1.0)
	player.call("_step_free", DT, 0.0)
	var braked_slippery: float = (player.get("velocity") as Vector3).x
	check(braked_slippery > braked_normal + 0.1, "on the patch he brakes slower (%.2f vs %.2f m/s after one tick)" % [braked_slippery, braked_normal])
	player.set("velocity", Vector3.ZERO)
	player.call("_step_free", DT, 1.0)
	var started_slippery: float = (player.get("velocity") as Vector3).x
	player.set("slip_left", 0.0)
	player.set("velocity", Vector3.ZERO)
	player.call("_step_free", DT, 1.0)
	var started_normal: float = (player.get("velocity") as Vector3).x
	check(started_slippery < started_normal * 0.6, "and speeds up slower (%.2f vs %.2f)" % [started_slippery, started_normal])


func test_a_roll_breaks_the_line_into_single_slices() -> void:
	var train: Node3D = _train()
	var slices: Array = (train.get("slices") as Array).duplicate()
	var broke: Array[bool] = []
	train.connect("line_broken", func() -> void: broke.append(true))
	var result: Dictionary = (slices[2] as Node3D).call("receive_attack", "roll", 1.0)
	check_eq(result["reaction"], "break_line", "roll: break_line")
	check(train.get("broken"), "the train is broken")
	check_eq(broke.size(), 1, "announced once")
	var directions: Array[float] = []
	for slice: Node3D in slices:
		check(slice.get("alive"), "%s is still alive: they can be picked off one by one" % slice.name)
		check(slice.get("train") == null, "%s walks on its own now" % slice.name)
		check(float(slice.get("velocity").y) > 0.0, "%s hopped out" % slice.name)
		directions.append(slice.get("_dir"))
	check(directions.has(1.0) and directions.has(-1.0), "they scatter both ways")
	(slices[0] as Node3D).call("receive_attack", "roll", 1.0)
	check_eq(broke.size(), 1, "a second roll does not break it again")


func test_a_broken_slice_is_picked_off_with_stomps() -> void:
	var train: Node3D = _train()
	var slice: Node3D = _slice(train, 0)
	slice.call("receive_attack", "roll", 1.0)
	var hits: int = 0
	while slice.get("alive") and hits < 10:
		slice.call("receive_attack", "stomp", 1.0)
		hits += 1
	check(not slice.get("alive"), "dead after %d stomps" % hits)
	check_eq(hits, _def().max_hp, "as many stomps as its health")
	for other: int in range(1, _def().train_slices):
		check(_slice(train, other).get("alive"), "slice %d is untouched" % other)


func test_a_slam_kills_a_slice_and_a_heavy_object_too() -> void:
	var train: Node3D = _train()
	var slam_result: Dictionary = _slice(train, 1).call("receive_attack", "slam", 1.0)
	check_eq(slam_result["reaction"], "kill", "slam: kill")
	check(slam_result["killed"], "dead at once")
	var heavy: Dictionary = _slice(train, 1).call("receive_attack", "heavy_object", 1.0)
	check(not bool(_slice(train, 1).get("alive")) or heavy["killed"], "heavy object: kill")
	var other: Node3D = _slice(train, 0)
	other.call("receive_attack", "heavy_object", 1.0)
	check(not other.get("alive"), "a heavy object kills the next one too")


func test_sauce_hurts_a_slice() -> void:
	var train: Node3D = _train()
	var slice: Node3D = _slice(train, 2)
	var hp: int = slice.get("hp")
	var result: Dictionary = slice.call("receive_attack", "sauce", 1.0)
	check_eq(result["reaction"], "damage", "sauce: damage")
	check(int(slice.get("hp")) < hp, "it lost health")


func test_a_dead_slice_falls_apart_with_no_collisions() -> void:
	var train: Node3D = _train()
	var slice: Node3D = _slice(train, 1)
	var decor_before: int = tree.get_nodes_in_group("section_decor").size()
	slice.call("receive_attack", "slam", 1.0)
	check_eq((slice as CharacterBody3D).collision_layer, 0, "no collisions")
	check(not slice.visible, "the slice itself is gone")
	var decor: Array[Node] = tree.get_nodes_in_group("section_decor")
	check(decor.size() >= decor_before + 3, "small pieces scatter (%d)" % (decor.size() - decor_before))
	for piece: Node in decor:
		check(piece is MeshInstance3D, "the pieces are only pictures")
	for piece: Node in decor:
		piece.free()


func test_the_leader_dying_hands_the_lead_to_the_next_slice() -> void:
	var train: Node3D = _train()
	var first: Node3D = _slice(train, 0)
	var second: Node3D = _slice(train, 1)
	first.call("receive_attack", "slam", 1.0)
	check_eq(train.call("leader"), second, "the next slice leads")
	check_eq((train.get("slices") as Array).size(), _def().train_slices - 1, "the line closed up")


func test_every_slice_dead_clears_the_train() -> void:
	var train: Node3D = _train(2)
	var cleared: Array[bool] = []
	train.connect("cleared", func() -> void: cleared.append(true))
	for slice: Node3D in (train.get("slices") as Array).duplicate():
		slice.call("receive_attack", "slam", 1.0)
	check_eq(cleared.size(), 1, "the train is cleared")
	check(train.call("leader") == null, "no leader")


func test_followers_walk_the_leaders_path_so_the_line_turns_like_a_snake() -> void:
	var train: Node3D = _train(3)
	var spacing: float = train.get("spacing_m")
	var slices: Array = train.get("slices")
	# Hand-driven: no physics, so move the bodies ourselves the way move_and_slide would.
	var lead: Node3D = slices[0]
	var xs: Array[float] = [0.0, 0.0, 0.0]
	for i: int in 3:
		(slices[i] as Node3D).position = Vector3(-float(i) * spacing, 0.0, 0.0)
	var dir: float = 1.0
	for tick: int in 600:
		for slice: Node3D in slices:
			slice.call("_ai", DT)
		# The leader walks to x = 6 and then turns (a wall): set its direction like the AI would.
		if lead.position.x >= 6.0:
			train.set("leader_dir", -1.0)
			dir = -1.0
		for slice: Node3D in slices:
			slice.position += Vector3((slice.get("velocity") as Vector3).x * DT, 0.0, 0.0)
		if tick == 120:
			for i: int in 3:
				xs[i] = (slices[i] as Node3D).position.x
	check(lead.position.x < 6.5, "the leader turned at its wall (x %.2f)" % lead.position.x)
	check(dir == -1.0, "it did turn")
	check((slices[1] as Node3D).position.x <= 6.0 + 0.2, "the second slice did not walk past the turning point (x %.2f)" % (slices[1] as Node3D).position.x)
	check((slices[2] as Node3D).position.x <= 6.0 + 0.2, "nor the third (x %.2f)" % (slices[2] as Node3D).position.x)
	check(absf(((slices[0] as Node3D).position.x - (slices[1] as Node3D).position.x)) < spacing * 3.0, "the line stays together")
	check(xs[0] > xs[1] and xs[1] > xs[2], "in order, leader first, at mid-run (%s)" % str(xs))


func test_a_death_drops_sesame_oil_through_the_drop_system() -> void:
	var gs: GameStateScript = GameStateScript.new()
	_nodes.append(gs)
	gs.drops.rng.seed = 11
	var oil: int = 0
	var kills: int = 0
	for i: int in 12:
		var train: Node3D = _train(2)
		for slice: Node3D in train.get("slices"):
			slice.set("game_state", gs)
		var victim: Node3D = _slice(train, 0)
		victim.call("receive_attack", "slam", 1.0)
		kills += 1
		for drop: Dictionary in victim.get("last_drops"):
			if drop["kind"] == "sesame_oil":
				oil += 1
	check(oil > 0, "sometimes a 참기름 drop")
	check(oil < kills, "not every time (%d of %d)" % [oil, kills])
	for node: Node in tree.get_nodes_in_group("dropped_loot"):
		node.free()
