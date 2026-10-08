extends GreyboxLevel
## 第二幕：清点 → 惊吓瞥见换灯 → 笔停回忆 → 汇报


enum Phase { OFFICE, STAIRS, MEMORY, REPORT }
var _phase: Phase = Phase.OFFICE
var _dark: ColorRect


func get_room_width() -> float:
	return 1400.0


func _ready() -> void:
	setup_shell(1400.0, "S2-1 · 清点名单 · 晨")
	_dark = ColorRect.new()
	_dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dark.color = Color(0, 0, 0, 0)
	_dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_node("HUD").add_child(_dark)

	_build_office()
	spawn_player(Vector2(200, 600), false)
	await say([
		"第二幕 · 发现",
		"天亮的时候，雨小了一些。",
		"山本：田中一郎……昨晚还在病房的，怎么不见了。",
	])
	status.text = "名单 · 护士 · 拾取煤油灯 · 去楼梯口"


func _build_office() -> void:
	add_prop(Vector2(180, 420), Vector2(160, 80), Color("4a4035"), "Desk")
	add_prop(Vector2(900, 200), Vector2(140, 100), Color("5a6a7a"), "MorningWindow")
	add_label_at(Vector2(920, 230), "晨光", Color("c8d0d8"))
	add_prop(Vector2(500, 200), Vector2(50, 80), Color("4a2020"), "Flag")
	make_interactable("roster", "查看·病人名单", Vector2(200, 460), Vector2(100, 60), Color("c4b090"), true).interacted.connect(_on_roster)
	make_interactable("nurse", "对话·护士", Vector2(420, 480), Vector2(60, 100), Color("3a3a40"), true).interacted.connect(_on_nurse)
	make_interactable("lamp", "拾取·煤油灯", Vector2(80, 500), Vector2(50, 50), Color("c4a050"), true).interacted.connect(_on_lamp)
	make_interactable("to_stairs", "去楼梯口", Vector2(1250, 420), Vector2(70, 140), Color("5a4030"), false).interacted.connect(_on_to_stairs)


func _on_roster(_by: PlayerController) -> void:
	GameState.set_flag("2a_roster", true)
	GameState.add_note("名册：田中一郎后面没有勾。")
	await say(["住院伤兵名册。田中一郎后面没有勾。"])


func _on_nurse(_by: PlayerController) -> void:
	GameState.set_flag("2a_nurse", true)
	await say([
		"护士：我今早查房时就没看到他。可能是出去了？",
		"山本：伤兵擅自离开？去哪了。",
		"护士：不知道……要不要报告上级？",
		"山本：先找找看。许是去茅房了。",
	])


func _on_lamp(_by: PlayerController) -> void:
	GameState.add_item("lamp")
	await say(["黄铜灯座，油只剩个底。", "（已收进箱内。）"])


func _on_to_stairs(_by: PlayerController) -> void:
	if not (GameState.has_flag("2a_roster") and GameState.has_flag("2a_nurse")):
		await say(["先核对名单，并问问门口那个人。"])
		return
	if not GameState.has_item("lamp"):
		await say(["得先有个亮的东西。"])
		return
	_enter_stairs()


func _enter_stairs() -> void:
	_phase = Phase.STAIRS
	_clear(["Desk", "MorningWindow", "Flag", "Interact_roster", "Interact_nurse", "Interact_lamp", "Interact_to_stairs"])
	status.text = "S2-2 · 发现尸体"
	add_prop(Vector2(560, 560), Vector2(140, 40), Color("4a2020"), "Body")
	add_label_at(Vector2(28, 390), "↑ 楼梯", Color("a09080"))
	add_label_at(Vector2(1200, 390), "密室 →", Color("a09080"))
	make_interactable("body", "走近·尸体", Vector2(560, 500), Vector2(140, 70), Color("8a5050"), true).interacted.connect(_on_body)
	make_interactable("chamber_door", "靠近·密室门", Vector2(1220, 420), Vector2(70, 140), Color("3a3028"), false).interacted.connect(_on_chamber_door)
	get_node("Interact_chamber_door").set_enabled(false)
	player.position = Vector2(180, 600)
	await say(["楼梯上有拖痕。有人被拖过。"])


