extends Resource
## Her lines, exactly as written by NHMH (Korean only). Do not "fix" spelling, spacing or
## punctuation here: they are NHMH's text.

@export var opening: String = ""
@export var stage_1_enter: String = ""
@export var stage_1_later: String = ""
@export var stage_2_enter: String = ""
@export var stage_3_enter: String = ""
@export var mandu_break: String = ""
@export var final_stab: String = ""


## "" for an unknown key.
func get_line(key: String) -> String:
	var value: Variant = get(key)
	return value if value is String else ""
