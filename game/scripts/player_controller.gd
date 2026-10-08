extends CharacterBody2D
class_name PlayerController
## 横版移动 + E 调查（距离判定，不依赖必须走进 Area）

@export var move_speed: float = 180.0
@export var interact_range: float = 100.0

var locked: bool = false
## 鬼影段：站在躲避点内时不被监管抓取
var hiding: bool = false
var _nearby: Array[Interactable] = []
var _facing: float = 1.0

@onready var _body_visual: Polygon2D = $BodyVisual
@onready var _prompt: Label = $Prompt


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	motion_mode = MOTION_MODE_FLOATING


func _physics_process(_delta: float) -> void:
	if locked:
		velocity = Vector2.ZERO
		move_and_slide()
	else:
		var dir := 0.0
		if Input.is_action_pressed("move_left"):
			dir -= 1.0
		if Input.is_action_pressed("move_right"):
			dir += 1.0

		velocity.x = dir * move_speed
		velocity.y = 0.0
		move_and_slide()

		if dir != 0.0:
			_facing = dir
			_body_visual.scale.x = absf(_body_visual.scale.x) * signf(_facing)

	_update_prompt()

	if Input.is_action_just_pressed("interact"):
		_try_interact()


func add_nearby(item: Interactable) -> void:
	if item not in _nearby:
		_nearby.append(item)


func remove_nearby(item: Interactable) -> void:
	_nearby.erase(item)


func _update_prompt() -> void:
	var target := _get_focus()
	# 锁移动时也显示提示（起身等）
	if target:
		_prompt.visible = true
		_prompt.text = "E · %s" % target.prompt_text
	else:
		_prompt.visible = false


func _get_focus() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	var origin := global_position + Vector2(0, -28)

	# 1) 组内距离（主路径）
	for node in get_tree().get_nodes_in_group("interactable"):
		var item := node as Interactable
		if item == null or not item.is_active():
			continue
		var d := origin.distance_to(item.focus_point())
		var range_ok := minf(interact_range, item.interact_radius)
		if d <= range_ok and d < best_d:
			best_d = d
			best = item

	# 2) Area 登记的兜底
	if best == null:
		for item in _nearby:
			if not is_instance_valid(item) or not item.is_active():
				continue
			var d2 := origin.distance_to(item.focus_point())
			if d2 < best_d:
				best_d = d2
				best = item

	return best


func _try_interact() -> void:
	if dialogue_blocking():
		return
	var target := _get_focus()
	if target:
		target.interact(self)


func dialogue_blocking() -> bool:
	# 对白打开时由 DialogueBox 吃输入
	for node in get_tree().get_nodes_in_group("dialogue_box"):
		if node.has_method("is_open") and node.is_open():
			return true
	return false