func _on_body(_by: PlayerController) -> void:
	await say(["山本：田中？！……这、这是……"])
	await red_flash()
	_dark.color = Color(0, 0, 0, 0.72)
	await say([
		"煤油灯脱手摔灭。玻璃碎了。全黑。",
		"（摸黑。手碰到冰凉的东西。）",
	])
	GameState.add_item("flashlight")
	if not GameState.has_item("form"):
		GameState.add_item("form")
	GameState.set_flag("2b_flashlight", true)
	_dark.color = Color(0, 0, 0, 0.25)
	await say([
		"拾取：手电筒。光束发黄，照不了多远。",
		"口袋里有一张申请表。最后一栏是空的。",
	])
	var door := get_node_or_null("Interact_chamber_door") as Interactable
	if door:
		door.set_enabled(true)
	status.text = "可靠近右侧半开门 · 会逃回"
	GameState.set_flag("2b_glimpse", true)


func _on_chamber_door(_by: PlayerController) -> void:
	if not GameState.has_flag("2b_glimpse"):
		await say(["先看清地上的人。"])
		return
	GameState.set_flag("2b_door_almost", true)
	_dark.color = Color(0, 0, 0, 0.9)
	await say(["手电突然熄灭。山本仓皇退回。"])
	_enter_memory()


func _enter_memory() -> void:
	_phase = Phase.MEMORY
	_dark.color = Color(0, 0, 0, 0)
	_clear(["Body", "Interact_body", "Interact_chamber_door"])
	add_prop(Vector2(180, 420), Vector2(160, 80), Color("4a4035"), "DeskBack")
	make_interactable("write", "坐下·落笔", Vector2(200, 460), Vector2(120, 70), Color("8a7060"), true).interacted.connect(_on_write)
	make_interactable("report", "汇报", Vector2(1180, 420), Vector2(80, 140), Color("4a4550"), false).interacted.connect(_on_report)
	get_node("Interact_report").set_enabled(false)
	player.position = Vector2(200, 600)
	status.text = "S2-3 · 写不下去"
	await say(["山本逃回办公室。桌上是他的手记。"])


func _on_write(_by: PlayerController) -> void:
	await say([
		"他坐到桌前，蘸墨，落笔。笔尖停住。墨滴晕开。",
		"山本：……写不下去。",
	])
	await ink_wash(0.35, 0.05)
	await say([
		"脸。扭曲得不成样子。死前极痛苦。",
		"手。呈抓挠状。指甲断了——可周围没有能抓的东西。",
		"口。舌头咬碎了。……癫痫？不像。",
		"无外伤。体温低得反常，摸上去手发麻。",
	])
	await ink_clear()
	await say([
		"（他放下笔。低头看那团晕开的墨。）",
		"山本：医学解释不了的事，我不信它存在。",
	])
	GameState.add_note("死状：无外伤，抓挠，舌碎，极冷。")
	GameState.set_flag("2c_memory", true)
	get_node("Interact_report").set_enabled(true)
	status.text = "右侧汇报"


func _on_report(_by: PlayerController) -> void:
	if not GameState.has_flag("2c_memory"):
		await say(["先把看见的写下来。"])
		return
	GameState.set_flag("2d_complete", true)
	await say([
		"山本：报告。田中一郎死亡，死因不明。死状……异常。",
		"上级：异常？什么意思。",
		"山本：无外伤。面容扭曲，双手呈抓挠状，口中咬碎舌头。体温异常低。",
		"上级：凶手呢。",
		"山本：未找到。尸体在通往地下室的楼梯口。",
		"上级：封锁仙馆，所有人不得进出。",
		"上级：山本，你去找到那个老管家，问清楚这地方的情况。",
		"山本：是。",
	])
	goto_scene(ScenePaths.JING_TANG)


func _clear(names: Array) -> void:
	for node_name in names:
		var n := get_node_or_null(str(node_name))
		if n == null:
			continue
		n.visible = false
		if n is Interactable:
			(n as Interactable).set_enabled(false)
