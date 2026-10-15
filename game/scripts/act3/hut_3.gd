extends GreyboxLevel
## S3-2 挤牙膏 + S3-3 一闪 + S3-4 线索卡排序 + S3-5 劝告辱骂


## 正确顺序：七年前 → 有个姑娘 → 不是自杀 → 活活钉进去 → 和死人合葬
const CLUE_CARDS := [
	{"id": "years", "text": "七年前"},
	{"id": "girl", "text": "有个姑娘"},
	{"id": "not_suicide", "text": "不是自杀"},
	{"id": "nailed", "text": "活活钉进去"},
	{"id": "burial", "text": "和死人合葬"},
]

var _story_step: int = 0
var _sort_root: Control
var _card_list: VBoxContainer
var _order: Array[int] = []
var _sorting: bool = false
var _afu_busy: bool = false
var _feedback: Label
var _afu_area: Interactable


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	setup_shell(1280.0, "S3-2 · 阿福伯小屋")
	add_prop(Vector2(700, 450), Vector2(80, 120), Color("5a5040"), "Afu")
	add_prop(Vector2(200, 480), Vector2(50, 40), Color("8a7060"), "Comb")
	add_prop(Vector2(280, 470), Vector2(60, 50), Color("706050"), "Score")
	add_prop(Vector2(40, 500), Vector2(70, 50), Color("3a3028"), "Chest")

	_afu_area = make_interactable("afu_talk", "对话·阿福伯", Vector2(690, 460), Vector2(100, 120), Color("6a5a48"), false)
	_afu_area.interacted.connect(_on_afu)
	make_interactable("comb", "查看·梳子", Vector2(200, 500), Vector2(50, 40), Color("8a7060"), true).interacted.connect(_on_comb)
	make_interactable("score", "查看·曲谱", Vector2(280, 490), Vector2(60, 50), Color("706050"), true).interacted.connect(_on_score)
	make_interactable("chest", "查看·旧木箱", Vector2(40, 500), Vector2(70, 50), Color("3a3028"), true).interacted.connect(_on_chest)

	_build_sort_ui()
	spawn_player(Vector2(150, 600), false)
	await say(["老头在里面。山本推门。"])
	status.text = "与阿福伯对话"


