extends GreyboxLevel
## S1-2 走廊：三异常（红影给方向、镜前摸脸）→ 密室门


var _inspected: Dictionary = {}


func get_room_width() -> float:
	return 1600.0


func _ready() -> void:
	setup_shell(1600.0, "S1-2 · 走廊与楼梯 · 夜")
	add_prop(Vector2(200, 80), Vector2(80, 520), Color("2a2230"), "Pillar1")
	add_prop(Vector2(700, 80), Vector2(80, 520), Color("2a2230"), "Pillar2")
	add_prop(Vector2(400, 140), Vector2(120, 160), Color("4a3a55"), "ManchuWindow")
	add_prop(Vector2(900, 200), Vector2(70, 160), Color("3a3028"), "DoorFrame")
	add_prop(Vector2(1100, 180), Vector2(90, 200), Color("353045"), "Mirror")
	add_label_at(Vector2(1180, 520), "↓ 地下室", Color("a09080"))

	make_interactable("win", "查看·满洲窗", Vector2(420, 420), Vector2(90, 100), Color("6a5080"), true).interacted.connect(_on_win)
	make_interactable("door_empty", "查看·自开门", Vector2(900, 420), Vector2(70, 100), Color("705040"), true).interacted.connect(_on_door_empty)
	make_interactable("matches", "拾取·火柴", Vector2(80, 520), Vector2(40, 30), Color("c4a574"), true).interacted.connect(_on_matches)
	make_interactable("mirror", "查看·穿衣镜", Vector2(1110, 420), Vector2(80, 100), Color("506070"), true).interacted.connect(_on_mirror)
	make_interactable("stairs", "下地下室", Vector2(1450, 420), Vector2(80, 140), Color("5a4030"), false).interacted.connect(_on_stairs)

	spawn_player(Vector2(120, 600), false)
	await say([
		"田中：（压低）别怕……可能就是个女人在唱歌。",
		"田中：抓住她，就是功劳。",
	])
	status.text = "调查 0/3 · 满洲窗 / 自开门 / 镜子"


func _mark(id: String) -> void:
	_inspected[id] = true
	GameState.set_flag("1b_%s" % id, true)
	var n := _inspected.size()
	status.text = "调查 %d/3" % n
	if n >= 3:
		status.text = "三处已查 · 右侧下地下室"
		GameState.set_flag("1b_all_inspected", true)


func _on_win(_by: PlayerController) -> void:
	await red_flash()
	await say([
		"（玻璃上有个影子，往楼梯那边去了。再看，什么也没有。）",
		"田中：刚才玻璃上……是不是有个人。",
		"田中：……看错了。",
	])
	_mark("win")
	var w := get_node_or_null("ManchuWindow") as Polygon2D
	if w:
		w.color = Color("2a2035")


func _on_door_empty(_by: PlayerController) -> void:
	await say([
		"田中：这门……刚刚是关着的吧。",
		"没人。灯怎么灭了。",
	])
	_mark("door_empty")


func _on_matches(_by: PlayerController) -> void:
	GameState.add_item("matches")
	await say(["半盒火柴，受了潮。划一根少一根。", "（已收进箱内。）"])


func _on_mirror(_by: PlayerController) -> void:
	await say([
		"田中：我的影子……怎么慢了半拍。",
	])
	status.text = "镜前 · 约 4 秒"
	await get_tree().create_timer(1.2).timeout
	await say([
		"（他抬手摸了摸自己的脸。只给手，不给特写。）",
		"田中：……刚才那是什么。",
		"田中：（停顿）错觉。是错觉。",
	])
	GameState.add_note("镜：倒影慢了半拍。")
	_mark("mirror")


func _on_stairs(_by: PlayerController) -> void:
	if _inspected.size() < 3:
		await say(["还不安心。先把走廊里三处查完。"])
		return
	GameState.set_flag("1b_complete", true)
	await say(["田中：下面有光。……下去看看。"])
	goto_scene(ScenePaths.BASEMENT_DOOR)
