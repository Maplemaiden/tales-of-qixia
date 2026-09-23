extends GreyboxLevel
## 第四幕：五物 → 三层幻象 → 七钉 → 合棺挣扎之死（剧情设计 v1.1）

enum Phase { SEARCH, L1, L2, L3, DEATH, END }
var _phase: Phase = Phase.SEARCH
var _items: Dictionary = {}
var _nails: int = 0
var _nail_hint: Label


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	setup_shell(1280.0, "4A · 进入密室")
	add_prop(Vector2(520, 470), Vector2(260, 90), Color("3a2a22"), "Coffin")
	add_label_at(Vector2(600, 490), "合棺", Color("c0a090"))
	add_prop(Vector2(200, 500), Vector2(70, 50), Color("6a2020"), "Dress")
	add_prop(Vector2(900, 480), Vector2(50, 60), Color("5a5040"), "Diary")

	make_interactable("scratch", "调查·抓痕", Vector2(540, 440), Vector2(70, 50), Color("7a4040"), true).interacted.connect(func(b): _on_item("scratch", b))
	make_interactable("print", "调查·指印", Vector2(650, 440), Vector2(70, 50), Color("7a4040"), true).interacted.connect(func(b): _on_item("print", b))
	make_interactable("cup", "调查·合卺碎片", Vector2(400, 520), Vector2(70, 50), Color("8a7060"), true).interacted.connect(func(b): _on_item("cup", b))
	make_interactable("dress", "调查·红嫁衣", Vector2(200, 480), Vector2(80, 60), Color("8b2020"), true).interacted.connect(func(b): _on_item("dress", b))
	make_interactable("diary", "调查·日记（回忆污染）", Vector2(900, 460), Vector2(60, 70), Color("5a5040"), true).interacted.connect(func(b): _on_item("diary", b))

	_nail_hint = Label.new()
	_nail_hint.position = Vector2(500, 100)
	_nail_hint.add_theme_font_size_override("font_size", 18)
	_nail_hint.add_theme_color_override("font_color", Color("e0d0c0"))
	_nail_hint.visible = false
	get_node("HUD").add_child(_nail_hint)

	spawn_player(Vector2(150, 600), false)
	await say([
		"【第四幕】山本独自进入密室。法阵残迹尚在。",
		"昨夜日记已被污染。调查五处细节后，幻象将开始。",
	])
	status.text = "调查 0/5 · 抓痕/指印/合卺/嫁衣/日记"


func _on_item(id: String, _by: PlayerController) -> void:
	_items[id] = true
	GameState.set_flag("4a_%s" % id, true)
	match id:
		"scratch":
			await say(["合棺内壁深深抓痕——更早的、女性的。"])
		"print":
			await say(["棺盖内侧有指印。"])
		"cup":
			await say(["合卺杯的碎片散落一地。"])
		"dress":
			await say(["角落叠放整齐的红嫁衣。"])
		"diary":
			await say([
				"墙角又看见那本日记。山本想起昨夜——「你看见了吗？」",
				"山本：（低声）看见什么……就是这些吗。",
				"手开始颤抖。有什么东西在注视他。",
			])
	status.text = "调查 %d/5" % _items.size()
	if _items.size() >= 5 and _phase == Phase.SEARCH:
		GameState.set_flag("4a_complete", true)
		await _start_layer1()


func _start_layer1() -> void:
	_phase = Phase.L1
	status.text = "4B · 第一层幻象·日常"
	await red_flash()
	await say([
		"水墨晕染。阿霞的幻象出现——不是怨灵，是生前的日常。",
		"她梳妆、哼曲、写日记。你可走近，但永远碰不到她。",
	])
	var axia := make_interactable("axia", "靠近·阿霞（无法触及）", Vector2(600, 400), Vector2(80, 120), Color("c08090"), false)
	axia.interacted.connect(_on_axia_near)
	status.text = "走近阿霞幻象（会无法触及）· 然后再触发下一段"


func _on_axia_near(_by: PlayerController) -> void:
	if _phase != Phase.L1:
		return
	_phase = Phase.L2
	await say([
		"你伸出手——差一步。永远差一步。",
		"阿霞突然转头看向你。眼神空洞，似笑似哭。幻象破碎。",
	])
	await _start_layer2()


