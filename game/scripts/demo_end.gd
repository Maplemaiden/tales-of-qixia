extends Control
## Demo 结束页


func _ready() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color("120e14")
	bg.set_anchors_preset(PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "栖霞诡事 · Demo Greybox CLEAR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(PRESET_CENTER)
	title.offset_top = -80
	title.offset_bottom = -40
	title.offset_left = -300
	title.offset_right = 300
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("e8dcd0"))
	add_child(title)

	var body := Label.new()
	body.text = "已跑通：1A→1B→1C/1D→2→3→4\n美术均为几何占位。\n\nR 键：从 1A 重开\nEsc：退出游戏"
	body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.set_anchors_preset(PRESET_CENTER)
	body.offset_top = -10
	body.offset_bottom = 120
	body.offset_left = -320
	body.offset_right = 320
	body.add_theme_font_size_override("font_size", 16)
	body.add_theme_color_override("font_color", Color("a09080"))
	add_child(body)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().quit()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().change_scene_to_file(ScenePaths.WARD_1A)
