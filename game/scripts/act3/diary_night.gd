extends GreyboxLevel
## S3-6 夜间日记被污染（日记在他手里）


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	setup_shell(1280.0, "S3-6 · 办公室·夜")
	add_prop(Vector2(200, 420), Vector2(180, 90), Color("3a342c"), "DeskNight")
	add_prop(Vector2(900, 160), Vector2(140, 110), Color("2a3540"), "NightWindow")
	add_label_at(Vector2(930, 200), "雨夜", Color("6a8090"))

	make_interactable("write_diary", "写下今天", Vector2(220, 460), Vector2(120, 70), Color("8a7060"), true).interacted.connect(_on_diary)
	make_interactable("to_chamber", "又一夜 · 下密室", Vector2(1180, 420), Vector2(70, 140), Color("5a4030"), false).interacted.connect(_on_to_chamber)

	spawn_player(Vector2(180, 600), false)
	await say(["手记一直在他身上。他坐下来写。"])
	status.text = "在书桌写"


func _on_diary(_by: PlayerController) -> void:
	GameState.set_flag("3e_diary_polluted", true)
	GameState.add_note("手记被写下四个字：你看见了吗？")
	await say([
		"山本：这……这是什么。我没写过这个。",
		"你看见了吗？",
		"山本：笔迹不是我的。谁动过我的日记。",
		"山本：不可能。它一直在我身上。",
		"山本：「你看见了吗」……看见什么。",
		"山本：明天……我去地下室。那口棺材……一定有答案。",
	])
	status.text = "右侧出门"


func _on_to_chamber(_by: PlayerController) -> void:
	if not GameState.has_flag("3e_diary_polluted"):
		await say(["先把今天写下。"])
		return
	GameState.set_flag("3e_complete", true)
	goto_scene(ScenePaths.CHAMBER_4)