func _start_layer2() -> void:
	_phase = Phase.L2
	status.text = "4C · 第二层·冥婚与合棺（旁观）"
	player.locked = true
	await say([
		"【纯旁观】换嫁衣、合卺礼、被钉入合棺。",
		"咚、咚、咚——画面震动。阿霞：不要……放我出去……",
		"山本试图闭眼，幻象仍强行进入视野。",
		"山本：（惊恐）不要看了！不要看了！",
		"呼救渐弱。幻象结束。理性崩塌。",
	])
	player.locked = false
	await _start_layer3()


func _start_layer3() -> void:
	_phase = Phase.L3
	status.text = "4D · 第三层·棺内 · 七钉"
	_nails = 0
	_nail_hint.visible = true
	_nail_hint.text = "Space / E · 撑住/抓挠（钉 0/7）"
	await say([
		"全黑。你以阿霞的视角躺在合棺里。",
		"每一钉按一次 Space 或 E。越往后反馈越弱，最后按键无效。",
	])
	player.locked = true


func _unhandled_input(event: InputEvent) -> void:
	if _phase != Phase.L3:
		return
	if event.is_action_pressed("ui_advance") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_do_nail()


func _do_nail() -> void:
	if _nails >= 7:
		return
	_nails += 1
	GameState.set_flag("4d_nails", _nails)
	_nail_hint.text = "钉 %d/7" % _nails
	match _nails:
		1:
			status.text = "第一钉：棺盖合上，外界变闷"
		2:
			status.text = "第二钉：黑暗降临，开始窒息"
		3:
			status.text = "第三钉：挣扎，指甲抓挠木板"
		4:
			status.text = "第四钉：呼救沙哑……按键发沉"
		5:
			status.text = "第五钉：外界隔绝……反馈变弱"
		6:
			status.text = "第六钉：只剩心跳……几乎无响应"
		7:
			status.text = "第七钉：按键无效。寂静。"
			_nail_hint.text = "……"
			_finish_nails()


func _finish_nails() -> void:
	await get_tree().create_timer(0.3).timeout
	await get_tree().create_timer(2.0).timeout
	_nail_hint.visible = false
	await say([
		"（黑屏约数秒。声音逐渐消失。）",
		"……",
	])
	await get_tree().create_timer(1.5).timeout
	await _death_and_end()


func _death_and_end() -> void:
	_phase = Phase.DEATH
	player.locked = true
	status.text = "4E · 山本之死——合棺挣扎"
	await red_flash()
	await say([
		"幻象结束。山本发现——自己正躺在合棺里。与田中一样，清醒。",
		"棺盖半开。身体被怨气压制，但意志更顽强，仍能微微动弹。",
		"棺口站着傩舞花旦鬼：血泪、诡异微笑，正要合上棺盖。",
		"山本：（恐惧，挣扎）什……什么……放开我！",
	])
	await say([
		"【爆发】求生本能挣脱压制。他用肘撞开半合棺盖，翻出棺材，跌落地面。",
		"山本：（爆发）滚开！",
		"他掏枪连续射击——子弹穿过怨灵，打在石墙上，溅起石屑。",
		"山本：（惊恐）砰！砰！为什么……打不中！",
	])
	await red_flash()
	await say([
		"转身想逃——密室门已自行锁死。拍门、撞门，纹丝不动。",
		"水袖如触手缠住脖子。窒息、抓挠、咬碎舌头——死状与田中一致。",
		"山本：（绝望）开门！……不……不要……",
		"（视觉锚点：傩舞花旦鬼——请截图记住这个色块组合）",
	])
	status.text = "4F–4H · 地缚灵 / 钩子 / 撤离"
	await say([
		"山本的灵魂被吸入合棺方向。",
		"阿霞：（旁白）又一个……看见了……",
		"角落里，田中的灵魂眼神空洞。",
		"【通灵预知】雨中，撑油纸伞的女子走向仙馆——莫婉清。",
		"山本：（无声）别进来……别进来……",
		"日军发现军医惨死，恐慌撤离。仙馆空廊只剩雨声与远处粤曲。",
		"【Demo 四幕灰盒流程结束 · 对齐剧情设计 v1.1】",
	])
	GameState.set_flag("demo_complete", true)
	goto_scene(ScenePaths.DEMO_END)
