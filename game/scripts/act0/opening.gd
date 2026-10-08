extends Control
## 开场：内容警告 + 标题卡 + 冷旁白 NAR-01 / NAR-02


func _ready() -> void:
	GameState.reset()
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("0c0a0e")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var lab := Label.new()
	lab.name = "Body"
	lab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lab.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lab.set_anchors_preset(PRESET_FULL_RECT)
	lab.add_theme_font_size_override("font_size", 22)
	lab.add_theme_color_override("font_color", Color("c8c0b8"))
	lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lab.offset_left = 160
	lab.offset_right = -160
	add_child(lab)

	var hint := Label.new()
	hint.text = "Space / E · 继续　　F1 跳关　　右上角可切换全屏 · Esc 退出全屏"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.set_anchors_preset(PRESET_BOTTOM_WIDE)
	hint.offset_top = -48
	hint.offset_bottom = -16
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color("6a6058"))
	add_child(hint)

	await _run(lab)


func _run(lab: Label) -> void:
	lab.text = "本作含封闭空间、窒息、突发惊吓内容。请酌情游玩。\n若对闪烁光线敏感，建议稍后在设置中关闭画面闪烁。\n建议佩戴耳机游玩。"
	await _wait_advance()
	lab.text = "破封\n\n民国三十一年 · 秋 · 夜雨\n栖霞仙馆"
	await _wait_advance()
	lab.text = "民国三十一年，秋。雨下了七天。"
	await _wait_advance()
	lab.text = "这座宅子原是人家的宅院，如今住了兵。"
	await _wait_advance()
	get_tree().change_scene_to_file(ScenePaths.WARD_1A)


func _wait_advance() -> void:
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("ui_advance") or Input.is_action_just_pressed("interact"):
			break
