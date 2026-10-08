extends Node
## 全局旗标 / 皮箱 / 手记 / 香火（对齐 2026-09-27 玩法）

signal flag_changed(flag: String, value: Variant)
signal inventory_changed

const ITEM_NAMES := {
	"photo": "家人照片",
	"form": "回国申请表",
	"matches": "火柴",
	"key": "密室钥匙",
	"lamp": "煤油灯",
	"flashlight": "手电筒",
	"mask_frag": "面具碎片",
}

const HINTS := {
	"key": [
		"钥匙不在这间屋子里。",
		"挂钩上的牌子写了去处。",
		"去管理员桌上找。",
	],
	"seal": [
		"地上画的东西，是有讲究的。",
		"先看中间那个字，再看面具朝着哪边。",
		"中间是「镇」，面具朝内——是镇压，不是驱邪。",
	],
	"clues": [
		"他刚说的，不是自杀。",
		"钉子、合葬。那不是自己寻的死，也不是鬼。",
		"有人把她活着钉进棺材，和死人葬在一起。",
	],
	"mask": [
		"也许该看看墙上的画。",
		"用灯照那幅画，记住摆法。",
		"上 → 下 → 左 → 右 → 左上 → 右上 → 中。",
	],
}

var flags: Dictionary = {}
var items: Dictionary = {}
var notes: Array[String] = []
var incense: int = 3
var puzzle_id: String = ""
var hint_used: Dictionary = {}
var first_ghost_catch: bool = true


func reset() -> void:
	flags.clear()
	items.clear()
	notes.clear()
	incense = 3
	puzzle_id = ""
	hint_used.clear()
	first_ghost_catch = true
	inventory_changed.emit()


func set_flag(flag: String, value: Variant = true) -> void:
	flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag: String, default: Variant = false) -> Variant:
	return flags.get(flag, default)


func has_flag(flag: String) -> bool:
	return bool(flags.get(flag, false))


func add_item(id: String, amount: int = 1) -> void:
	items[id] = int(items.get(id, 0)) + amount
	inventory_changed.emit()


func has_item(id: String) -> bool:
	return int(items.get(id, 0)) > 0


func item_count(id: String) -> int:
	return int(items.get(id, 0))


func bag_text() -> String:
	var parts: Array[String] = []
	for id in items:
		var n: int = int(items[id])
		if n <= 0:
			continue
		var label: String = str(ITEM_NAMES.get(id, id))
		if id == "mask_frag":
			parts.append("%s %d/7" % [label, n])
		elif n > 1:
			parts.append("%s ×%d" % [label, n])
		else:
			parts.append(label)
	if parts.is_empty():
		return "皮箱：身上没有东西。"
	return "皮箱：" + " · ".join(PackedStringArray(parts))


func add_note(text: String) -> void:
	if text in notes:
		return
	notes.append(text)


func use_hint() -> String:
	if puzzle_id == "" or not HINTS.has(puzzle_id):
		return "此刻没有可问的。"
	if incense <= 0:
		return "香不够了。"
	var n: int = int(hint_used.get(puzzle_id, 0))
	var lines: Array = HINTS[puzzle_id]
	if n >= lines.size():
		return "她没有再说了。"
	incense -= 1
	hint_used[puzzle_id] = n + 1
	inventory_changed.emit()
	return str(lines[n])
