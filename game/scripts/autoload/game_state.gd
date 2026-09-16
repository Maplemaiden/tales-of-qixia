extends Node
## 全局旗标 / Demo 进度（灰盒）

signal flag_changed(flag: String, value: Variant)

var flags: Dictionary = {}

func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)

func get_flag(flag: String, default: Variant = false) -> Variant:
	return flags.get(flag, default)

func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))
