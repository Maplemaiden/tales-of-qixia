extends GreyboxLevel
## 1B 走廊楼梯：三处异常调查 → 下地下室

var _inspected: Dictionary = {}


func get_room_width() -> float:
	return 1600.0


func _ready() -> void:
	setup_shell(1600.0, "1B · 走廊与楼梯")
	add_prop(Vector2(200, 80), Vector2(80, 520), Color("2a2230"), "Pillar1")
	add_prop(Vector2(700, 80), Vector2(80, 520), Color("2a2230"), "Pillar2")
	add_prop(Vector2(400, 140), Vector2(120, 160), Color("4a3a55"), "ManchuWindow")
	add_prop(Vector2(900, 200), Vector2(70, 160), Color("3a3028"), "DoorFrame")
	add_prop(Vector2(1100, 180), Vector2(90, 200), Color("353045"), "Mirror")
	add_label_at(Vector2(1200, 520), "↓ 地下室", Color("a09080"))

	make_interactable("win", "调查·满洲窗倒影", Vector2(420, 420), Vector2(90, 100), Color("6a5080"), true).interacted.connect(_on_win)
	make_interactable("door_empty", "调查·自开门", Vector2(900, 420), Vector2(70, 100), Color("705040"), true).interacted.connect(_on_door_empty)
	make_interactable("mirror", "调查·镜中延迟", Vector2(1110, 420), Vector2(80, 100), Color("506070"), true).interacted.connect(_on_mirror)
	make_interactable("stairs", "下地下室", Vector2(1450, 420), Vector2(80, 140), Color("5a4030"), false).interacted.connect(_on_stairs)

	spawn_player(Vector2(120, 600), false)
	await say([
		"【1B 走廊】粤曲时远时近，引你向地下室。",
		"调查三处异常后，可从右侧楼梯下去。",
	])
	status.text = "调查 0/3 · 满洲窗 / 自开门 / 镜子"


func _mark(id: String) -> void:
	_inspected[id] = true
	GameState.set_flag("1b_%s" % id, true)
	var n := _inspected.size()
	status.text = "调查 %d/3 · 满洲窗 / 自开门 / 镜子" % n
	if n >= 3:
		status.text = "三处异常已查 · 前往右侧楼梯下地下室"
		GameState.set_flag("1b_all_inspected", true)


func _on_win(_by: PlayerController) -> void:
	await red_flash()
	await say([
		"满洲窗彩色玻璃上，倒影出一个红衣女子的轮廓。",
		"田中回头——走廊空无一人。",
	])
	_mark("win")
	# 环境略变：窗更暗
	var w := get_node_or_null("ManchuWindow") as Polygon2D
	if w:
		w.color = Color("2a2035")


func _on_door_empty(_by: PlayerController) -> void:
	await say([
		"走廊尽头一扇门自行打开。田中举枪进入——空房。",
		"桌上的煤油灯自行熄灭。",
	])
	_mark("door_empty")


func _on_mirror(_by: PlayerController) -> void:
	await say([
		"镜中倒影似乎比动作慢了半拍。",
		"田中：（低声）别怕……可能就是个女人在唱歌……抓住她，就是功劳。",
	])
	_mark("mirror")


func _on_stairs(_by: PlayerController) -> void:
	if _inspected.size() < 3:
		await say(["还不安心。先把走廊里三处异常查完。"])
		return
	GameState.set_flag("1b_complete", true)
	await say(["楼梯向下延伸，黑暗深处隐约有微光。粤曲更清晰了。"])
	goto_scene(ScenePaths.SEAL_1C)
