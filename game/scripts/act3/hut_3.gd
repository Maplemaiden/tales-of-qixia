extends GreyboxLevel
## 第三幕：阿福伯挤牙膏式讲述 + 阿霞一闪穿插（剧情设计 v1.1）

var _story_step: int = 0
var _ink_overlay: Polygon2D


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	setup_shell(1280.0, "3A · 阿福伯小屋")
	add_prop(Vector2(700, 450), Vector2(80, 120), Color("5a5040"), "Afu")
	add_prop(Vector2(200, 480), Vector2(50, 40), Color("8a7060"), "Comb")
	add_prop(Vector2(280, 470), Vector2(60, 50), Color("706050"), "Score")
	add_prop(Vector2(360, 480), Vector2(40, 40), Color("9a8060"), "Relic")

	make_interactable("afu_talk", "对话·阿福伯", Vector2(690, 460), Vector2(100, 120), Color("6a5a48"), false).interacted.connect(_on_afu)
	make_interactable("comb", "调查·梳子", Vector2(200, 500), Vector2(50, 40), Color("8a7060"), true).interacted.connect(_on_comb)
	make_interactable("score", "调查·曲谱", Vector2(280, 490), Vector2(60, 50), Color("706050"), true).interacted.connect(_on_score)
	make_interactable("relic", "调查·旧物", Vector2(360, 500), Vector2(40, 40), Color("9a8060"), true).interacted.connect(_on_relic)

	_ink_overlay = _rect_poly(Vector2(-50, 0), Vector2(1400, 720), Color(0.12, 0.11, 0.16, 0.0), 30, "InkOverlay")
	add_child(_ink_overlay)

	spawn_player(Vector2(150, 600), false)
	await say([
		"【第三幕】山本找到阿福伯，持枪逼问仙馆之事。",
		"阿福伯恐惧抵触——只会挤牙膏式吐露。屋内遗物可查，不触发主穿插。",
	])
	status.text = "与阿福伯对话推进剧情（1/3）"


func _on_comb(_by: PlayerController) -> void:
	await say(["一把旧木梳，齿间还缠着一缕黑发。与主线无关。"])


func _on_score(_by: PlayerController) -> void:
	await say(["残缺曲谱，隐约是《帝女花》的片段。与主线无关。"])


func _on_relic(_by: PlayerController) -> void:
	await say(["蒙尘的小物件。摸不到真相，只能摸到灰尘。"])


func _on_afu(_by: PlayerController) -> void:
	match _story_step:
		0:
			# 挤牙膏讲述（最低限度信息）
			await say([
				"山本：（严厉）老头！昨天晚上死了一个人，你知道什么？",
				"阿福伯：（颤抖，回避眼神）先生……这地方……不干净……",
				"山本：（不耐烦）什么不干净？说清楚！",
				"阿福伯：七年前……有个姑娘……死在这口棺材里……",
				"山本：姑娘？什么姑娘？",
				"阿福伯：（摇头）我不想说了……您放过我吧……",
				"山本：（举枪威胁）说！",
				"阿福伯：（被迫，断续）她……她不是自杀……他们把她……钉进去了……",
				"山本：钉进去？什么意思？",
				"阿福伯：（痛苦，闭眼）活活钉进去的……和死人一起……合葬……",
			])
			# 阿霞穿插·一闪而过（10–15 秒信息量）
			await _insert_axia([
				"【阿霞穿插·一闪而过】水墨晕染，极短。",
				"只见嫁衣下摆与苍白的手。咚、咚、咚——钉棺。指甲抓挠木板。",
				"阿霞：（空灵，极短）放我出去……",
				"画面切回。不露脸、不解释原因。",
			])
			await say([
				"山本愣了一下，以为是错觉。阿福伯低着头，不敢看他。",
			])
			_story_step = 1
			status.text = "继续与阿福伯对话（2/3）· 劝告"
		1:
			await say([
				"阿福伯：先生……您要敬畏死灵……安抚怨魂……此事作罢吧……不要再查了……",
				"山本：（爆发）敬畏死灵？你让我相信这些鬼话？！中国人就是愚昧！迷信！",
				"山本：我是军医，我只信科学。我自己去查。地下室的棺材……一定有线索。",
			])
			await say([
				"阿福伯沉默良久，叹息，起身走向门口。",
				"阿福伯：（回头，低声）先生……您看不见的……比看得见的……更可怕……",
				"他摇头离开。背影苍老而绝望。山本冷哼一声。",
			])
			_story_step = 2
			GameState.set_flag("3d_afu_done", true)
			await say(["夜色渐深。山本决定回办公室写日记……"])
			goto_scene(ScenePaths.DIARY_NIGHT)
		_:
			await say(["屋里只剩雨声。阿福伯已经走了。"])


func _insert_axia(lines: Array) -> void:
	var tw := create_tween()
	tw.tween_method(func(a: float): _ink_overlay.color.a = a, 0.0, 0.55, 0.25)
	await tw.finished
	await say(lines)
	var tw2 := create_tween()
	tw2.tween_method(func(a: float): _ink_overlay.color.a = a, 0.55, 0.0, 0.25)
	await tw2.finished
