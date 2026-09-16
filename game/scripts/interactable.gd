extends Area2D
class_name Interactable
## 可调查物：靠近显示提示，E 触发。

signal interacted(by: PlayerController)

@export var interact_id: String = ""
@export var prompt_text: String = "调查"
@export var once: bool = false

var _used: bool = false
var _enabled: bool = true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	collision_layer = 0
	collision_mask = 2  # player layer


func is_active() -> bool:
	return _enabled and not (once and _used)


func set_enabled(v: bool) -> void:
	_enabled = v


func interact(by: PlayerController) -> void:
	if not is_active():
		return
	_used = true
	interacted.emit(by)


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerController:
		(body as PlayerController).add_nearby(self)


func _on_body_exited(body: Node2D) -> void:
	if body is PlayerController:
		(body as PlayerController).remove_nearby(self)
