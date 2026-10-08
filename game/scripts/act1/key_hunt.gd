extends GreyboxLevel
## S1-3 回程：已归还 → 半开门 → 管理员桌上的钥匙


func get_room_width() -> float:
	return 1400.0


func _ready() -> void:
	GameState.puzzle_id = "key"
	setup_shell(1400.0, "S1-3 · 找钥匙")
	add_prop(Vector2(280, 240), Vector2(40, 200), Color("4a4038"), "Hooks")
	add_label_at(Vector2(250, 520), "已归还", Color("7a7068"))
	add_prop(Vector2(820, 200), Vector2(70, 180), Color("3a3028"), "HalfDoor")
	add_prop(Vector2(980, 430), Vector2(140, 70), Color("4a4035"), "Desk")

	make_interactable("returned", "查看·已归还", Vector2(250, 500), Vector2(90, 50), Color("6a6058"), true).interacted.connect(_on_returned)
	make_interactable("room", "进入·半开的门", Vector2(820, 420), Vector2(70, 140), Color("5a4030"), false).interacted.connect(_on_room)
	make_interactable("key", "拾取·密室钥匙", Vector2(1000, 460), Vector2(80, 50), Color("c4a050"), true).interacted.connect(_on_key)
	make_interactable("back", "回密室门", Vector2(40, 420), Vector2(70, 140), Color("4a4038"), false).interacted.connect(_on_back)

	get_node("Interact_key").set_enabled(false)
	get_node("Interact_key").visible = false

	spawn_player(Vector2(140, 600), false)
	status.text = "找备用钥匙"
	await say(["一排挂钩。其中一个底下写着字。"])


func _on_returned(_by: PlayerController) -> void:
	GameState.set_flag("1s3_returned", true)
	await say([
		"一排挂钩。这一个底下写着「已归还」。",
		"田中：借出去没还。……没还，就是还在谁手上。",
	])


func _on_room(_by: PlayerController) -> void:
	GameState.set_flag("1s3_room", true)
	await say(["门虚掩着。里面是张桌子。"])
	var k := get_node_or_null("Interact_key") as Interactable
	if k and not GameState.has_item("key"):
		k.set_enabled(true)
		k.visible = true
	status.text = "桌上有钥匙"


func _on_key(_by: PlayerController) -> void:
	GameState.add_item("key")
	await say(["田中：找到了……就是这个。", "钥匙已收进箱内。"])
	status.text = "回密室门"


func _on_back(_by: PlayerController) -> void:
	goto_scene(ScenePaths.BASEMENT_DOOR)
