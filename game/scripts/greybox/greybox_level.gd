extends Node2D
class_name GreyboxLevel
## 几何占位关卡基类：房间壳、玩家、对白、HUD、跳转

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const DIALOGUE_SCENE := preload("res://scenes/ui/dialogue_box.tscn")

var player: PlayerController
var dialogue: DialogueBox
var status: Label
var fx_flash: Polygon2D


func setup_shell(room_w: float = 1280.0, title: String = "") -> void:
	add_child(_rect_poly(Vector2(-80, 0), Vector2(room_w + 160, 720), Color("1a1520"), -10, "BG"))
	add_child(_rect_poly(Vector2(-80, 600), Vector2(room_w + 160, 120), Color("2c2433"), -5, "FloorVis"))
	_add_static_box(Vector2(room_w * 0.5, 660), Vector2(room_w + 160, 80), "Floor")
	_add_static_box(Vector2(-40, 360), Vector2(80, 720), "WallL")
	_add_static_box(Vector2(room_w + 40, 360), Vector2(80, 720), "WallR")

	fx_flash = _rect_poly(Vector2(-100, 0), Vector2(room_w + 200, 720), Color(0.7, 0.05, 0.08, 0.0), 40, "RedFlash")
	add_child(fx_flash)

	_build_ui(title)


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

	var help := Label.new()
	help.text = "A/D 移动 · E 调查 · Space 继续"
	help.position = Vector2(24, 680)
	help.add_theme_color_override("font_color", Color("8a8078"))
	help.add_theme_font_size_override("font_size", 14)
	hud.add_child(help)


func say(lines: Array) -> void:
	player.locked = true
	var typed: Array[String] = []
	for line in lines:
		typed.append(str(line))
	dialogue.play(typed)
	await dialogue.finished
	player.locked = false


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
