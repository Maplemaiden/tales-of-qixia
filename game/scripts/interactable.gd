extends Area2D
class_name Interactable
## 可调查物。以距离判定为主，Area2D 为辅。

signal interacted(by: PlayerController)

@export var interact_id: String = ""
@export var prompt_text: String = "调查"
@export var once: bool = false
## 交互判定半径（相对脚底/中心）
@export var interact_radius: float = 90.0
## 高处物件：判定点落到站立高度，色块位置不变
@export var ground_focus: bool = false

var _used: bool = false
var _enabled: bool = true


func _ready() -> void:
	add_to_group("interactable")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = true
	# 若生成时已与玩家重叠，补一次登记
	call_deferred("_sync_overlaps")


func is_used() -> bool:
	return _used


func reset_use() -> void:
	_used = false


func is_active() -> bool:
	return _enabled and not (once and _used)


func set_enabled(v: bool) -> void:
	_enabled = v


func focus_point() -> Vector2:
	var shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	var x := global_position.x
	if shape:
		x += shape.position.x
	if ground_focus:
		return Vector2(x, 572.0)
	if shape:
		return global_position + shape.position
	return global_position + Vector2(0, 40)


func interact(by: PlayerController) -> void:
	if not is_active():
		return
	_used = true
	interacted.emit(by)


func _sync_overlaps() -> void:
	for body in get_overlapping_bodies():
		_on_body_entered(body)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		(body as PlayerController).add_nearby(self)


func _on_body_exited(body: Node2D) -> void:
	if body is PlayerController:
		(body as PlayerController).remove_nearby(self)
