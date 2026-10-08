extends Node2D
class_name GreyboxLevel
## 几何占位关卡基类：房间壳、玩家、对白、HUD、跳转

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const DIALOGUE_SCENE := preload("res://scenes/ui/dialogue_box.tscn")

var player: PlayerController
var dialogue: DialogueBox
var status: Label
var fx_flash: Polygon2D
var ink_overlay: Polygon2D
var inv_label: Label
var note_panel: PanelContainer
var note_label: Label
var blackout: ColorRect
var _notes_open: bool = false


func setup_shell(room_w: float = 1280.0, title: String = "") -> void:
	add_child(_rect_poly(Vector2(-80, 0), Vector2(room_w + 160, 720), Color("1a1520"), -10, "BG"))
	add_child(_rect_poly(Vector2(-80, 600), Vector2(room_w + 160, 120), Color("2c2433"), -5, "FloorVis"))
	_add_static_box(Vector2(room_w * 0.5, 660), Vector2(room_w + 160, 80), "Floor")
	_add_static_box(Vector2(-40, 360), Vector2(80, 720), "WallL")
	_add_static_box(Vector2(room_w + 40, 360), Vector2(80, 720), "WallR")

	fx_flash = _rect_poly(Vector2(-100, 0), Vector2(room_w + 200, 720), Color(0.7, 0.05, 0.08, 0.0), 40, "RedFlash")
	add_child(fx_flash)
	ink_overlay = _rect_poly(Vector2(-100, 0), Vector2(room_w + 200, 720), Color(0.12, 0.11, 0.16, 0.0), 35, "InkOverlay")
	add_child(ink_overlay)

	_build_ui(title)
	if not GameState.inventory_changed.is_connected(_refresh_inv):
		GameState.inventory_changed.connect(_refresh_inv)
	_refresh_inv()


func spawn_player(pos: Vector2, locked: bool = false) -> void:
	player = PLAYER_SCENE.instantiate() as PlayerController
	player.position = pos
	add_child(player)
	player.locked = locked
	var cam := player.get_node_or_null("Camera2D") as Camera2D
	if cam:
		cam.limit_left = 0
		cam.limit_right = int(get_room_width())
		cam.limit_top = 0
		cam.limit_bottom = 720
		# 对白若暂停整树，带平滑的相机会停在原点，人在 y=600 会出画。
		cam.reset_smoothing()
		cam.force_update_scroll()


func get_room_width() -> float:
	return 1280.0


