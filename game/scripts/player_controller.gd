extends CharacterBody2D
class_name PlayerController
## 横版移动 + E 调查。演出锁时不可移动。

@export var move_speed: float = 180.0

var locked: bool = false
var _nearby: Array[Interactable] = []
var _facing: float = 1.0

@onready var _body_visual: Polygon2D = $BodyVisual
@onready var _prompt: Label = $Prompt


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1


func _physics_process(_delta: float) -> void:
	if locked:
		velocity.x = 0.0
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

	# 锁移动时仍可 E（如床上起身）
	if Input.is_action_just_pressed("interact"):
		_try_interact()


func add_nearby(item: Interactable) -> void:
	if item not in _nearby:
		_nearby.append(item)


func remove_nearby(item: Interactable) -> void:
	_nearby.erase(item)


func _update_prompt() -> void:
	var target := _get_focus()
	if target and not locked:
		_prompt.visible = true
		_prompt.text = "E · %s" % target.prompt_text
	else:
		_prompt.visible = false


func _get_focus() -> Interactable:
	var best: Interactable = null
	var best_d := INF
	for item in _nearby:
		if not is_instance_valid(item) or not item.is_active():
			continue
		var d := global_position.distance_squared_to(item.global_position)
		if d < best_d:
			best_d = d
			best = item
	return best


func _try_interact() -> void:
	var target := _get_focus()
	if target:
		target.interact(self)
