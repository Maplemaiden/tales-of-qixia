extends CanvasLayer
## 灰盒跳关：F1 开关。重置进度并补齐该场前置道具/旗标。

const ENTRIES: Array[Dictionary] = [
	{"key": KEY_1, "title": "1  开场警告 / NAR", "scene": ScenePaths.OPENING, "seed": "start"},
	{"key": KEY_2, "title": "2  S1-1 病房", "scene": ScenePaths.WARD_1A, "seed": "ward"},
	{"key": KEY_3, "title": "3  S1-2 走廊", "scene": ScenePaths.CORRIDOR_1B, "seed": "corridor"},
	{"key": KEY_4, "title": "4  S1-3 密室门", "scene": ScenePaths.BASEMENT_DOOR, "seed": "basement"},
	{"key": KEY_5, "title": "5  S1-3 找钥匙", "scene": ScenePaths.KEY_HUNT, "seed": "basement"},
	{"key": KEY_6, "title": "6  S1-4 密室 · 合棺", "scene": ScenePaths.SEAL_1C, "seed": "seal"},
	{"key": KEY_7, "title": "7  第二幕 办公室", "scene": ScenePaths.OFFICE_2, "seed": "office"},
	{"key": KEY_8, "title": "8  S3-1 经堂", "scene": ScenePaths.JING_TANG, "seed": "jing"},
	{"key": KEY_9, "title": "9  S3-2 阿福伯小屋", "scene": ScenePaths.HUT_3, "seed": "hut"},
	{"key": KEY_0, "title": "0  S3-6 日记夜", "scene": ScenePaths.DIARY_NIGHT, "seed": "diary"},
	{"key": KEY_MINUS, "title": "-  第四幕 密室", "scene": ScenePaths.CHAMBER_4, "seed": "chamber"},
	{"key": KEY_EQUAL, "title": "=  结束卡", "scene": ScenePaths.DEMO_END, "seed": "end"},
]

var _open: bool = false
var _dim: ColorRect
var _panel: PanelContainer


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_set_open(false)


func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.05, 0.04, 0.06, 0.72)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.gui_input.connect(_on_dim_input)
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.position = Vector2(24, 56)
	_panel.custom_minimum_size = Vector2(420, 0)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_panel.add_child(margin)

	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 6)
	margin.add_child(col)

	var title := Label.new()
	title.text = "调试跳关"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("e8dcd0"))
	col.add_child(title)

	var hint := Label.new()
	hint.text = "F1 开关 · Esc 关闭 · 数字键直达\n会重置进度，并补齐进入该场需要的皮箱与旗标。"
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color("8a8078"))
	col.add_child(hint)

	for entry in ENTRIES:
		var btn := Button.new()
		btn.text = str(entry["title"])
		btn.focus_mode = Control.FOCUS_NONE
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size = Vector2(0, 28)
		btn.pressed.connect(_warp.bind(entry))
		col.add_child(btn)


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_set_open(false)


func _set_open(v: bool) -> void:
	_open = v
	_dim.visible = v
	_panel.visible = v
	var tree := get_tree()
	if tree:
		tree.paused = v


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_warp"):
		_set_open(not _open)
		get_viewport().set_input_as_handled()
		return
	if not _open:
		return
	if event.is_action_pressed("ui_cancel"):
		_set_open(false)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k := _normalize_key(event)
		for entry in ENTRIES:
			if k == int(entry["key"]):
				_warp(entry)
				get_viewport().set_input_as_handled()
				return


func _normalize_key(event: InputEventKey) -> int:
	var k := event.keycode
	match k:
		KEY_KP_1:
			return KEY_1
		KEY_KP_2:
			return KEY_2
		KEY_KP_3:
			return KEY_3
		KEY_KP_4:
			return KEY_4
		KEY_KP_5:
			return KEY_5
		KEY_KP_6:
			return KEY_6
		KEY_KP_7:
			return KEY_7
		KEY_KP_8:
			return KEY_8
		KEY_KP_9:
			return KEY_9
		KEY_KP_0:
			return KEY_0
		KEY_KP_SUBTRACT:
			return KEY_MINUS
		KEY_KP_ADD:
			return KEY_EQUAL
	if k == KEY_NONE:
		k = event.physical_keycode
	return k


func _warp(entry: Dictionary) -> void:
	_set_open(false)
	var tree := get_tree()
	if tree:
		tree.paused = false
	GameState.reset()
	_apply_seed(str(entry["seed"]))
	tree.change_scene_to_file(str(entry["scene"]))


func _apply_seed(kind: String) -> void:
	match kind:
		"start", "ward":
			return
		"corridor":
			_seed_act1_leave_ward()
		"basement":
			_seed_act1_leave_ward()
			_seed_act1_corridor()
		"seal":
			_seed_act1_leave_ward()
			_seed_act1_corridor()
			GameState.add_item("key")
			GameState.set_flag("1c_door_open")
		"office":
			_seed_through_act1()
		"jing":
			_seed_through_act2()
		"hut":
			_seed_through_act2()
			GameState.add_item("mask_frag", 2)
			GameState.set_flag("3a_masks")
			GameState.set_flag("3a_frags")
		"diary":
			_seed_through_act2()
			GameState.add_item("mask_frag", 2)
			GameState.set_flag("3a_masks")
			GameState.set_flag("3a_frags")
			GameState.set_flag("3c_clues")
			GameState.set_flag("3d_afu_done")
		"chamber":
			_seed_through_act2()
			GameState.add_item("mask_frag", 2)
			GameState.set_flag("3a_frags")
			GameState.set_flag("3e_complete")
		"end":
			_seed_through_act2()
			GameState.add_item("mask_frag", 7)
			GameState.set_flag("demo_complete")


func _seed_act1_leave_ward() -> void:
	GameState.add_item("photo")
	GameState.add_item("form")
	GameState.set_flag("1a_stood_up")
	GameState.set_flag("1a_photo_seen")
	GameState.set_flag("1a_papers_seen")
	GameState.set_flag("1a_opera_heard")
	GameState.set_flag("1a_complete")


func _seed_act1_corridor() -> void:
	GameState.add_item("matches")
	GameState.set_flag("1b_all_inspected")
	GameState.set_flag("1b_complete")


func _seed_through_act1() -> void:
	_seed_act1_leave_ward()
	_seed_act1_corridor()
	GameState.add_item("key")
	GameState.set_flag("1c_door_open")
	GameState.set_flag("1c_identified")
	GameState.set_flag("1d_complete")
	GameState.set_flag("act1_complete")


func _seed_through_act2() -> void:
	_seed_through_act1()
	GameState.add_item("lamp")
	GameState.add_item("flashlight")
	GameState.set_flag("2b_flashlight")
	GameState.set_flag("2d_complete")
