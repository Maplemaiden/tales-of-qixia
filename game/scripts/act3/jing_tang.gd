extends GreyboxLevel
## S3-1 后园经堂：反挂面具 + 碎片 ×2


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	setup_shell(1280.0, "S3-1 · 后园经堂")
	add_prop(Vector2(200, 180), Vector2(220, 160), Color("3a3428"), "Altar")
	add_label_at(Vector2(240, 200), "香案", Color("c4a050"))
	for i in 7:
		add_prop(Vector2(160.0 + i * 70.0, 80), Vector2(40, 50), Color("6a3030"), "Hang%d" % i)
	add_prop(Vector2(980, 500), Vector2(70, 40), Color("8a7060"), "FragsVis")

	make_interactable("altar", "查看·香案", Vector2(220, 430), Vector2(120, 70), Color("5a5040"), true).interacted.connect(_on_altar)
	make_interactable("masks", "查看·梁上傩面具", Vector2(300, 420), Vector2(100, 70), Color("8b3030"), false).interacted.connect(_on_masks)
	make_interactable("frags", "拾取·面具碎片", Vector2(960, 480), Vector2(90, 50), Color("c4a050"), true).interacted.connect(_on_frags)
	make_interactable("tree", "查看·榕树", Vector2(40, 480), Vector2(70, 70), Color("2a4030"), true).interacted.connect(_on_tree)
	make_interactable("hut", "去阿福伯小屋", Vector2(1180, 420), Vector2(70, 140), Color("5a4030"), false).interacted.connect(_on_hut)

	spawn_player(Vector2(150, 600), false)
	await say([
		"同一个白天。后园的香火，已经很久没有人上过。",
		"（第三幕不给标题卡。）",
	])
	status.text = "查看经堂 · 拾取墙角碎片 · 去小屋"


func _on_altar(_by: PlayerController) -> void:
	await say(["香灰积了很厚。佛像的脸看不清了。"])


func _on_masks(_by: PlayerController) -> void:
	GameState.add_note("傩面具：倒挂，脸朝墙。背面有半个字。")
	if GameState.has_flag("3a_masks"):
		await say(["背面刻着半个字。看不全。"])
		return
	GameState.set_flag("3a_masks", true)
	await say([
		"傩面具，倒挂在梁上。脸朝着墙。",
		"山本：倒着挂。……中国人讲究这个？",
	])


func _on_frags(_by: PlayerController) -> void:
	GameState.add_item("mask_frag", 2)
	GameState.set_flag("3a_frags", true)
	await say(["拾取：傩舞面具碎片 ×2", "木雕面具的碎片。背面刻着半个字。"])
	status.text = "右侧去小屋"


func _on_tree(_by: PlayerController) -> void:
	await say(["树根把石阶拱裂了。"])


func _on_hut(_by: PlayerController) -> void:
	if not GameState.has_flag("3a_frags"):
		await say(["墙角那堆木头，先捡起来。"])
		return
	goto_scene(ScenePaths.HUT_3)
