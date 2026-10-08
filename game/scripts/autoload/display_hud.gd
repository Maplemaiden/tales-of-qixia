extends CanvasLayer
## 全局窗口控制：默认窗口化；按钮 / F11 切换全屏；Esc 退出全屏

const DESIGN := Vector2i(1280, 720)

var _btn: Button


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_button()
	_apply_windowed()
	_refresh_label()


func _build_button() -> void:
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	_btn = Button.new()
	_btn.focus_mode = Control.FOCUS_NONE
	_btn.process_mode = Node.PROCESS_MODE_ALWAYS
	_btn.custom_minimum_size = Vector2(96, 32)
	_btn.tooltip_text = "F11 切换全屏 · Esc 退出全屏"
	_btn.pressed.connect(toggle_fullscreen)
	root.add_child(_btn)
	_btn.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_btn.offset_left = -120.0
	_btn.offset_top = 16.0
	_btn.offset_right = -16.0
	_btn.offset_bottom = 48.0


func is_fullscreen() -> bool:
	var mode := DisplayServer.window_get_mode()
	return (
		mode == DisplayServer.WINDOW_MODE_FULLSCREEN
		or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	)


func toggle_fullscreen() -> void:
	if is_fullscreen():
		_apply_windowed()
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	_refresh_label()


func _apply_windowed() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var usable := DisplayServer.screen_get_usable_rect()
	var w: int = mini(DESIGN.x, maxi(960, usable.size.x - 48))
	var h: int = mini(DESIGN.y, maxi(540, usable.size.y - 96))
	if float(w) / float(h) > 16.0 / 9.0:
		w = int(round(h * 16.0 / 9.0))
	else:
		h = int(round(w * 9.0 / 16.0))
	w = mini(w, usable.size.x)
	h = mini(h, usable.size.y)
	DisplayServer.window_set_size(Vector2i(w, h))
	var pos := usable.position + (usable.size - Vector2i(w, h)) / 2
	DisplayServer.window_set_position(pos)
	DisplayServer.window_set_min_size(Vector2i(960, 540))


func _refresh_label() -> void:
	if _btn:
		_btn.text = "窗口" if is_fullscreen() else "全屏"


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen_toggle"):
		toggle_fullscreen()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and is_fullscreen():
		_apply_windowed()
		_refresh_label()
		get_viewport().set_input_as_handled()
