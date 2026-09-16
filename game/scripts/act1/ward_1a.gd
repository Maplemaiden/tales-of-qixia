extends Node2D
## Demo 第一幕 1A · 临时病房（几何占位）
## 流程：起身 →（可选）调查照片 → 粤曲/红影提示 → 出门完成

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const DIALOGUE_SCENE := preload("res://scenes/ui/dialogue_box.tscn")

var _player: PlayerController
var _dialogue: DialogueBox
var _fx_flash: Polygon2D
var _status: Label
var _opera_triggered: bool = false
var _opera_scheduled: bool = false


func _ready() -> void:
	_build_world()
	_build_player()
	_build_ui()
	_boot_sequence()


func _boot_sequence() -> void:
	_player.locked = true
	await get_tree().create_timer(0.2).timeout
	_dialogue.play([
		"【第一幕 · 1A 临时病房】",
		"雨夜。田中躺在靠窗的床上，左臂缠着绷带。",
		"按 E 起身。可调查床头照片。听到异响后，从左侧门离开。",
	])
	await _dialogue.finished
	# 起身点仍可用；未起身时 locked 在床边由 get_up 解锁
	_player.locked = true
	_status.text = "目标：靠近床上的起身点，按 E 起身"


func _build_world() -> void:
	var bg := _rect_poly(Vector2(-160, 0), Vector2(1600, 720), Color("1a1520"), -10, "BG")
	add_child(bg)
	add_child(_rect_poly(Vector2(-160, 600), Vector2(1600, 120), Color("2c2433"), -5, "FloorVis"))

	_add_static_box(Vector2(640, 660), Vector2(1600, 80), "Floor")
	_add_static_box(Vector2(-40, 360), Vector2(80, 720), "WallL")
	_add_static_box(Vector2(1320, 360), Vector2(80, 720), "WallR")

	add_child(_rect_poly(Vector2(980, 120), Vector2(160, 100), Color("3d4a5c"), 0, "Window"))
	var rain := Label.new()
	rain.text = "｜雨｜"
	rain.position = Vector2(1025, 155)
	rain.add_theme_color_override("font_color", Color("8a9bb0"))
	add_child(rain)

	add_child(_rect_poly(Vector2(200, 520), Vector2(100, 40), Color("3a3040"), 0, "BedNPC1"))
	add_child(_rect_poly(Vector2(360, 520), Vector2(100, 40), Color("3a3040"), 0, "BedNPC2"))
	add_child(_rect_poly(Vector2(860, 520), Vector2(120, 44), Color("4a3548"), 0, "BedTanaka"))

	var get_up := _make_interactable(
		"get_up", "起身", Vector2(880, 470), Vector2(100, 90), Color("6b4a5a"), true
	)
	get_up.interacted.connect(_on_get_up)

	var photo := _make_interactable(
		"photo", "调查·家人照片", Vector2(1020, 470), Vector2(40, 52), Color("c4a574"), false
	)
	photo.interacted.connect(_on_photo)

	var door := _make_interactable(
		"door", "离开病房", Vector2(40, 420), Vector2(56, 140), Color("5a4030"), false
	)
	door.interacted.connect(_on_door)

	_fx_flash = _rect_poly(Vector2(-200, 0), Vector2(1800, 720), Color(0.7, 0.05, 0.08, 0.0), 40, "RedFlash")
	add_child(_fx_flash)


func _build_player() -> void:
	_player = PLAYER_SCENE.instantiate() as PlayerController
	_player.position = Vector2(930, 600)
	add_child(_player)
	_player.locked = true


func _build_ui() -> void:
	_dialogue = DIALOGUE_SCENE.instantiate() as DialogueBox
	add_child(_dialogue)

	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)

	_status = Label.new()
	_status.position = Vector2(24, 16)
	_status.add_theme_color_override("font_color", Color("d8cfc4"))
	_status.add_theme_font_size_override("font_size", 16)
	hud.add_child(_status)

	var help := Label.new()
	help.text = "A/D 移动 · E 调查 · Space 继续"
	help.position = Vector2(24, 680)
	help.add_theme_color_override("font_color", Color("8a8078"))
	help.add_theme_font_size_override("font_size", 14)
	hud.add_child(help)


