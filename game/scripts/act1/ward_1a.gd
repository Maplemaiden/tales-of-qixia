extends GreyboxLevel
## 1A 临时病房（剧情设计 v1.1：具体动机 + 回国申请表）

var _opera_triggered: bool = false
var _opera_scheduled: bool = false
var _photo: Interactable
var _papers: Interactable
var _door: Interactable


func get_room_width() -> float:
	return 1280.0


func _ready() -> void:
	setup_shell(1280.0, "1A · 临时病房")
	add_prop(Vector2(980, 120), Vector2(160, 100), Color("3d4a5c"), "Window")
	add_label_at(Vector2(1025, 155), "｜雨｜", Color("8a9bb0"))
	add_prop(Vector2(200, 520), Vector2(100, 40), Color("3a3040"), "BedNPC1")
	add_prop(Vector2(360, 520), Vector2(100, 40), Color("3a3040"), "BedNPC2")
	add_prop(Vector2(860, 520), Vector2(120, 44), Color("4a3548"), "BedTanaka")

	make_interactable("get_up", "起身", Vector2(880, 470), Vector2(100, 90), Color("6b4a5a"), true).interacted.connect(_on_get_up)
	_photo = make_interactable("photo", "调查·家人照片", Vector2(1020, 470), Vector2(40, 52), Color("c4a574"), false)
	_photo.interacted.connect(_on_photo)
	_papers = make_interactable("papers", "调查·回国申请表", Vector2(940, 500), Vector2(36, 28), Color("c8b890"), true)
	_papers.interacted.connect(_on_papers)
	_door = make_interactable("door", "离开病房", Vector2(40, 420), Vector2(56, 140), Color("5a4030"), false)
	_door.interacted.connect(_on_door)
	# 起身前只允许按 E 起身，不能走动、不能先查别的
	_photo.set_enabled(false)
	_papers.set_enabled(false)
	_door.set_enabled(false)

	spawn_player(Vector2(930, 600), true)
	await _boot()


func _boot() -> void:
	await say([
		"【第一幕 · 1A 临时病房】",
		"雨夜。上等兵田中躺在靠窗的床上，左臂缠着绷带。",
		"按 E 起身。起身后可调查床头照片与口袋里的申请表，再从左侧门离开。",
	])
	# say() 结束会解锁移动；起身前必须保持锁定
	player.locked = true
	status.text = "目标：按 E 起身（起身前方不可移动）"


func _on_get_up(_by: PlayerController) -> void:
	GameState.set_flag("1a_stood_up", true)
	await say([
		"田中：（低声）……再忍忍。再立一功就能升军曹了……升了就不用去太平洋……",
		"他撑着床沿站起身。窗外雨声不断。",
	])
	_photo.set_enabled(true)
	_papers.set_enabled(true)
	_door.set_enabled(true)
	player.locked = false
	status.text = "可调查照片 / 申请表 · 留意窗外 · 从左侧门离开"
	_schedule_opera_cue()


func _schedule_opera_cue() -> void:
	if _opera_triggered or _opera_scheduled:
		return
	_opera_scheduled = true
	await get_tree().create_timer(2.5).timeout
	if _opera_triggered or not GameState.has_flag("1a_stood_up"):
		return
	_opera_triggered = true
	GameState.set_flag("1a_opera_heard", true)
	await red_flash()
	await say([
		"……远处隐约传来粤曲哼唱。（音频占位：amb_yuequ_far）",
		"田中：（皱眉）什么声音……收音机？这个点了谁在听戏……",
		"雨幕中，一个红影在远处一闪而过。",
		"田中：（警觉）有人？……敌军？",
		"田中：（内心）如果是敌军……军曹稳了，回国分数也够了。不能让别人抢先——这是我最后的机会……",
	])
	status.text = "目标：从左侧门离开（→ 1B 走廊）"


func _on_photo(_by: PlayerController) -> void:
	GameState.set_flag("1a_photo_seen", true)
	await say([
		"一张旧照片：妻子与年幼的女儿站在木屋前。",
		"田中：（看着照片）再忍忍……攒够分数就能回家见丫头了……",
	])
	if GameState.has_flag("1a_stood_up"):
		_schedule_opera_cue()


func _on_papers(_by: PlayerController) -> void:
	GameState.set_flag("1a_papers_seen", true)
	await say([
		"皱巴巴的「回国资格申请表」。上面盖了几个章，还差最后一个「战功章」。",
		"田中：（低声）还差一个章……升军曹、盖完章，就能回家。",
	])
	if GameState.has_flag("1a_stood_up"):
		_schedule_opera_cue()


func _on_door(_by: PlayerController) -> void:
	if not GameState.has_flag("1a_stood_up"):
		await say(["还躺着。先起身。"])
		return
	GameState.set_flag("1a_complete", true)
	await say([
		"田中把申请表塞回口袋，拿起手枪，悄悄走出病房。",
		"【1A 完成】进入走廊……",
	])
	goto_scene(ScenePaths.CORRIDOR_1B)
