extends Area2D
class_name GhostShadow
## 灰盒鬼影：在碎片区间巡逻；面对且进入监管范围才抓住（躲避点内无效）

signal caught

var dir: float = 1.0
var speed: float = 70.0
var left_x: float = 420.0
var right_x: float = 1580.0
var detect_range: float = 200.0
var active: bool = true
var _player: PlayerController
var _cool: float = 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 0
	monitoring = false
	monitorable = false


func setup(from_x: float, to_x: float, spd: float, player: PlayerController, sense: float = 200.0) -> void:
	left_x = from_x
	right_x = to_x
	speed = spd
	detect_range = sense
	_player = player
	dir = 1.0
	position = Vector2(from_x, 560.0)


func _process(delta: float) -> void:
	if not active:
		return
	position.x += dir * speed * delta
	if position.x >= right_x:
		position.x = right_x
		dir = -1.0
	elif position.x <= left_x:
		position.x = left_x
		dir = 1.0

	if _cool > 0.0:
		_cool -= delta
		return
	_try_catch()


func _try_catch() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.hiding or _player.locked:
		return
	var dx := _player.global_position.x - global_position.x
	if absf(dx) > detect_range:
		return
	# 面对：朝向与玩家相对位置同号
	if signf(dx) != 0.0 and signf(dx) != signf(dir):
		return
	_cool = 0.8
	caught.emit()


func reset_patrol() -> void:
	position.x = left_x
	dir = 1.0
	_cool = 0.6
