extends "res://tests/base_test.gd"

const MovementTuningScript := preload("res://player/movement_tuning.gd")
const TUNING_PATH: String = "res://data/movement_tuning.tres"

## Every field the task asks for, by name.
const REQUIRED: Array[String] = [
	"max_speed", "acceleration", "friction", "gravity", "jump_velocity", "short_hop_cut",
	"coyote_time", "buffer_time", "stomp_speed", "roll_speed", "roll_duration", "slam_speed",
	"slam_radius", "i_frame_time", "knockback_horizontal", "knockback_vertical",
]


func test_loads_as_movement_tuning() -> void:
	var t: MovementTuningScript = load(TUNING_PATH) as MovementTuningScript
	check(t != null, "movement_tuning.tres loads as MovementTuning")


func test_every_field_is_set() -> void:
	var t: MovementTuningScript = load(TUNING_PATH) as MovementTuningScript
	check_eq(t.unset_fields(), [] as Array[String], "fields still at 0 in the .tres")


func test_required_fields_exist_and_are_positive() -> void:
	var t: MovementTuningScript = load(TUNING_PATH) as MovementTuningScript
	for field: String in REQUIRED:
		var value: Variant = t.get(field)
		check(value is float, "%s exists and is a float" % field)
		if value is float:
			check(value > 0.0, "%s is positive" % field)


func test_unset_fields_detects_a_fresh_resource() -> void:
	var fresh: MovementTuningScript = MovementTuningScript.new()
	check(fresh.unset_fields().size() >= REQUIRED.size(), "a fresh resource reports unset fields")
	check("max_speed" in fresh.unset_fields(), "max_speed reported unset on a fresh resource")


func test_sane_relationships() -> void:
	var t: MovementTuningScript = load(TUNING_PATH) as MovementTuningScript
	check(t.short_hop_cut < 1.0, "short hop cut shrinks the jump")
	check(t.stomp_speed > t.max_speed, "stomp is faster than running")
	check(t.slam_speed >= t.stomp_speed, "slam is at least as fast as stomp")
	check(t.respawn_delay < 2.0, "respawn stays under 2 s")
