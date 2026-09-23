extends GreyboxLevel
## 1C 密室法阵 + 1D 田中之死——合棺清醒（剧情设计 v1.1）

var _seal_progress: float = 0.0
var _erasing: bool = false
var _seal_done: bool = false
var _seal_bar: ColorRect
var _seal_area: Interactable


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	setup_shell(1280.0, "1C · 地下密室·封印")
	add_prop(Vector2(520, 480), Vector2(240, 80), Color("3a2a22"), "Coffin")
	add_prop(Vector2(480, 420), Vector2(40, 40), Color("8b2020"), "Mask1")
	add_prop(Vector2(760, 420), Vector2(40, 40), Color("8b2020"), "Mask2")
	add_prop(Vector2(480, 560), Vector2(40, 40), Color("8b2020"), "Mask3")
	add_prop(Vector2(760, 560), Vector2(40, 40), Color("8b2020"), "Mask4")
	add_label_at(Vector2(560, 450), "合棺", Color("c0a090"))

	add_prop(Vector2(500, 400), Vector2(280, 200), Color(0.45, 0.1, 0.12, 0.35), "SealGlow")

	make_interactable("coffin_look", "调查·合棺", Vector2(560, 460), Vector2(160, 70), Color("5a4038"), true).interacted.connect(_on_coffin)
	_seal_area = make_interactable("seal", "长按 E · 抹除法阵", Vector2(540, 500), Vector2(200, 80), Color("7a3030"), false)
	_seal_area.interacted.connect(_on_seal_tap)
	# 查过合棺后再显示抹除交互（避免与合棺抢焦点）
	_seal_area.set_enabled(false)
	_seal_area.visible = false

	var hud := get_node("HUD") as CanvasLayer
	var bar_bg := ColorRect.new()
	bar_bg.position = Vector2(440, 80)
	bar_bg.size = Vector2(400, 16)
	bar_bg.color = Color(0.15, 0.12, 0.14, 1)
	bar_bg.visible = false
	bar_bg.name = "SealBarBG"
	hud.add_child(bar_bg)
	_seal_bar = ColorRect.new()
	_seal_bar.position = Vector2(440, 80)
	_seal_bar.size = Vector2(0, 16)
	_seal_bar.color = Color("a03030")
	_seal_bar.visible = false
	hud.add_child(_seal_bar)

	spawn_player(Vector2(200, 600), false)
	await say([
		"【1C 密室】中央是合棺，地面朱砂法阵，四角反挂傩面具。",
		"先调查合棺。之后才会出现抹除法阵的交互。",
	])
	status.text = "目标：调查合棺"


func _process(_delta: float) -> void:
	if _seal_done:
		return
	if _erasing and Input.is_action_pressed("interact") and not dialogue.is_open():
		_seal_progress = minf(1.0, _seal_progress + _delta / 4.0)
		_seal_bar.visible = true
		(get_node("HUD/SealBarBG") as ColorRect).visible = true
		_seal_bar.size.x = 400.0 * _seal_progress
		var glow := get_node_or_null("SealGlow") as Polygon2D
		if glow:
			glow.color.a = 0.35 * (1.0 - _seal_progress)
		if _seal_progress >= 1.0:
			_finish_seal()
	elif _erasing and not Input.is_action_pressed("interact"):
		pass


func _on_coffin(_by: PlayerController) -> void:
	GameState.set_flag("1c_coffin_seen", true)
	await say([
		"田中：（困惑）这是什么……棺材？地上的画……中国人的东西？",
		"他用枪拨开棺盖缝隙——腐朽气息涌出。",
	])
	_seal_area.set_enabled(true)
	_seal_area.visible = true
	status.text = "靠近法阵，长按 E 抹除"


func _on_seal_tap(_by: PlayerController) -> void:
	if _seal_done or _erasing:
		return
	if not GameState.has_flag("1c_bewitched"):
		GameState.set_flag("1c_bewitched", true)
		await red_flash()
		await say([
			"朱砂微微发光。面具似乎转了过来。粤曲贴耳。",
			"视野水墨晕染——田中眼神空洞。",
			"田中：（机械地）打破它……打破它……",
			"（长按 E 抹除法阵，松开则暂停）",
		])
	_erasing = true
	status.text = "长按 E 抹除法阵…"
	player.locked = true


func _finish_seal() -> void:
	_seal_done = true
	_erasing = false
	_seal_bar.visible = false
	var bg := get_node_or_null("HUD/SealBarBG") as ColorRect
	if bg:
		bg.visible = false
	GameState.set_flag("1c_seal_broken", true)
	player.locked = false
	await say([
		"法阵光芒熄灭，面具纷纷掉落。封印破碎。",
		"密室骤冷。合棺「咚」地一震——然后一切扭曲。",
	])
	await _death_sequence()


func _death_sequence() -> void:
	status.text = "1D · 田中之死——合棺清醒"
	GameState.set_flag("1d_playing", true)
	player.locked = true
	await red_flash()
	await say([
		"田中如梦初醒——发现自己已经不在法阵前。",
		"他正躺在合棺里。棺盖半开，微弱光线透入。",
		"身体无法动弹，只有眼球和嘴唇能动。",
		"田中：（恐惧，低声）什……什么……我怎么在这里……动不了……",
	])
	status.text = "1D · 花旦鬼凝视"
	await red_flash()
	await say([
		"合棺旁，傩舞花旦鬼低头凝视棺中的他——花旦戏服、傩面具、水袖垂落。",
		"面具下眼部有血泪；嘴角露出诡异微笑：像「终于有人陪我」。",
		"阿霞：（空灵，双声部）你……看见了吗……",
		"田中想喊，发不出声。口型：不……不要……",
	])
	status.text = "1D · 棺盖合上与钉棺"
	await say([
		"花旦鬼缓缓合上棺盖。黑暗降临。",
		"咚、咚、咚——每一钉都伴随画面震动。",
		"田中挣扎、抓挠棺壁、试图呼救（无声）。声音渐消，只剩心跳，最后寂静。",
	])
	await get_tree().create_timer(1.2).timeout
	await say([
		"【全黑】钉棺声变慢……停止。",
		"画面渐亮：田中已死——面容扭曲、双手抓挠、咬碎舌头、指甲断裂、无外伤。",
		"眼睛死死盯着棺盖方向，死不瞑目。",
		"【切至次日】军医山本的办公室。",
	])
	GameState.set_flag("1d_complete", true)
	GameState.set_flag("act1_complete", true)
	goto_scene(ScenePaths.OFFICE_2)