func _build_sort_ui() -> void:
	var hud := get_node("HUD") as CanvasLayer
	_sort_root = Control.new()
	_sort_root.name = "ClueSort"
	_sort_root.visible = false
	_sort_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_sort_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(_sort_root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sort_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(280, 70)
	panel.custom_minimum_size = Vector2(720, 0)
	_sort_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 10)
	margin.add_child(col)

	var title := Label.new()
	title.text = "S3-4 · 把他说的话理一遍"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("e8dcd0"))
	col.add_child(title)

	var hint := Label.new()
	hint.text = "用 ↑↓ 调整顺序，再确认。不是考智力，是亲手理一遍。"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("8a8078"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(hint)

	_card_list = VBoxContainer.new()
	_card_list.add_theme_constant_override("separation", 8)
	col.add_child(_card_list)

	_feedback = Label.new()
	_feedback.text = ""
	_feedback.add_theme_font_size_override("font_size", 14)
	_feedback.add_theme_color_override("font_color", Color("c08070"))
	col.add_child(_feedback)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	col.add_child(actions)

	var confirm := Button.new()
	confirm.text = "确认顺序"
	confirm.focus_mode = Control.FOCUS_NONE
	confirm.custom_minimum_size = Vector2(160, 36)
	confirm.pressed.connect(_on_confirm_order)
	actions.add_child(confirm)

	var reshuffle := Button.new()
	reshuffle.text = "打乱重排"
	reshuffle.focus_mode = Control.FOCUS_NONE
	reshuffle.custom_minimum_size = Vector2(120, 36)
	reshuffle.pressed.connect(_shuffle_and_refresh)
	actions.add_child(reshuffle)


func _set_world_interact(v: bool) -> void:
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is Interactable:
			(node as Interactable).set_enabled(v)


func _lock_scene() -> void:
	if player:
		player.locked = true
	_set_world_interact(false)


func _unlock_scene() -> void:
	_set_world_interact(true)
	if player:
		player.locked = false


func _show_sort() -> void:
	if GameState.has_flag("3c_clues") or _story_step >= 2:
		return
	_sorting = false
	_feedback.text = ""
	_shuffle_and_refresh()
	_sort_root.visible = true
	_lock_scene()
	status.text = "S3-4 · 线索拼凑 · 用 ↑↓ 调顺序"


func _hide_sort() -> void:
	_sort_root.visible = false


func _shuffle_and_refresh() -> void:
	_order.clear()
	for i in CLUE_CARDS.size():
		_order.append(i)
	# 打乱，避免开局已是正解
	for _n in 12:
		var a := randi() % _order.size()
		var b := randi() % _order.size()
		var tmp := _order[a]
		_order[a] = _order[b]
		_order[b] = tmp
	if _order_ok():
		var last := _order[_order.size() - 1]
		_order[_order.size() - 1] = _order[0]
		_order[0] = last
	_refresh_cards()


func _refresh_cards() -> void:
	for child in _card_list.get_children():
		child.queue_free()
	for slot in _order.size():
		var card_i: int = _order[slot]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var num := Label.new()
		num.text = "%d." % (slot + 1)
		num.custom_minimum_size = Vector2(28, 0)
		num.add_theme_font_size_override("font_size", 16)
		num.add_theme_color_override("font_color", Color("a89888"))
		row.add_child(num)

		var card := Button.new()
		card.text = str(CLUE_CARDS[card_i]["text"])
		card.focus_mode = Control.FOCUS_NONE
		card.alignment = HORIZONTAL_ALIGNMENT_LEFT
		card.custom_minimum_size = Vector2(420, 40)
		card.disabled = true
		row.add_child(card)

		var up := Button.new()
		up.text = "↑"
		up.focus_mode = Control.FOCUS_NONE
		up.custom_minimum_size = Vector2(44, 40)
		up.disabled = slot == 0
		up.pressed.connect(_move_card.bind(slot, -1))
		row.add_child(up)

		var down := Button.new()
		down.text = "↓"
		down.focus_mode = Control.FOCUS_NONE
		down.custom_minimum_size = Vector2(44, 40)
		down.disabled = slot == _order.size() - 1
		down.pressed.connect(_move_card.bind(slot, 1))
		row.add_child(down)

		_card_list.add_child(row)


func _move_card(slot: int, delta: int) -> void:
	if _sorting:
		return
	var dest := slot + delta
	if dest < 0 or dest >= _order.size():
		return
	var tmp := _order[slot]
	_order[slot] = _order[dest]
	_order[dest] = tmp
	_feedback.text = ""
	_refresh_cards()


func _order_ok() -> bool:
	for i in _order.size():
		if _order[i] != i:
			return false
	return true


func _on_confirm_order() -> void:
	if _sorting or not _sort_root.visible:
		return
	_sorting = true
	if _order_ok():
		_feedback.text = ""
		_hide_sort()
		_lock_scene()
		# 成功：一秒静默，不要「叮」
		await get_tree().create_timer(1.0).timeout
		await say([
			"山本：所以……有人把这个姑娘活活钉进了棺材？",
			"（阿福伯点头。不说话。）",
		], true)
		# 吞掉推进最后一句的 E/Space，避免同帧再触发阿福伯交互
		await get_tree().process_frame
		await get_tree().process_frame
		GameState.add_note("她的结局：被人活着钉进棺材，和死人合葬。")
		GameState.set_flag("3c_clues", true)
		GameState.puzzle_id = ""
		_story_step = 2
		if _afu_area:
			_afu_area.prompt_text = "对话·阿福伯（劝告）"
		_sorting = false
		_afu_busy = false
		_unlock_scene()
		status.text = "再与阿福伯对话"
	else:
		_feedback.text = "顺序还不对。再想想他是怎么开口的。"
		await get_tree().create_timer(0.6).timeout
		_sorting = false


func _on_comb(_by: PlayerController) -> void:
	if _afu_busy or _sort_root.visible:
		return
	await say(["木梳，缠着几根长发。"])


func _on_score(_by: PlayerController) -> void:
	if _afu_busy or _sort_root.visible:
		return
	await say(["手抄的曲谱，只抄了一半。最后一行没写完。"])


func _on_chest(_by: PlayerController) -> void:
	if _afu_busy or _sort_root.visible:
		return
	await say(["锁着。锁是新的。"])


func _on_afu(_by: PlayerController) -> void:
	# 防重入：对白/墨洗/解谜 await 之间若再按 E，会开第二条协程把进度打回
	if _afu_busy or _sorting or _sort_root.visible:
		return
	if GameState.has_flag("3d_afu_done"):
		return

	_afu_busy = true
	_lock_scene()
	match _story_step:
		0:
			GameState.puzzle_id = "clues"
			await say([
				"山本：老头。昨天晚上死了一个人，你知道什么。",
				"阿福伯：我……我什么都不知道……",
				"山本：这地方是你的地盘。说。这仙馆到底有什么问题。",
				"阿福伯：先生……这地方……不干净。",
				"山本：什么不干净？说清楚。",
				"阿福伯：七年前……有个姑娘……死在这口棺材里……",
				"山本：姑娘？什么姑娘。",
				"阿福伯：我不想说了……您放过我吧……",
				"山本：谁钉的。说名字。",
				"阿福伯：他们……他们……",
				"阿福伯：他们……他们……",
				"山本：说。",
				"阿福伯：她……她不是自杀……他们把她……钉进去了……",
				"阿福伯：活活钉进去的……和死人一起……合葬……",
			], true)
			await ink_wash(0.55, 0.05)
			await say([
				"（嫁衣下摆。苍白的手。指甲翻起。钉棺声。）",
				"（空灵，无字幕。）",
				"山本：……刚才，是什么。",
				"山本：错觉。累了。",
			], true)
			await ink_clear()
			await get_tree().process_frame
			_story_step = 1
			_afu_busy = false
			_show_sort()
		1:
			if GameState.has_flag("3c_clues"):
				_story_step = 2
				_afu_busy = false
				_unlock_scene()
				status.text = "再与阿福伯对话"
				return
			await say(["先把他刚说的话按顺序理一遍。"], true)
			await get_tree().process_frame
			_afu_busy = false
			_show_sort()
		2:
			await say([
				"阿福伯：先生……您要敬畏死灵……安抚怨魂……此事作罢吧……",
				"山本：敬畏死灵？安抚怨魂？你让我信这些鬼话？",
				"山本：中国人就是愚昧。迷信。不可信。",
				"山本：田中是被凶手杀的，不是什么鬼。我自己去查清楚。",
				"阿福伯：先生……您看不见的……比看得见的……更可怕……",
				"山本：愚昧。我自己去查。地下室那口棺材……一定有线索。",
			], true)
			GameState.set_flag("3d_afu_done", true)
			GameState.puzzle_id = ""
			status.text = "前往日记夜…"
			goto_scene(ScenePaths.DIARY_NIGHT)
		_:
			_afu_busy = false
			_unlock_scene()
