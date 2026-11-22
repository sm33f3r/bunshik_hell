extends "res://tests/base_test.gd"
## Task 3a-fix: the prologue set is the real-size table times the world scale, and the exit is a
## forearm that blocks the way until the 30th stab. No scene: the set builds without a tree.

const DataScript := preload("res://prologue/prologue_data.gd")
const SetScript := preload("res://prologue/prologue_set.gd")
const ActorScript := preload("res://prologue/prologue_actor.gd")
const DirectorScript := preload("res://prologue/prologue_director.gd")
const GameStateScript := preload("res://systems/game_state.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")
const Layers := preload("res://systems/layers.gd")

const TOLERANCE: float = 0.02 # 2 %

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func _data() -> DataScript:
	return load("res://data/prologue/prologue.tres") as DataScript


func _built_set() -> SetScript:
	var set_node: SetScript = SetScript.new()
	_nodes.append(set_node)
	set_node.build(_data())
	return set_node


func _near(actual: float, real_cm: float, what: String) -> void:
	var expected: float = real_cm * _data().m_per_cm()
	check(absf(actual - expected) <= expected * TOLERANCE + 0.001,
		"%s: %.3f m, expected %.3f m (= %.2f real cm)" % [what, actual, expected, real_cm])


func test_the_table_holds_the_real_starting_values() -> void:
	var d: Variant = _data().dims()
	check_eq(d.counter_top_height_cm, 75.0, "counter top 75 cm")
	check_eq(d.counter_depth_cm, 40.0, "counter depth 40 cm")
	check_eq(d.cup_height_cm, 9.0, "cup 9 cm tall")
	check_eq(d.cup_width_cm, 7.0, "cup 7 cm wide")
	check_eq(d.pick_length_cm, 7.0, "pick 7 cm long")
	check_eq(d.pick_thickness_cm, 0.3, "pick 0.3 cm thick")
	check_eq(d.plate_width_cm, 15.0, "plate 15 cm")
	check_eq(d.mandu_width_cm, 5.0, "만두 5 cm")
	check_eq(d.napkin_box_cm, Vector3(12.0, 10.0, 8.0), "napkin box 12 x 10 x 8 cm")
	check_eq(d.spoon_holder_height_cm, 12.0, "수저통 12 cm tall")
	check_eq(d.stool_seat_width_cm, 35.0, "stool seat 35 cm")
	check_eq(d.hand_length_cm, 19.0, "hand 19 cm")
	check_eq(d.mouth_width_cm, 5.0, "mouth 5 cm")


func test_every_prop_is_its_real_size_times_the_scale() -> void:
	var set_node: SetScript = _built_set()
	var d: Variant = _data().dims()
	var cup: Node3D = set_node.get_node("Props/Cup") as Node3D
	var cup_size: Vector3 = SetScript.mesh_size(cup, ["Sauce", "Stripe"] as Array[String])
	_near(cup_size.y, d.cup_height_cm, "cup height")
	_near(cup_size.x, d.cup_width_cm, "cup width")
	var plate_size: Vector3 = SetScript.mesh_size(set_node.get_node("Props/Plate") as Node3D)
	_near(plate_size.x, d.plate_width_cm, "plate width")
	var napkin: Vector3 = SetScript.mesh_size(set_node.get_node("Props/NapkinBox") as Node3D, ["Slot"] as Array[String])
	_near(napkin.x, d.napkin_box_cm.x, "napkin box width")
	_near(napkin.y, d.napkin_box_cm.y, "napkin box height")
	_near(napkin.z, d.napkin_box_cm.z, "napkin box depth")
	var holder: Vector3 = SetScript.mesh_size(set_node.get_node("Props/SpoonHolder") as Node3D,
		["Utensil0", "Utensil1", "Utensil2"] as Array[String])
	_near(holder.y, d.spoon_holder_height_cm, "수저통 height")
	var seat: Vector3 = SetScript.mesh_size(set_node.get_node("Level/Stool_0") as Node3D, ["Leg"] as Array[String])
	_near(seat.x, d.stool_seat_width_cm, "stool seat width")
	var counter: Vector3 = SetScript.mesh_size(set_node.get_node("Level/Counter") as Node3D)
	_near(counter.y, d.counter_top_height_cm, "counter top height")
	_near(counter.z, d.counter_depth_cm, "counter depth")
	_near(counter.x, d.counter_length_cm, "counter length")
	var table: Vector3 = SetScript.mesh_size(set_node.get_node("Level/NextTable") as Node3D)
	_near(table.x, d.next_table_length_cm, "next table length")
	check(absf((set_node.get_node("Level/NextTable") as Node3D).position.y + table.y * 0.5 - _data().counter_top_y) < 0.001,
		"the next table's top is exactly as high as her counter")


func test_the_pick_the_hand_and_the_mouth_are_real_size_too() -> void:
	var data: DataScript = _data()
	var d: Variant = data.dims()
	var actor: ActorScript = ActorScript.new()
	_nodes.append(actor)
	actor.build(data)
	var pick: Vector2 = actor.pick_size()
	_near(pick.x, d.pick_length_cm, "pick length")
	check(absf(pick.y - d.pick_thickness_cm * data.m_per_cm()) < 0.002, "pick thickness %.3f m" % pick.y)
	_near(actor.hand_length_m(), d.hand_length_cm, "hand length (fingertip to wrist)")
	_near(actor.mouth_node().measured_width_m(), d.mouth_width_cm, "mouth (lips) width")
	_near(actor.mouth_node().open_gap_m, d.mouth_open_cm, "mouth opening")


