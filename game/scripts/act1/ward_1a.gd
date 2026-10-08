extends GreyboxLevel
## S1-1 临时病房：先动机，后红影；出门须持照片与申请表


var _photo: Interactable
var _papers: Interactable
var _window: Interactable
var _door: Interactable
var _opera_done: bool = false


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	setup_shell(1280.0, "S1-1 · 临时病房 · 夜")
	add_prop(Vector2(980, 120), Vector2(160, 100), Color("3d4a5c"), "WindowVis")
	add_label_at(Vector2(1025, 155), "｜雨｜", Color("8a9bb0"))
	add_prop(Vector2(200, 520), Vector2(100, 40), Color("3a3040"), "BedNPC1")
	add_prop(Vector2(360, 520), Vector2(100, 40), Color("3a3040"), "BedNPC2")
	add_prop(Vector2(860, 520), Vector2(120, 44), Color("4a3548"), "BedTanaka")

	make_interactable("get_up", "起身", Vector2(880, 470), Vector2(100, 90), Color("6b4a5a"), true).interacted.connect(_on_get_up)
	_photo = make_interactable("photo", "查看·家人照片", Vector2(1020, 470), Vector2(40, 52), Color("c4a574"), true)
	_photo.interacted.connect(_on_photo)
	_papers = make_interactable("papers", "查看·回国申请表", Vector2(940, 500), Vector2(36, 28), Color("c8b890"), true)
	_papers.interacted.connect(_on_papers)
	_window = make_interactable("window", "查看·窗户", Vector2(1000, 420), Vector2(90, 80), Color("4a5a70"), true)
	_window.interacted.connect(_on_window)
	make_interactable("bed", "查看·床铺", Vector2(200, 500), Vector2(80, 40), Color("4a4050"), true).interacted.connect(_on_bed)
	make_interactable("lamp", "查看·煤油灯", Vector2(700, 480), Vector2(40, 50), Color("c4a050"), true).interacted.connect(_on_lamp)
	make_interactable("sleepers", "查看·熟睡的士兵", Vector2(360, 500), Vector2(80, 40), Color("4a4050"), true).interacted.connect(_on_sleep)
	make_interactable("poster", "查看·墙上的纸", Vector2(80, 430), Vector2(50, 70), Color("6a5040"), true).interacted.connect(_on_poster)
	_door = make_interactable("door", "离开病房", Vector2(40, 420), Vector2(56, 140), Color("5a4030"), false)
	_door.interacted.connect(_on_door)

	_photo.set_enabled(false)
	_papers.set_enabled(false)
	_window.set_enabled(false)
	_door.set_enabled(false)

	spawn_player(Vector2(930, 600), true)
	await say([
		"雨夜。上等兵田中躺在靠窗的床上，左臂缠着绷带。",
		"按 E 起身。先看清他要什么，灵异才会来。",
	], true)
	status.text = "目标：起身 · 查看照片与申请表"


func _on_get_up(_by: PlayerController) -> void:
	GameState.set_flag("1a_stood_up", true)
	await say([
		"田中：（低声）再忍忍……再立一功就能升军曹了。",
		"田中：升了军曹，就不用去太平洋了。",
	])
	_photo.set_enabled(true)
	_papers.set_enabled(true)
	_door.set_enabled(true)
	player.locked = false
	status.text = "先查看照片和申请表，再看窗"


func _on_photo(_by: PlayerController) -> void:
	GameState.set_flag("1a_photo_seen", true)
	GameState.add_item("photo")
	await say([
		"一张合影。妻子抱着女儿，两个人都笑着。边角磨白了。",
		"田中：还差一个章……攒够了就能回家见丫头了。",
	])
	_try_unlock_window()


func _on_papers(_by: PlayerController) -> void:
	GameState.set_flag("1a_papers_seen", true)
	GameState.add_item("form")
	await say([
		"皱得像团纸。章盖了三个，最后一栏空着——「战功」。",
		"田中：三年了。再不立功，就要被调走了。",
	])
	_try_unlock_window()


func _try_unlock_window() -> void:
	if GameState.has_flag("1a_photo_seen") and GameState.has_flag("1a_papers_seen"):
		_window.set_enabled(true)
		status.text = "去窗边看看"


func _on_window(_by: PlayerController) -> void:
	if _opera_done:
		return
	_opera_done = true
	GameState.set_flag("1a_opera_heard", true)
	await say([
		"田中：什么声音……这个点了，谁在听戏？",
		"田中：收音机？这儿哪来的收音机。",
		"雨很大。外面黑得很匀。",
	])
	await red_flash()
	await say([
		"（什么都没有。）",
		"田中：有人？……敌军？",
		"田中：如果是敌军……军曹稳了，回国的分数也够。",
		"田中：不能让别人抢先。这是我最后的机会。",
	])
	status.text = "左侧出门（须已收起照片与申请表）"


func _on_bed(_by: PlayerController) -> void:
	await say(["硬板床。躺久了腰疼。"])


func _on_lamp(_by: PlayerController) -> void:
	await say(["油剩个底。点了也没多亮。"])


func _on_sleep(_by: PlayerController) -> void:
	await say(["睡得很沉。不知道叫什么名字。"])


func _on_poster(_by: PlayerController) -> void:
	await say(["纸潮了，字糊了一半。"])


func _on_door(_by: PlayerController) -> void:
	if not GameState.has_flag("1a_stood_up"):
		await say(["还躺着。先起身。"])
		return
	if not (GameState.has_item("photo") and GameState.has_item("form")):
		await say(["照片和申请表还没收好。"])
		return
	if not GameState.has_flag("1a_opera_heard"):
		await say(["窗外好像有什么。先去窗边看看。"])
		return
	GameState.set_flag("1a_complete", true)
	await say(["田中把手枪摸出来，悄悄出门。"])
	goto_scene(ScenePaths.CORRIDOR_1B)
