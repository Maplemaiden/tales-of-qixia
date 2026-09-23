extends GreyboxLevel
## 3E 夜间日记被污染（剧情设计 v1.1 · 第三幕结尾 / 第四幕前）

func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	setup_shell(1280.0, "3E · 办公室·夜 · 日记被污染")
	add_prop(Vector2(200, 420), Vector2(180, 90), Color("3a342c"), "DeskNight")
	add_prop(Vector2(900, 160), Vector2(140, 110), Color("2a3540"), "NightWindow")
	add_label_at(Vector2(930, 200), "雨夜", Color("6a8090"))
	add_prop(Vector2(240, 400), Vector2(50, 36), Color("c4b090"), "DiaryOpen")

	make_interactable("write_diary", "写日记 / 发现污染", Vector2(220, 460), Vector2(120, 70), Color("8a7060"), true).interacted.connect(_on_diary)
	make_interactable("to_chamber", "明日·进入密室", Vector2(1180, 420), Vector2(70, 140), Color("5a4030"), false).interacted.connect(_on_to_chamber)

	spawn_player(Vector2(180, 600), false)
	await say([
		"【第三幕结尾】山本回到办公室。夜间写日记，记录当天调查。",
		"靠近书桌按 E。",
	])
	status.text = "在书桌写日记"


func _on_diary(_by: PlayerController) -> void:
	GameState.set_flag("3e_diary_polluted", true)
	await say([
		"山本翻开日记，写到一半突然停笔——多了一段他从未写过的话。",
		"山本：（困惑）这……这是什么？我没写过这个……",
		"字迹歪斜，像左手写的，与他自己的笔迹完全不同。",
		"只有四个字：「你看见了吗？」",
	])
	await red_flash()
	await say([
		"山本：（强撑）笔迹不是我的。谁动过我的日记？……不可能，一直在抽屉里。",
		"他翻遍前后页——只有这一页多出那四个字。",
		"山本：（内心）「你看见了吗」……看见什么？田中的死状？还是地下室的棺材？",
	])
	await say([
		"窗边雨幕中，红影一闪。桌上那四个字仿佛在暗处发微光。",
		"山本：（下定决心）明天……我要去地下室。那口棺材……一定有答案。",
	])
	status.text = "目标：右侧出门 → 第四幕密室"


func _on_to_chamber(_by: PlayerController) -> void:
	if not GameState.has_flag("3e_diary_polluted"):
		await say(["先在书桌写完今天的日记。"])
		return
	GameState.set_flag("3e_complete", true)
	await say([
		"雨夜过去。山本独自走向地下室……",
		"【进入第四幕】",
	])
	goto_scene(ScenePaths.CHAMBER_4)