func _build_ui(title: String) -> void:
	dialogue = DIALOGUE_SCENE.instantiate() as DialogueBox
	add_child(dialogue)

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)

	status = Label.new()
	status.position = Vector2(24, 16)
	status.add_theme_color_override("font_color", Color("d8cfc4"))
	status.add_theme_font_size_override("font_size", 16)
	status.text = title
	hud.add_child(status)

	inv_label = Label.new()
	inv_label.position = Vector2(24, 40)
	inv_label.add_theme_color_override("font_color", Color("b8a898"))
	inv_label.add_theme_font_size_override("font_size", 14)
	hud.add_child(inv_label)

	var help := Label.new()
	help.text = "A/D 移动 · E 调查 · Space 继续 · Tab 手记 · H 香火 · F1 跳关 · F11 全屏"
	help.position = Vector2(24, 680)
	help.add_theme_color_override("font_color", Color("8a8078"))
	help.add_theme_font_size_override("font_size", 14)
	hud.add_child(help)

	blackout = ColorRect.new()
	blackout.color = Color(0, 0, 0, 0)
	blackout.mouse_filter = Control.MOUSE_FILTER_IGNORE
	blackout.name = "Blackout"
	blackout.size = Vector2(1920, 1080)
	hud.add_child(blackout)
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	note_panel = PanelContainer.new()
	note_panel.visible = false
	note_panel.position = Vector2(360, 80)
	note_panel.size = Vector2(560, 420)
	hud.add_child(note_panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	note_panel.add_child(margin)
	note_label = Label.new()
	note_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_label.add_theme_font_size_override("font_size", 16)
	note_label.add_theme_color_override("font_color", Color("d8cfc4"))
	margin.add_child(note_label)


func say(lines: Array, keep_locked: bool = false) -> void:
	if player:
		player.locked = true
	var typed: Array[String] = []
	for line in lines:
		typed.append(str(line))
	dialogue.play(typed)
	await dialogue.finished
	if player and not keep_locked:
		player.locked = false


func _refresh_inv() -> void:
	if inv_label:
		inv_label.text = "%s    香火 · %d支" % [GameState.bag_text(), GameState.incense]


func _unhandled_input(event: InputEvent) -> void:
	if dialogue and dialogue.is_open():
		return
	if event.is_action_pressed("notebook"):
		_toggle_notes()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("hint"):
		get_viewport().set_input_as_handled()
		_do_hint()


func _toggle_notes() -> void:
	_notes_open = not _notes_open
	note_panel.visible = _notes_open
	if _notes_open:
		if GameState.notes.is_empty():
			note_label.text = "手记\n\n还没记下什么。"
		else:
			note_label.text = "手记\n\n· " + "\n· ".join(PackedStringArray(GameState.notes))


func _do_hint() -> void:
	var line := GameState.use_hint()
	await say([line])


func ink_wash(peak: float = 0.55, hold: float = 0.2) -> void:
	var t := create_tween()
	t.tween_method(_set_ink_alpha, ink_overlay.color.a, peak, 0.25)
	await t.finished
	if hold > 0.0:
		await get_tree().create_timer(hold).timeout


func ink_clear() -> void:
	var t := create_tween()
	t.tween_method(_set_ink_alpha, ink_overlay.color.a, 0.0, 0.3)
	await t.finished


func _set_ink_alpha(a: float) -> void:
	var c := ink_overlay.color
	c.a = a
	ink_overlay.color = c


func set_black(a: float) -> void:
	if blackout:
		blackout.color = Color(0, 0, 0, a)


func flash_frame(duration: float = 0.3) -> void:
	set_black(0.85)
	status.text = "咚　咚　咚"
	await get_tree().create_timer(duration).timeout
	set_black(0.0)


func goto_scene(path: String) -> void:
	get_tree().change_scene_to_file(path)


func red_flash() -> void:
	var t := create_tween()
	t.tween_method(_set_flash_alpha, 0.0, 0.45, 0.12)
	t.tween_method(_set_flash_alpha, 0.45, 0.0, 0.55)
	await t.finished


func _set_flash_alpha(a: float) -> void:
	var c := fx_flash.color
	c.a = a
	fx_flash.color = c


func add_label_at(pos: Vector2, text: String, color: Color = Color("8a8078")) -> Label:
	var lab := Label.new()
	lab.text = text
	lab.position = pos
	lab.add_theme_color_override("font_color", color)
	lab.add_theme_font_size_override("font_size", 14)
	add_child(lab)
	return lab


func add_prop(pos: Vector2, size: Vector2, color: Color, node_name: String) -> Polygon2D:
	var p := _rect_poly(pos, size, color, 0, node_name)
	add_child(p)
	return p


func make_interactable(
	id: String, prompt: String, pos: Vector2, size: Vector2, color: Color, once: bool = false
) -> Interactable:
	var area := Interactable.new()
	area.name = "Interact_%s" % id
	area.interact_id = id
	area.prompt_text = prompt
	area.once = once
	area.position = pos
	area.collision_layer = 4
	area.collision_mask = 2
	area.monitoring = true
	area.monitorable = true
	# 脚底可触：碰撞盒向下延伸到接近地面
	var hit_h: float = maxf(size.y, 160.0)
	var hit_w: float = maxf(size.x, 70.0)
	area.interact_radius = maxf(110.0, hit_w * 0.9)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(hit_w, hit_h)
	shape.shape = rect
	shape.position = Vector2(size.x * 0.5, hit_h * 0.55)
	area.add_child(shape)

	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)
	])
	vis.color = color
	area.add_child(vis)

	var tag := Label.new()
	tag.text = id
	tag.position = Vector2(2, -20)
	tag.add_theme_font_size_override("font_size", 12)
	tag.add_theme_color_override("font_color", Color("e8e0d5"))
	area.add_child(tag)

	add_child(area)
	return area


func _add_static_box(center: Vector2, size: Vector2, node_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.position = center
	body.collision_layer = 1
	body.collision_mask = 0
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	body.add_child(shape)
	add_child(body)


func _rect_poly(pos: Vector2, size: Vector2, color: Color, z: int, node_name: String) -> Polygon2D:
	var p := Polygon2D.new()
	p.name = node_name
	p.position = pos
	p.color = color
	p.z_index = z
	p.polygon = PackedVector2Array([
		Vector2.ZERO, Vector2(size.x, 0), size, Vector2(0, size.y)
	])
	return p
