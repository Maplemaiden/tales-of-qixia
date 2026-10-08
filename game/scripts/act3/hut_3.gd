extends GreyboxLevel
## S3-2 挤牙膏 + S3-3 一闪 + S3-4 结论三选一 + S3-5 劝告辱骂


const CHOICES := [
	{
		"id": "suicide",
		"text": "她是自己寻的死。",
		"ok": false,
		"reply": [
			"山本：自己寻的死？……那钉子是谁钉的。",
			"阿福伯：先生……不是这样的。",
		],
	},
	{
		"id": "ghost",
		"text": "田中是被鬼杀死的。",
		"ok": false,
		"reply": [
			"山本：鬼？田中是被凶手杀的。不是什么鬼。",
			"阿福伯：先生……不是这样的。",
		],
	},
	{
		"id": "coffin",
		"text": "有人把这个姑娘活着钉进了棺材，和死人葬在一起。",
		"ok": true,
		"reply": [],
	},
]

var _story_step: int = 0
var _choice_root: Control
var _picking: bool = false


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	setup_shell(1280.0, "S3-2 · 阿福伯小屋")
	add_prop(Vector2(700, 450), Vector2(80, 120), Color("5a5040"), "Afu")
	add_prop(Vector2(200, 480), Vector2(50, 40), Color("8a7060"), "Comb")
	add_prop(Vector2(280, 470), Vector2(60, 50), Color("706050"), "Score")
	add_prop(Vector2(40, 500), Vector2(70, 50), Color("3a3028"), "Chest")

	make_interactable("afu_talk", "对话·阿福伯", Vector2(690, 460), Vector2(100, 120), Color("6a5a48"), false).interacted.connect(_on_afu)
	make_interactable("comb", "查看·梳子", Vector2(200, 500), Vector2(50, 40), Color("8a7060"), true).interacted.connect(_on_comb)
	make_interactable("score", "查看·曲谱", Vector2(280, 490), Vector2(60, 50), Color("706050"), true).interacted.connect(_on_score)
	make_interactable("chest", "查看·旧木箱", Vector2(40, 500), Vector2(70, 50), Color("3a3028"), true).interacted.connect(_on_chest)

	_build_choice_ui()
	spawn_player(Vector2(150, 600), false)
	await say(["老头在里面。山本推门。"])
	status.text = "与阿福伯对话"


func _build_choice_ui() -> void:
	var hud := get_node("HUD") as CanvasLayer
	_choice_root = Control.new()
	_choice_root.name = "ConclusionChoice"
	_choice_root.visible = false
	_choice_root.mouse_filter = Control.MOUSE_FILTER_STOP
	_choice_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(_choice_root)

	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.04, 0.06, 0.58)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_choice_root.add_child(dim)

	var panel := PanelContainer.new()
	panel.position = Vector2(260, 140)
	panel.custom_minimum_size = Vector2(760, 0)
	_choice_root.add_child(panel)

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
	title.text = "你听懂了什么。"
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("e8dcd0"))
	col.add_child(title)

	var hint := Label.new()
	hint.text = "选一句。不是复述，是判断。"
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("8a8078"))
	col.add_child(hint)

	for i in CHOICES.size():
		var btn := Button.new()
		btn.text = "%d  %s" % [i + 1, str(CHOICES[i]["text"])]
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 40)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.pressed.connect(_on_pick.bind(i))
		col.add_child(btn)


func _set_world_interact(v: bool) -> void:
	for node in get_tree().get_nodes_in_group("interactable"):
		if node is Interactable:
			(node as Interactable).set_enabled(v)


func _show_choices() -> void:
	_choice_root.visible = true
	if player:
		player.locked = true
	_set_world_interact(false)
	status.text = "S3-4 · 你听懂了什么"


func _hide_choices() -> void:
	_choice_root.visible = false


func _unhandled_input(event: InputEvent) -> void:
	if _choice_root and _choice_root.visible and not _picking and event is InputEventKey and event.pressed and not event.echo:
		var key := event as InputEventKey
		var n: int = key.keycode
		if n >= KEY_1 and n <= KEY_3:
			_on_pick(n - KEY_1)
			get_viewport().set_input_as_handled()
			return
		if n >= KEY_KP_1 and n <= KEY_KP_3:
			_on_pick(n - KEY_KP_1)
			get_viewport().set_input_as_handled()
			return
	super._unhandled_input(event)


func _on_comb(_by: PlayerController) -> void:
	await say(["木梳，缠着几根长发。"])


func _on_score(_by: PlayerController) -> void:
	await say(["手抄的曲谱，只抄了一半。最后一行没写完。"])


func _on_chest(_by: PlayerController) -> void:
	await say(["锁着。锁是新的。"])


func _on_afu(_by: PlayerController) -> void:
	if _choice_root.visible or _picking:
		return
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
			])
			await ink_wash(0.55, 0.05)
			await say([
				"（嫁衣下摆。苍白的手。指甲翻起。钉棺声。）",
				"（空灵，无字幕。）",
				"山本：……刚才，是什么。",
				"山本：错觉。累了。",
			])
			await ink_clear()
			_story_step = 1
			_show_choices()
		1:
			await say(["先想清楚。他刚说的，到底是什么意思。"])
		2:
			await say([
				"阿福伯：先生……您要敬畏死灵……安抚怨魂……此事作罢吧……",
				"山本：敬畏死灵？安抚怨魂？你让我信这些鬼话？",
				"山本：中国人就是愚昧。迷信。不可信。",
				"山本：田中是被凶手杀的，不是什么鬼。我自己去查清楚。",
				"阿福伯：先生……您看不见的……比看得见的……更可怕……",
				"山本：愚昧。我自己去查。地下室那口棺材……一定有线索。",
			])
			GameState.set_flag("3d_afu_done", true)
			GameState.puzzle_id = ""
			goto_scene(ScenePaths.DIARY_NIGHT)


func _on_pick(index: int) -> void:
	if _picking or not _choice_root.visible:
		return
	if index < 0 or index >= CHOICES.size():
		return
	_picking = true
	_hide_choices()
	var choice: Dictionary = CHOICES[index]
	if bool(choice["ok"]):
		await get_tree().create_timer(1.0).timeout
		await say([
			"山本：所以……有人把这个姑娘活活钉进了棺材？",
			"（阿福伯点头。不说话。）",
		])
		GameState.add_note("她的结局：被人活着钉进棺材，和死人合葬。")
		GameState.set_flag("3c_clues", true)
		GameState.puzzle_id = ""
		_story_step = 2
		_set_world_interact(true)
		if player:
			player.locked = false
		status.text = "再与阿福伯对话"
	else:
		var reply: Array = choice["reply"]
		await say(reply)
		_picking = false
		_show_choices()
		return
	_picking = false
