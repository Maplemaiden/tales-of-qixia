extends GreyboxLevel
## 第四幕：空棺 → 五物 → 喘息 → 鬼影拾碎片 → 壁画 → 拼合（灰盒一次交互）→ 三层幻象 → 七钉


enum Phase { LOOK, SEARCH, REST, GHOST, MURAL, ASSEMBLE, L1, L2, L3, DEATH }
const FRAG_XS: Array[float] = [420.0, 720.0, 1020.0, 1320.0, 1580.0]
## 鬼影段开始 / 重试点（右侧触发点附近）
const GHOST_START := Vector2(1600, 600)

var _phase: Phase = Phase.LOOK
var _items: Dictionary = {}
var _ghost: GhostShadow
var _frag_nodes: Array[Interactable] = []
var _nails: int = 0
var _nail_hint: Label
var _nail_busy: bool = false
var _coffin: Polygon2D
var _assemble_busy: bool = false


func get_room_width() -> float:
	return 1800.0


func _ready() -> void:
	GameState.puzzle_id = "mask"
	setup_shell(1800.0, "S4-1 · 进入密室")
	_coffin = add_prop(Vector2(760, 470), Vector2(260, 90), Color("3a2a22"), "Coffin")
	add_label_at(Vector2(840, 490), "合棺", Color("c0a090"))
	add_prop(Vector2(200, 500), Vector2(70, 50), Color("6a2020"), "Dress")
	add_prop(Vector2(1400, 200), Vector2(180, 160), Color("2a241c"), "MuralDark")

	make_interactable("coffin_empty", "探进棺缝", Vector2(800, 440), Vector2(160, 70), Color("5a4038"), true).interacted.connect(_on_empty)
	make_interactable("scratch", "查看·抓痕", Vector2(780, 430), Vector2(70, 40), Color("7a4040"), true).interacted.connect(func(b): _on_item("scratch", b))
	make_interactable("print", "查看·指印", Vector2(900, 430), Vector2(70, 40), Color("7a4040"), true).interacted.connect(func(b): _on_item("print", b))
	make_interactable("cup", "查看·合卺碎片", Vector2(620, 520), Vector2(70, 40), Color("8a7060"), true).interacted.connect(func(b): _on_item("cup", b))
	make_interactable("dress", "查看·红嫁衣", Vector2(200, 480), Vector2(80, 60), Color("8b2020"), true).interacted.connect(func(b): _on_item("dress", b))
	make_interactable("seal", "查看·法阵残迹", Vector2(1100, 500), Vector2(90, 50), Color("6a2020"), true).interacted.connect(func(b): _on_item("seal", b))
	_set_search_enabled(false)

	_nail_hint = Label.new()
	_nail_hint.position = Vector2(640, 100)
	_nail_hint.add_theme_font_size_override("font_size", 18)
	_nail_hint.add_theme_color_override("font_color", Color("e0d0c0"))
	_nail_hint.visible = false
	get_node("HUD").add_child(_nail_hint)

	spawn_player(Vector2(120, 600), false)
	await say([
		"第四幕 · 合棺",
		"又一夜。这一次，是他自己要下去的。",
	])
	status.text = "先把光探进棺缝"


func _set_search_enabled(v: bool) -> void:
	for id in ["scratch", "print", "cup", "dress", "seal"]:
		var n := get_node_or_null("Interact_%s" % id)
		if n is Interactable:
			(n as Interactable).set_enabled(v)
			n.visible = v


func _on_empty(_by: PlayerController) -> void:
	await say(["他把光探进那道缝。里面是空的。"])
	await get_tree().create_timer(3.0).timeout
	await say(["（停。不给任何解释。）"])
	_phase = Phase.SEARCH
	_set_search_enabled(true)
	status.text = "调查 0/5 · 抓痕 / 指印 / 合卺 / 嫁衣 / 法阵残迹"


func _on_item(id: String, _by: PlayerController) -> void:
	if _phase != Phase.SEARCH:
		return
	_items[id] = true
	GameState.set_flag("4a_%s" % id, true)
	match id:
		"scratch":
			await say(["里面有抓痕。很深。不像男人的手。"])
		"print":
			await say(["指印。是从里面推的。"])
		"cup":
			await say(["一对喜杯，碎在地上。红金两色。"])
		"dress":
			await say(["叠得很整齐。像从没穿过。"])
		"seal":
			await say(["朱砂被抹断了。像是有人故意擦掉的。", "山本：昨天那四个字……有人在看着我。"])
	status.text = "调查 %d/5" % _items.size()
	if _items.size() >= 5:
		_start_rest()


