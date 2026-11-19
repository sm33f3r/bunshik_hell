class_name SauceTypeList
extends Resource
## The ordered list sauce_next / sauce_prev cycle through.

const SauceTypeScript := preload("res://systems/sauce_type.gd")

@export var types: Array[SauceTypeScript] = []


func ids() -> Array[String]:
	var out: Array[String] = []
	for t: SauceTypeScript in types:
		if t != null and t.id != "":
			out.append(t.id)
	return out


## Null for an unknown id.
func find(id: String) -> SauceTypeScript:
	for t: SauceTypeScript in types:
		if t != null and t.id == id:
			return t
	return null
