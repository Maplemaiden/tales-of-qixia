extends CanvasLayer
class_name DialogueBox
## 简单对白 / 旁白。Space 推进。

signal finished

@onready var _panel: PanelContainer = $Root/Panel
@onready var _label: RichTextLabel = $Root/Panel/Margin/VBox/Text
@onready var _hint: Label = $Root/Panel/Margin/VBox/Hint

var _lines: Array[String] = []
var _index: int = 0
var _busy: bool = false


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("dialogue_box")


func is_open() -> bool:
	return _busy


func play(lines: Array[String]) -> void:
	if lines.is_empty():
		finished.emit()
		return
	_lines = lines.duplicate()
	_index = 0
	_busy = true
	visible = true
	_show_current()


func _unhandled_input(event: InputEvent) -> void:
	if not _busy:
		return
	if event.is_action_pressed("ui_advance") or event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		_advance()


func _show_current() -> void:
	_label.text = _lines[_index]
	_hint.text = "Space / E · 继续"


func _advance() -> void:
	_index += 1
	if _index >= _lines.size():
		_close()
	else:
		_show_current()


func _close() -> void:
	_busy = false
	visible = false
	finished.emit()
