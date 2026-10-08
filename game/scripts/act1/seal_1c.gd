extends GreyboxLevel
## S1-4 识别法阵（调查即解密）→ S1-5 自动破封 → S1-6 不给棺内


var _seen: Dictionary = {}
var _seal_progress: float = 0.0
var _erasing: bool = false
var _seal_done: bool = false
var _seal_bar: ColorRect
var _coffin_prop: Polygon2D


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	GameState.puzzle_id = "seal"
	setup_shell(1280.0, "S1-4 · 密室 · 识别法阵")
	_coffin_prop = add_prop(Vector2(520, 480), Vector2(240, 80), Color("3a2a22"), "Coffin")
	add_label_at(Vector2(560, 450), "合棺", Color("c0a090"))
	add_prop(Vector2(500, 400), Vector2(280, 200), Color(0.45, 0.1, 0.12, 0.35), "SealGlow")
	for i in 7:
		var x := 360.0 + i * 80.0
		add_prop(Vector2(x, 360), Vector2(36, 44), Color("8b2020"), "Mask%d" % i)

	make_interactable("coffin", "查看·合棺", Vector2(560, 460), Vector2(160, 70), Color("5a4038"), true).interacted.connect(_on_coffin)
	make_interactable("seal", "查看·法阵", Vector2(540, 500), Vector2(120, 50), Color("7a3030"), false).interacted.connect(_on_seal)
	make_interactable("center", "查看·中央的字", Vector2(620, 490), Vector2(70, 40), Color("9a4040"), true).interacted.connect(_on_center)
	var masks := make_interactable("masks", "查看·反挂面具", Vector2(400, 340), Vector2(80, 70), Color("8b3030"), true)
	masks.ground_focus = true
	masks.interact_radius = 160.0
	masks.interacted.connect(_on_masks)
	make_interactable("oldnew", "查看·朱砂新旧", Vector2(760, 500), Vector2(80, 50), Color("6a2020"), true).interacted.connect(_on_oldnew)
	make_interactable("dress", "查看·红嫁衣", Vector2(160, 500), Vector2(70, 50), Color("8b2020"), true).interacted.connect(_on_dress)
	make_interactable("cups", "查看·合卺碎片", Vector2(280, 520), Vector2(70, 40), Color("8a7060"), true).interacted.connect(_on_cups)

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
	await say(["田中：这是什么……棺材？好大一口。"])
	status.text = "调查合棺、法阵、「镇」、面具朝向"


func _process(delta: float) -> void:
	if not _erasing or _seal_done:
		return
	_seal_progress = minf(1.0, _seal_progress + delta / 4.0)
	_seal_bar.visible = true
	var bg := get_node_or_null("HUD/SealBarBG") as ColorRect
	if bg:
		bg.visible = true
	_seal_bar.size.x = 400.0 * _seal_progress
	var glow := get_node_or_null("SealGlow") as Polygon2D
	if glow:
		glow.color.a = 0.35 * (1.0 - _seal_progress)
	if _seal_progress >= 1.0:
		_finish_seal()


func _mark(id: String) -> void:
	_seen[id] = true
	if _seen.has("center") and _seen.has("masks") and not GameState.has_flag("1c_identified"):
		GameState.set_flag("1c_identified", true)
		_start_bewitch()


func _on_coffin(_by: PlayerController) -> void:
	await say(["双人棺。木头是湿的。", "田中：两个人？……谁和谁。"])
	_mark("coffin")
	GameState.set_flag("1c_coffin_seen", true)


func _on_seal(_by: PlayerController) -> void:
	await say(["地上画了一圈。朱砂。笔很稳。"])
	_mark("seal")


func _on_center(_by: PlayerController) -> void:
	GameState.add_note("法阵中央：镇。不是驱。")
	await say(["中间一个字。笔画很重。——「镇」。"])
	_mark("center")


func _on_masks(_by: PlayerController) -> void:
	GameState.add_note("七个傩面具反挂，脸朝棺材。")
	await say([
		"七个傩面具，都倒着挂。脸朝着棺材。",
		"田中：朝里，不朝外。……这是要压住什么。",
	])
	_mark("masks")


func _on_oldnew(_by: PlayerController) -> void:
	GameState.add_note("朱砂有新旧两道。有人补过。")
	await say(["有的线是新的，压在旧线上面。补过。", "田中：迷信的把戏。"])
	_mark("oldnew")


func _on_dress(_by: PlayerController) -> void:
	await say(["叠得很整齐。像从没穿过。"])


func _on_cups(_by: PlayerController) -> void:
	GameState.add_note("合卺杯：婚礼交杯。")
	await say(["一对喜杯，碎在地上。红金两色。"])


func _start_bewitch() -> void:
	if _erasing:
		return
	player.locked = true
	GameState.set_flag("1c_bewitched", true)
	await red_flash()
	await ink_wash(0.4, 0.1)
	await say([
		"画面边缘晕开。田中眼神散了。",
		"田中：（机械）打破它……打破它……打破它……",
		"（手不听使唤。法阵开始被抹掉。）",
	], true)
	status.text = "S1-5 · 被蛊惑 · 破封（无法操作）"
	_erasing = true


func _finish_seal() -> void:
	if _seal_done:
		return
	_seal_done = true
	_erasing = false
	_seal_bar.visible = false
	var bg := get_node_or_null("HUD/SealBarBG") as ColorRect
	if bg:
		bg.visible = false
	GameState.set_flag("1c_seal_broken", true)
	await say([
		"面具一块块砸在地上。法阵的光灭了。",
		"（所有声音停了一拍。）",
		"密室骤冷。合棺「咚」地一震。",
	], true)
	await _death_sequence()


func _death_sequence() -> void:
	status.text = "S1-6 · 合棺清醒"
	GameState.set_flag("1d_playing", true)
	player.locked = true
	set_black(1.0)
	await say([
		"（全黑。呼吸很近。）",
		"田中：什……什么……我怎么在这里……",
		"田中：动不了……身子动不了……",
	], true)
	set_black(0.35)
	await red_flash()
	await say([
		"傩舞花旦鬼站在棺口。面具、水袖、血泪。嘴角像在笑。",
		"她：（空灵，双声部）你……看见了吗……",
		"（田中想喊。发不出声。口型：不……不要……）",
	], true)
	set_black(1.0)
	status.text = "七钉"
	for i in 7:
		status.text = "第 %d 钉" % (i + 1)
		await get_tree().create_timer(0.85).timeout
	status.text = "……"
	await get_tree().create_timer(2.0).timeout
	set_black(0.15)
	status.text = "次日 · 密室外"
	await say([
		"光慢慢回来。镜头停在棺盖上。",
	], true)
	# 棺盖实位移半寸
	if _coffin_prop:
		var tw := create_tween()
		tw.tween_property(_coffin_prop, "position:y", _coffin_prop.position.y - 8.0, 1.6)
		await tw.finished
	await say([
		"棺盖被推开半寸。不给方向。",
		"缝里是黑的。不给棺内画面。",
	], true)
	await get_tree().create_timer(4.0).timeout
	GameState.set_flag("1d_complete", true)
	GameState.set_flag("act1_complete", true)
	GameState.puzzle_id = ""
	goto_scene(ScenePaths.OFFICE_2)