func _start_rest() -> void:
	_phase = Phase.REST
	GameState.set_flag("4a_complete", true)
	await say(["山本：先……先理清楚。", "（可以走动。这不是过场。）"])
	make_interactable("go_on", "继续 · 地上有微光", Vector2(1600, 480), Vector2(100, 80), Color("9b8b4c"), true).interacted.connect(_start_ghost)
	status.text = "喘息 8–12 秒 · 可走动 · 右侧继续"
	await get_tree().create_timer(8.0).timeout
	if _phase == Phase.REST:
		status.text = "右侧继续 · 碎片"


func _start_ghost(_by: PlayerController) -> void:
	if _phase != Phase.REST:
		return
	_phase = Phase.GHOST
	player.position = GHOST_START
	player.hiding = false
	_make_hide_spot(Vector2(GHOST_START.x - 170.0, 520), "HideL")
	_make_hide_spot(Vector2(GHOST_START.x + 120.0, 520), "HideR")
	await say(["山本：……前面有东西。", "山本：别让它看见我。", "（贴进两侧墙凹，它就看不见。）"])
	_ghost = GhostShadow.new()
	_ghost.name = "Ghost"
	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([Vector2(-18, -90), Vector2(18, -90), Vector2(18, 0), Vector2(-18, 0)])
	vis.color = Color("6a5a70")
	_ghost.add_child(vis)
	add_child(_ghost)
	# 只在几块碎片之间往返；朝向不改（仍从左端向右起步）
	_ghost.setup(FRAG_XS[0], FRAG_XS[FRAG_XS.size() - 1], 70.0, player, 200.0)
	_ghost.caught.connect(_on_caught)

	for i in FRAG_XS.size():
		var it := make_interactable("frag%d" % i, "拾取·面具碎片", Vector2(FRAG_XS[i], 500), Vector2(50, 40), Color("c4a050"), true)
		it.interacted.connect(func(b, idx=i): _on_frag(idx, b))
		_frag_nodes.append(it)
	status.text = "贴墙凹躲避 · 躲开监管再拾取 · 碎片 %d/7" % GameState.item_count("mask_frag")


func _make_hide_spot(pos: Vector2, node_name: String) -> void:
	add_prop(pos, Vector2(56, 90), Color("2a3438"), node_name)
	add_label_at(pos + Vector2(4, -18), "躲避", Color("8ab0a0"))
	var area := Area2D.new()
	area.name = "Area_%s" % node_name
	area.position = pos + Vector2(28, 70)
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	area.monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(70, 120)
	shape.shape = rect
	area.add_child(shape)
	area.body_entered.connect(_on_hide_enter)
	area.body_exited.connect(_on_hide_exit)
	add_child(area)


func _on_hide_enter(body: Node2D) -> void:
	if body is PlayerController:
		(body as PlayerController).hiding = true
		status.text = "躲避中 · 它看不见你"


func _on_hide_exit(body: Node2D) -> void:
	if body is PlayerController:
		(body as PlayerController).hiding = false
		if _phase == Phase.GHOST:
			status.text = "躲开监管再拾取 · 碎片 %d/7" % GameState.item_count("mask_frag")


func _on_frag(_idx: int, _by: PlayerController) -> void:
	GameState.add_item("mask_frag", 1)
	await say(["拾取：傩舞面具碎片"])
	var n := GameState.item_count("mask_frag")
	status.text = "躲开监管再拾取 · 碎片 %d/7" % n
	if _ghost:
		_ghost.speed = 70.0 + n * 8.0
	if n >= 7:
		_start_mural()


func _on_caught() -> void:
	if _phase != Phase.GHOST:
		return
	_ghost.active = false
	player.hiding = false
	await ink_wash(0.85, 0.15)
	if GameState.first_ghost_catch:
		GameState.first_ghost_catch = false
		await say(["山本：……又来了。"])
	else:
		await say(["（无字。）"])
	await ink_clear()
	player.position = GHOST_START
	_ghost.reset_patrol()
	_ghost.active = true


func _start_mural() -> void:
	_phase = Phase.MURAL
	if player:
		player.hiding = false
	if _ghost:
		_ghost.active = false
		_ghost.visible = false
	make_interactable("mural", "查看·壁画", Vector2(1400, 430), Vector2(140, 100), Color("5a4a38"), false).interacted.connect(_on_mural)
	status.text = "用手电照壁画"
	await say(["墙上有画。"])


func _on_mural(_by: PlayerController) -> void:
	if not GameState.has_item("flashlight"):
		await say(["太暗了，看不清。", "得先有个亮的东西。"])
		return
	if GameState.has_flag("4_mural"):
		await say(["七个面具围着一个人。得把碎片拼回去。"])
		_start_assemble()
		return
	GameState.set_flag("4_mural", true)
	await say([
		"山本：墙上有画。太暗，看不清。",
		"（手电凑近。）",
		"山本：七个面具，围着一个人在中间。",
		"山本：画的是怎么摆这些面具。",
	])
	GameState.add_note("壁画：七个面具围着中间的人。")
	_start_assemble()


