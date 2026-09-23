extends GreyboxLevel
## 第二幕：清点 → 验尸 → 假进门 → 喘息 → 汇报

enum Phase { OFFICE, STAIRS, AFTERMATH, REPORT }
var _phase: Phase = Phase.OFFICE
var _autopsy: Dictionary = {}


func get_room_width() -> float:
	return 1400.0


func _ready() -> void:
	setup_shell(1400.0, "2A · 清点名单·晨")
	_build_office_props()
	spawn_player(Vector2(200, 600), false)
	await say([
		"【第二幕】次日清晨。军医山本发现田中不见了。",
		"调查名单、与护士对话，然后去找人。",
	])
	status.text = "调查名单 · 对话护士 · 前往楼梯口"


func _build_office_props() -> void:
	add_prop(Vector2(180, 420), Vector2(160, 80), Color("4a4035"), "Desk")
	add_prop(Vector2(900, 200), Vector2(140, 100), Color("5a6a7a"), "MorningWindow")
	add_label_at(Vector2(920, 230), "晨光", Color("c8d0d8"))

	make_interactable("roster", "调查·病人名单", Vector2(200, 460), Vector2(100, 60), Color("c4b090"), true).interacted.connect(_on_roster)
	make_interactable("nurse", "对话·护士", Vector2(420, 480), Vector2(60, 100), Color("708090"), true).interacted.connect(_on_nurse)
	make_interactable("to_stairs", "去楼梯口找人", Vector2(1250, 420), Vector2(70, 140), Color("5a4030"), false).interacted.connect(_on_to_stairs)


func _on_roster(_by: PlayerController) -> void:
	GameState.set_flag("2a_roster", true)
	await say([
		"山本：田中一郎……昨晚还在病房的，怎么不见了？",
	])


func _on_nurse(_by: PlayerController) -> void:
	GameState.set_flag("2a_nurse", true)
	await say([
		"护士：我今早查房时就没看到他。可能是出去了？",
		"山本：伤兵擅自离开？……先找找看。可能是去茅房了。",
	])
	status.text = "前往右侧楼梯口"


func _on_to_stairs(_by: PlayerController) -> void:
	if not (GameState.has_flag("2a_roster") and GameState.has_flag("2a_nurse")):
		await say(["先核对名单，并问问护士。"])
		return
	_enter_stairs()


func _enter_stairs() -> void:
	_phase = Phase.STAIRS
	_clear_office_layout()
	status.text = "2B · 发现尸体 — 验尸 0/3"
	await say([
		"楼梯上有拖痕。山本持手电向下。",
		"楼梯底部——田中尸体横陈。死状凄惨。手电掉落。",
		"山本：（惊恐）田中？！……这、这是……",
		"用医学眼光检查：调查三处异常。",
	])
	# 从左侧入口进入；右侧才是半开密室门
	player.position = Vector2(180, 600)
	_spawn_autopsy()


func _clear_office_layout() -> void:
	for n in ["Desk", "MorningWindow", "Interact_roster", "Interact_nurse", "Interact_to_stairs"]:
		_hide_named(n)


func _hide_named(node_name: String) -> void:
	var n := get_node_or_null(node_name)
	if n == null:
		return
	n.visible = false
	if n is Interactable:
		(n as Interactable).set_enabled(false)


func _spawn_autopsy() -> void:
	# 左侧：来时楼梯入口（仅视觉，不可进）
	add_prop(Vector2(40, 420), Vector2(56, 140), Color("5a4030"), "EntryDoor")
	add_label_at(Vector2(28, 390), "↑ 楼梯上来", Color("a09080"))
	# 中央：尸体与验尸点
	add_prop(Vector2(560, 560), Vector2(140, 40), Color("4a2020"), "Body")
	make_interactable("face", "验尸·面容", Vector2(540, 500), Vector2(50, 50), Color("8a5050"), true).interacted.connect(func(b): _on_autopsy("face", b))
	make_interactable("hands", "验尸·双手抓挠", Vector2(600, 500), Vector2(50, 50), Color("8a5050"), true).interacted.connect(func(b): _on_autopsy("hands", b))
	make_interactable("temp", "验尸·体温异常", Vector2(660, 500), Vector2(50, 50), Color("8a5050"), true).interacted.connect(func(b): _on_autopsy("temp", b))
	# 右侧：唯一通往密室的门
	make_interactable("chamber_door", "靠近·密室门（半开）", Vector2(1220, 420), Vector2(70, 140), Color("3a3028"), false).interacted.connect(_on_chamber_door)
	add_label_at(Vector2(1200, 390), "密室 →", Color("a09080"))


func _on_autopsy(part: String, _by: PlayerController) -> void:
	_autopsy[part] = true
	GameState.set_flag("2b_%s" % part, true)
	match part:
		"face":
			await say(["无外伤，但面容扭曲，像经历极度痛苦。神经毒素？……不符合。"])
		"hands":
			await say(["双手呈抓挠状，指甲断裂——周围却没有可抓挠的物体。"])
		"temp":
			await say(["尸体温度异常低。触碰时手被冻得发紫。癫痫？……也不对。"])
	status.text = "验尸 %d/3" % _autopsy.size()
	if _autopsy.size() >= 3:
		GameState.set_flag("2b_autopsy_done", true)
		status.text = "验尸完成 · 前往右侧半开的密室门（会强制逃回）"
		await say([
			"口袋里掉出皱巴巴的「回国资格申请表」——还差一个战功章。",
			"山本：这到底是什么……右侧密室门半开着。他犹豫了。",
		])


func _on_chamber_door(_by: PlayerController) -> void:
	if not GameState.has_flag("2b_autopsy_done"):
		await say(["先把验尸做完。"])
		return
	GameState.set_flag("2b_door_almost", true)
	await red_flash()
	await say([
		"（选择：进入密室）",
		"手电突然熄灭。（sfx_flashlight_die）",
		"山本仓皇逃回楼上。",
	])
	_phase = Phase.AFTERMATH
	_clear_stairs_layout()
	_build_aftermath_layout()
	player.position = Vector2(200, 600)
	await say([
		"【2C 喘息】山本：（内心）不可能是鬼……一定是有人杀了田中。必须报告上级。",
	])
	status.text = "前往右侧汇报"


func _clear_stairs_layout() -> void:
	for n in [
		"EntryDoor", "Body",
		"Interact_face", "Interact_hands", "Interact_temp", "Interact_chamber_door",
	]:
		_hide_named(n)
	# 标签没有统一命名，略过即可


func _build_aftermath_layout() -> void:
	add_prop(Vector2(180, 420), Vector2(160, 80), Color("4a4035"), "DeskBack")
	make_interactable("report", "汇报·上级", Vector2(1180, 420), Vector2(80, 140), Color("4a4550"), true).interacted.connect(_on_report)
	add_label_at(Vector2(1160, 390), "汇报 →", Color("a09080"))


func _on_report(_by: PlayerController) -> void:
	GameState.set_flag("2d_complete", true)
	await say([
		"山本：报告！田中一郎死亡，死因不明。死状……异常。",
		"上级：封锁仙馆。山本，你去找那个老管家，问清楚这地方的情况。逼他一起捉拿凶手。",
		"山本：是！",
		"【第二幕完成】去找阿福伯……",
	])
	goto_scene(ScenePaths.HUT_3)