func test_the_mandu_is_its_real_size_too() -> void:
	var data: DataScript = _data()
	var width: float = data.dims().mandu_width_cm * data.m_per_cm()
	var mandu: Node3D = (load("res://enemies/mandu.tscn") as PackedScene).instantiate() as Node3D
	_nodes.append(mandu)
	mandu.call("configure", width, data.dims().mandu_height_fraction)
	var box: BoxShape3D = (mandu.get_node("CollisionShape3D") as CollisionShape3D).shape as BoxShape3D
	_near(box.size.x, data.dims().mandu_width_cm, "만두 collision width")
	var body: Vector3 = SetScript.mesh_size(mandu.get_node("Visual") as Node3D, ["Seam"] as Array[String])
	_near(body.x, data.dims().mandu_width_cm, "만두 body width")


func test_the_props_on_her_counter_are_solid() -> void:
	var set_node: SetScript = _built_set()
	for path: String in ["Props/Cup", "Props/Plate", "Props/NapkinBox", "Props/SpoonHolder", "Level/Counter", "Level/NextTable", "Level/Floor"]:
		var body: StaticBody3D = set_node.get_node(path) as StaticBody3D
		check(body != null, "%s is a StaticBody3D" % path)
		if body != null:
			check_eq(body.collision_layer, Layers.WORLD, "%s is on the world layer" % path)
			check((body.get_node("CollisionShape3D") as CollisionShape3D).shape != null, "%s has a shape" % path)


func test_the_cup_can_be_stood_on_with_the_existing_jump() -> void:
	# His jump lifts his feet this high (v^2 / 2g): the cup's rim and the napkin box are reachable.
	var tuning: MovementTuningScript = load("res://data/movement_tuning.tres") as MovementTuningScript
	var jump_height: float = tuning.jump_velocity * tuning.jump_velocity / (2.0 * tuning.gravity)
	var data: DataScript = _data()
	check(data.cup_top_y - data.counter_top_y < jump_height, "the cup's rim is below a jump (%.2f < %.2f)" % [data.cup_top_y - data.counter_top_y, jump_height])
	check(data.cm(data.dims().napkin_box_cm.y) < jump_height, "so is the napkin box top")


func test_the_gap_to_the_next_table_is_jumpable_with_the_existing_jump() -> void:
	var tuning: MovementTuningScript = load("res://data/movement_tuning.tres") as MovementTuningScript
	var data: DataScript = _data()
	var apex: float = tuning.jump_velocity / tuning.gravity
	var peak: float = tuning.jump_velocity * tuning.jump_velocity / (2.0 * tuning.gravity)
	var fall: float = sqrt(2.0 * peak / (tuning.gravity * tuning.fall_gravity_scale))
	var reach: float = tuning.max_speed * (apex + fall) # a full running jump across level ground
	var gap: float = data.next_table_min_x - data.counter_length_m
	check(absf(gap - data.cm(data.dims().next_table_gap_cm)) < 0.0001, "the gap comes from the table")
	check(gap > 1.0, "a real gap (%.2f m)" % gap)
	check(gap < reach * 0.8, "jumpable with room to spare: gap %.2f m, reach %.2f m" % [gap, reach])


func test_the_forearm_blocks_the_way_until_the_exit_opens() -> void:
	var set_node: SetScript = _built_set()
	var d: DirectorScript = DirectorScript.new(_data(), GameStateScript.new())
	_nodes.append(d.gs)
	d.exit_opened.connect(func() -> void: set_node.set_exit_open(true))
	check(set_node.forearm_blocking(), "her forearm lies across the counter at the start")
	check(set_node.forearm_visible(), "and you can see it")
	var wall: CollisionShape3D = set_node.get_node("Exit/Forearm/CollisionShape3D") as CollisionShape3D
	check(not wall.disabled, "it is solid")
	check(((wall.shape as BoxShape3D).size.y) > 10.0, "and too tall to jump over")
	d.gs.prologue_intro_seen = true
	d.begin()
	d.debug_free()
	d.player_x = 5.0
	d.player_bottom_y = 13.0
	d.debug_set_count(2)
	for i: int in 240:
		d.step(1.0 / 60.0)
	check(not d.exit_open, "before the 30th stab the exit is closed")
	check(set_node.forearm_blocking(), "so the forearm still blocks the way")
	d.debug_set_count(29)
	for i: int in 2400:
		d.step(1.0 / 60.0)
		if d.exit_open:
			break
	check(d.exit_open, "the 30th stab opened the exit")
	check(not set_node.forearm_blocking(), "she yanked the forearm away: the way is open")


func test_the_forearm_is_yanked_away_over_time_and_comes_back_on_restart() -> void:
	var set_node: SetScript = _built_set()
	set_node.set_exit_open(true)
	set_node._process(0.1)
	check(set_node.forearm_visible(), "still being yanked")
	set_node._process(_data().forearm_yank_s)
	check(not set_node.forearm_visible(), "gone")
	set_node.set_exit_open(false)
	check(set_node.forearm_blocking() and set_node.forearm_visible(), "back across the counter after a restart")


func test_the_old_raised_table_and_stuck_pick_are_gone() -> void:
	var set_node: SetScript = _built_set()
	check(set_node.get_node_or_null("Level/StuckPick") == null and set_node.get_node_or_null("StuckPick") == null, "no stuck pick")
	var data: DataScript = _data()
	check_eq(data.next_table_top_y, data.counter_top_y, "the next table is the same height as her counter")


func test_plate_spawn_points_stand_on_the_plate() -> void:
	var set_node: SetScript = _built_set()
	var data: DataScript = _data()
	var points: Array[Vector3] = set_node.plate_spawn_points(3)
	check_eq(points.size(), 3, "three live 만두")
	var half: float = data.dims().plate_width_cm * data.m_per_cm() * 0.5
	for p: Vector3 in points:
		check(absf(p.x - data.plate_x) < half, "on the plate")
		check(p.y > data.counter_top_y, "above the counter")
