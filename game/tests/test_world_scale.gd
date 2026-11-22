extends "res://tests/base_test.gd"
## Task 3a-fix: the world grows around Ddeok Dude. His own size is measured, never changed.

const WorldScaleScript := preload("res://systems/world_scale.gd")
const DataScript := preload("res://prologue/prologue_data.gd")
const MovementTuningScript := preload("res://player/movement_tuning.gd")


func test_the_resource_holds_the_starting_value() -> void:
	var scale_data: WorldScaleScript = load("res://data/world_scale.tres") as WorldScaleScript
	check(scale_data != null, "world_scale.tres loads")
	check_eq(scale_data.real_ddeok_length_cm, 5.5, "a 떡볶이 떡 is 5.5 cm")


func test_ddeok_dudes_length_is_measured_from_his_collision_capsule() -> void:
	# He lies on his side: capsule height 0.96 along X (ddeok.tscn). If this fails, his size changed.
	check(absf(WorldScaleScript.measure_ddeok_length_m() - 0.96) < 0.0001,
		"he is 0.96 m long (got %f)" % WorldScaleScript.measure_ddeok_length_m())


func test_game_m_per_real_cm_is_his_length_over_the_real_length() -> void:
	var scale_data: WorldScaleScript = WorldScaleScript.new()
	scale_data.real_ddeok_length_cm = 5.5
	check(absf(scale_data.game_m_per_real_cm(0.96) - 0.96 / 5.5) < 0.000001, "0.96 / 5.5")
	check(absf(scale_data.game_m_per_real_cm() - 0.17454545) < 0.0001, "about 0.1745 m per cm")
	check(absf(scale_data.cm_to_m(75.0) - 13.0909) < 0.01, "a 75 cm counter is about 13.09 m")
	scale_data.real_ddeok_length_cm = 11.0
	check(absf(scale_data.game_m_per_real_cm(0.96) - 0.96 / 11.0) < 0.000001, "a bigger real 떡 shrinks the world")
	check(absf(scale_data.cm_to_m(10.0, 1.1) - 1.0) < 0.000001, "an injected length: 11 cm real, 1.1 m game: 10 cm is 1 m")


func test_the_prologue_data_uses_the_same_scale() -> void:
	var data: DataScript = load("res://data/prologue/prologue.tres") as DataScript
	check(absf(data.m_per_cm() - 0.96 / 5.5) < 0.0001, "PrologueData scale = WorldScale")
	check(absf(data.counter_top_y - 75.0 * data.m_per_cm()) < 0.0001, "counter top = 75 cm x scale")


func test_his_movement_numbers_did_not_change() -> void:
	var tuning: MovementTuningScript = load("res://data/movement_tuning.tres") as MovementTuningScript
	check_eq(tuning.max_speed, 5.5, "max_speed")
	check_eq(tuning.jump_velocity, 11.5, "jump_velocity")
	check_eq(tuning.gravity, 30.0, "gravity")
	check_eq(tuning.fall_gravity_scale, 1.4, "fall_gravity_scale")
	check_eq(tuning.acceleration, 45.0, "acceleration")