func _on_get_up(_by: PlayerController) -> void:
	_player.locked = false
	GameState.set_flag("1a_stood_up", true)
	_player.locked = true
	_dialogue.play([
		"田中：（低声）……再忍忍。等打完仗就回家。",
		"他撑着床沿站起身。窗外雨声不断。",
	])
	await _dialogue.finished
	_player.locked = false
	_status.text = "可调查床头照片 · 留意窗外 · 从左侧门离开"
	_schedule_opera_cue()


func _schedule_opera_cue() -> void:
	if _opera_triggered or _opera_scheduled:
		return
	_opera_scheduled = true
	await get_tree().create_timer(2.5).timeout
	if _opera_triggered or not GameState.has_flag("1a_stood_up"):
		return
	_opera_triggered = true
	GameState.set_flag("1a_opera_heard", true)
	await _red_flash()
	_player.locked = true
	_dialogue.play([
		"……远处隐约传来粤曲哼唱。（音频占位：amb_yuequ_far）",
		"田中：（皱眉）什么声音……收音机？这个点了谁在听戏……",
		"雨幕中，一个红影在远处一闪而过。",
		"田中：（警觉）有人？……敌军？",
		"田中：（内心）如果是敌军……功劳可不能让别人抢了。",
	])
	await _dialogue.finished
	_player.locked = false
	_status.text = "目标：从左侧门离开病房（1A 出口）"


func _on_photo(_by: PlayerController) -> void:
	GameState.set_flag("1a_photo_seen", true)
	_player.locked = true
	_dialogue.play([
		"一张旧照片：妻子与女儿站在木屋前。",
		"田中：（看着照片）再忍忍……等打完仗就回家……",
	])
	await _dialogue.finished
	_player.locked = false
	if GameState.has_flag("1a_stood_up"):
		_schedule_opera_cue()


func _on_door(_by: PlayerController) -> void:
	if not GameState.has_flag("1a_stood_up"):
		_player.locked = true
		_dialogue.play(["还躺着。先起身。"])
		await _dialogue.finished
		_player.locked = false
		return

	GameState.set_flag("1a_complete", true)
	_player.locked = true
	var photo_line := "已看照片" if GameState.has_flag("1a_photo_seen") else "未看照片（可选）"
	var opera_line := "已触发粤曲/红影" if GameState.has_flag("1a_opera_heard") else "粤曲未触发"
	_dialogue.play([
		"田中拿起手枪，悄悄走出病房。",
		"【1A 完成】下一场景（1B 走廊）尚未接入。",
		"状态：%s · %s" % [photo_line, opera_line],
	])
	await _dialogue.finished
	_status.text = "1A COMPLETE — 可关闭窗口"
	_player.locked = false


func _red_flash() -> void:
	var t := create_tween()
	t.tween_method(_set_flash_alpha, 0.0, 0.45, 0.12)
	t.tween_method(_set_flash_alpha, 0.45, 0.0, 0.55)
	await t.finished


func _set_flash_alpha(a: float) -> void:
	var c := _fx_flash.color
	c.a = a
	_fx_flash.color = c


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
		Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)
	])
	return p


func _make_interactable(
	id: String, prompt: String, pos: Vector2, size: Vector2, color: Color, once: bool
) -> Interactable:
	var area := Interactable.new()
	area.name = "Interact_%s" % id
	area.interact_id = id
	area.prompt_text = prompt
	area.once = once
	area.position = pos
	area.collision_layer = 0
	area.collision_mask = 2
	area.monitoring = true
	area.monitorable = false

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = size * 0.5
	area.add_child(shape)

	var vis := Polygon2D.new()
	vis.polygon = PackedVector2Array([
		Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, size.y), Vector2(0, size.y)
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