func _start_assemble() -> void:
	if _phase == Phase.ASSEMBLE:
		return
	_phase = Phase.ASSEMBLE
	# Demo 灰盒：正式版改为弹窗拼合；此处一次交互直接通关。
	make_interactable("workbench", "拼合·面具碎片", Vector2(520, 480), Vector2(120, 70), Color("6a6050"), true).interacted.connect(_on_assemble)
	status.text = "工作台 · E 拼合面具（灰盒跳过解谜）"
	await say(["工作台上可以拼这些碎片。"])


func _on_assemble(_by: PlayerController) -> void:
	if _phase != Phase.ASSEMBLE or _assemble_busy:
		return
	_assemble_busy = true
	await say([
		"（他把碎片一块块对上。烛火摇了一下。）",
		"山本：背面刻着字。",
		"镇",
		"山本：镇……不是驱。",
		"山本：他们不是在赶她走。他们在压着她。",
	])
	GameState.set_flag("4_assembled", true)
	_start_layer1()


func _start_layer1() -> void:
	_phase = Phase.L1
	GameState.puzzle_id = ""
	status.text = "S4-3 · 第一层幻象"
	await red_flash()
	await ink_wash(0.3, 0.05)
	await say([
		"密室变得有光。她坐在妆台前梳头。不给脸。",
		"她：今天又学了一段新曲……",
		"她：梅家阿哥的信还没回……等他回来，我们就成亲……",
		"山本：这……就是那个姑娘？她……",
	])
	var her := make_interactable("her", "靠近·她（无法触及）", Vector2(860, 400), Vector2(80, 120), Color("c08090"), false)
	her.interacted.connect(_on_her)
	status.text = "走近她 · 差一步"


func _on_her(_by: PlayerController) -> void:
	if _phase != Phase.L1:
		return
	await say(["你伸出手——差一步。永远差一步。", "她忽然转头。眼睛是空的。嘴角在笑。"])
	await _start_layer2()


func _start_layer2() -> void:
	_phase = Phase.L2
	status.text = "S4-4 · 第二层幻象"
	player.locked = true
	await say([
		"人影不清晰。她被换上红嫁衣。没有反抗。",
		"酒泼在地上。杯子摔了。",
		"她：不要……放我出去……求求你们……",
		"棺盖合上。",
	], true)
	await flash_frame(0.3)
	await say([
		"山本：不要看了！不要看了！",
		"山本：这……这不是真的……不可能……",
	], true)
	player.locked = false
	await _start_layer3()


func _start_layer3() -> void:
	_phase = Phase.L3
	status.text = "S4-5 · 她的第一人称"
	player.locked = true
	set_black(1.0)
	_nails = 0
	_nail_hint.visible = true
	_nail_hint.text = "Space / E · 一 ……（钉 0/7）"
	await say([
		"她的第一人称。你不再控制山本。",
		"她：放我出去……放我出去……求求你们……",
	], true)


func _unhandled_input(event: InputEvent) -> void:
	if _phase == Phase.L3:
		if _nail_busy:
			return
		if event.is_action_pressed("ui_advance") or event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			_do_nail()
		return
	super._unhandled_input(event)


func _do_nail() -> void:
	if _nails >= 7:
		return
	_nail_busy = true
	_nails += 1
	GameState.set_flag("4d_nails", _nails)
	_nail_hint.text = "钉 %d/7" % _nails
	status.text = "第 %d 钉" % _nails
	await get_tree().create_timer(0.35 + _nails * 0.12).timeout
	_nail_busy = false
	if _nails >= 7:
		_nail_hint.text = "……"
		await get_tree().create_timer(2.0).timeout
		await say(["她：（气音）……曲子……还没唱完……"], true)
		await get_tree().create_timer(1.2).timeout
		await _death_and_end()


func _death_and_end() -> void:
	_phase = Phase.DEATH
	set_black(0.0)
	status.text = "S4-6 · 山本之死"
	await red_flash()
	await say([
		"幻象结束。山本躺在合棺里。清醒。和那个人一样。",
		"山本：什……什么……我怎么会在这里……",
		"山本：放开我！",
		"他撞开棺盖。开枪。打不中。",
		"门已锁死。水袖缠住脖子。",
		"山本：开门！……不……不要……",
	], true)
	status.text = "S4-7 · 地缚灵"
	await say([
		"灯灭了。",
		"她：又一个……看见了……",
		"（角落里，另一个人也在。无台词。）",
	], true)
	status.text = "S4-8 · 钩子"
	await say([
		"（他的嘴在动。没有声音。口型：别进来。）",
		"雨中，一个撑伞的人走向大门。远景。不给名字。",
	], true)
	status.text = "S4-9 · 撤离"
	await say([
		"三日后。他们走得很快，连药都没带走。",
		"（空走廊。雨。远处有人在哼曲。）",
	], true)
	GameState.set_flag("demo_complete", true)
	goto_scene(ScenePaths.DEMO_END)
