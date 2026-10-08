extends GreyboxLevel
## S1-3 密室门：锁着 → 找钥匙 → 开门


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	GameState.puzzle_id = "key"
	setup_shell(1280.0, "S1-3 · 密室入口")
	add_prop(Vector2(980, 200), Vector2(80, 280), Color("2a221c"), "DoorVis")
	add_label_at(Vector2(980, 170), "密室门", Color("a09080"))
	add_prop(Vector2(860, 260), Vector2(36, 50), Color("8a7050"), "Hook")

	make_interactable("door", "密室门", Vector2(960, 420), Vector2(90, 140), Color("5a4030"), false).interacted.connect(_on_door)
	make_interactable("plaque", "查看·挂钩木牌", Vector2(840, 430), Vector2(70, 70), Color("8a7050"), false).interacted.connect(_on_plaque)
	make_interactable("back", "回走廊找钥匙", Vector2(40, 420), Vector2(70, 140), Color("4a4038"), false).interacted.connect(_on_back)

	spawn_player(Vector2(200, 600), false)
	if GameState.has_item("key"):
		status.text = "用钥匙开门"
		await say(["钥匙在箱里。门还锁着。"])
	else:
		status.text = "门锁着 · 查木牌，或回楼上"
		await say(["田中：锁着。钥匙呢。", "门缝下面透出一丝微光。"])


func _on_plaque(_by: PlayerController) -> void:
	GameState.add_note("备用钥匙——管理员处")
	await say(["备用钥匙 —— 管理员处", "田中：管理员……那个老头？"])


func _on_back(_by: PlayerController) -> void:
	if GameState.has_item("key"):
		await say(["钥匙已经在了。开门吧。"])
		return
	goto_scene(ScenePaths.KEY_HUNT)


func _on_door(_by: PlayerController) -> void:
	if not GameState.has_item("key"):
		await say(["锁着。得先找钥匙。"])
		return
	GameState.set_flag("1c_door_open", true)
	await say(["铜钥匙转了一下。门开了。"])
	GameState.puzzle_id = "seal"
	goto_scene(ScenePaths.SEAL_1C)
