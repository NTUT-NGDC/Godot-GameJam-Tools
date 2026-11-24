extends Node
## 起手包的自動測試：
## 1. 設定檔：game_config.tres 讀得到，Credits 拆行
## 2. 按鍵：每個常用動作都有設定
## 3. 畫面流程：標題（沒有暫停選單）→ 開始遊戲 → 主場景（有暫停選單）→ 暫停／繼續 → 贏 → 再玩一次 → 輸 → 回標題 → Credits
## 4. HUD：分數、計時、血條
## 5. 鏡頭：跟隨、固定、邊界；可移動縮放的鏡頭（移動、縮放、邊界）
## 6. 音量、存讀檔
##
## 在命令列執行：
##   godot --headless --path . res://core/tests/core_test.tscn

const ScriptErrors = preload("res://core/tests/scripts/script_error_counter.gd")
const EXPECTED_ACTIONS: Array[String] = [
	"move_up", "move_down", "move_left", "move_right", "run", "interact", "attack", "pause",
	"skill_1", "skill_2", "skill_3", "mouse_left", "mouse_right",
	"debug_1", "debug_2", "debug_3", "debug_4", "debug_5"]
const SCORE_SCENE: PackedScene = preload("res://core/hud/score_display.tscn")
const TIMER_SCENE: PackedScene = preload("res://core/hud/timer_display.tscn")
const HEALTH_SCENE: PackedScene = preload("res://core/hud/health_bar.tscn")
const CAMERA_SCENE: PackedScene = preload("res://core/camera/follow_camera.tscn")
const PAN_CAMERA_SCENE: PackedScene = preload("res://core/camera/pan_camera.tscn")

var _failures: int = 0
## 腳本錯誤也算失敗（會讓測試函式中斷、跑不到 _expect）
var _script_errors: ScriptErrors = ScriptErrors.new()


func _ready() -> void:
	# 測試自己不能是「目前的場景」，不然換場景時會被換掉
	get_tree().current_scene = null
	_test_config()
	_test_actions()
	await _test_hud()
	await _test_camera()
	await _test_pan_camera()
	_test_audio_and_save()
	await _test_flow()

	_failures += _script_errors.report()
	if _failures == 0:
		print("[起手包測試] 全部 PASS")
		get_tree().quit(0)
	else:
		print("[起手包測試] FAIL：%d 項失敗" % _failures)
		get_tree().quit(1)


func _test_config() -> void:
	print("--- 設定檔 ---")
	var config: GameConfig = GameConfig.current()
	_expect(config != null and config.game_name != "", "game_config.tres 讀得到（%s）" % config.game_name)
	_expect(not config.levels.is_empty() and config.level_paths().size() == config.levels.size(), "Levels 有設定、每一關都存在（%d 關）" % config.level_paths().size())
	var test: GameConfig = GameConfig.new()
	test.credits = "程式：小明\n\n美術：小華\n\n"
	_expect(test.credit_lines() == PackedStringArray(["程式：小明", "", "美術：小華"]), "Credits 一行一個，保留中間的空白行、去掉最後的空白行")


func _test_actions() -> void:
	print("--- 按鍵 ---")
	var missing: Array[String] = []
	for action: String in EXPECTED_ACTIONS:
		if not InputMap.has_action(action) or InputMap.action_get_events(action).is_empty():
			missing.append(action)
	_expect(missing.is_empty(), "常用按鍵都有設定（少了 %s）" % ", ".join(missing))
	var skill_keys: Array[int] = []
	for event: InputEvent in InputMap.action_get_events("skill_1"):
		skill_keys.append((event as InputEventKey).physical_keycode)
	_expect(skill_keys.has(KEY_1), "技能 1 是數字鍵 1")


func _test_hud() -> void:
	print("--- HUD ---")
	var score: ScoreDisplay = SCORE_SCENE.instantiate()
	add_child(score)
	score.add(10)
	score.add(5)
	_expect(score.score == 15 and score.text.ends_with("15"), "分數：加 10 再加 5 → 15（%s）" % score.text)
	_expect(get_tree().get_first_node_in_group("score") == score, "分數在 group「score」")

	var timer: TimerDisplay = TIMER_SCENE.instantiate()
	timer.mode = 1
	timer.countdown_seconds = 1.0
	var up: Array[bool] = [false]
	timer.time_up.connect(func() -> void: up[0] = true)
	add_child(timer)
	await get_tree().create_timer(1.3).timeout
	_expect(up[0] and timer.text.ends_with("0:00"), "倒數 1 秒：時間到（%s）" % timer.text)
	_expect(TimerDisplay.format(65.0) == "1:05", "秒數格式：65 秒 → 1:05")

	var bar: HealthBar = HEALTH_SCENE.instantiate()
	bar.max_health = 50.0
	add_child(bar)
	var dead: Array[int] = [0]
	bar.died.connect(func() -> void: dead[0] += 1)
	bar.damage(20)
	_expect(is_equal_approx(bar.health, 30.0) and is_equal_approx(bar.value, 30.0), "血條：50 扣 20 → 30")
	bar.heal(100)
	_expect(is_equal_approx(bar.health, 50.0), "補血不會超過上限")
	bar.damage(999)
	bar.damage(10)
	_expect(bar.is_dead() and dead[0] == 1, "扣到 0：died 只發一次")
	for node: Node in [score, timer, bar]:
		node.queue_free()


func _test_camera() -> void:
	print("--- 鏡頭 ---")
	var world: Node2D = Node2D.new()
	add_child(world)
	var target: Node2D = Node2D.new()
	world.add_child(target)
	target.add_to_group("player")
	var camera: FollowCamera = CAMERA_SCENE.instantiate()
	camera.smoothing = 0.0
	camera.use_limits = true
	camera.limit_size = Vector2(2000, 720)                        # 中心在 (0, 0)：左右各 1000
	world.add_child(camera)
	await _physics_frames(3)
	_expect(camera.target == target and camera.is_current(), "跟隨對象空著：自動找 player 群組")
	target.global_position = Vector2(200, 0)
	await _physics_frames(3)
	_expect(camera.get_screen_center_position().is_equal_approx(Vector2(200, 0)), "跟隨：鏡頭跟著玩家（%s）" % camera.get_screen_center_position())
	target.global_position = Vector2(5000, 3000)
	await _physics_frames(3)
	_expect(camera.get_screen_center_position().is_equal_approx(Vector2(360, 0)), "邊界：玩家跑出去，鏡頭停在框的邊上（%s）" % camera.get_screen_center_position())
	camera.follow = false
	camera.global_position = Vector2(-100, 0)
	target.global_position = Vector2(900, 0)
	await _physics_frames(3)
	_expect(camera.get_screen_center_position().is_equal_approx(Vector2(-100, 0)), "不跟隨：鏡頭固定不動（%s）" % camera.get_screen_center_position())
	world.queue_free()
	await _physics_frames(1)


func _test_pan_camera() -> void:
	print("--- 可移動縮放的鏡頭 ---")
	var world: Node2D = Node2D.new()
	add_child(world)
	var camera: PanCamera = PAN_CAMERA_SCENE.instantiate()
	camera.edge_scroll = false                                    # 測試時滑鼠位置不固定
	camera.keyboard_pan = false
	world.add_child(camera)
	await _physics_frames(2)
	_expect(camera.is_current(), "放進關卡：變成目前的鏡頭")
	camera.move_by(Vector2(300, 0))
	await _physics_frames(1)
	_expect(camera.get_screen_center_position().is_equal_approx(Vector2(300, 0)), "移動：沒有邊界時自由移動（%s）" % camera.get_screen_center_position())
	var center: Vector2 = camera.get_viewport_rect().size / 2.0
	camera.zoom_by(2.0, center)
	_expect(is_equal_approx(camera.zoom.x, 2.0), "縮放：放大兩倍")
	camera.zoom_by(100.0, center)
	_expect(is_equal_approx(camera.zoom.x, camera.max_zoom), "縮放：最多放大到 max_zoom")
	camera.zoom = Vector2.ONE
	camera.global_position = Vector2.ZERO
	var before: Vector2 = camera.screen_to_world(Vector2(100, 100))
	camera.zoom_by(2.0, Vector2(100, 100))
	_expect(camera.screen_to_world(Vector2(100, 100)).distance_to(before) < 0.5, "縮放：滑鼠指的地方留在原位")

	camera.zoom = Vector2.ONE
	camera.set_limit_rect(Rect2(0, 0, 2560, 720))                 # 比畫面寬一倍、跟畫面一樣高
	camera.global_position = Vector2(-5000, 999)
	camera.clamp_to_limits()
	_expect(camera.global_position.is_equal_approx(Vector2(640, 360)), "邊界：拉回框裡（%s）" % camera.global_position)
	camera.move_by(Vector2(99999, 0))
	_expect(camera.global_position.is_equal_approx(Vector2(1920, 360)), "邊界：最多移到右邊（%s）" % camera.global_position)
	camera.zoom_by(0.01, center)
	_expect(is_equal_approx(camera.zoom.x, 0.5) and camera.global_position.is_equal_approx(Vector2(1280, 360)), "邊界：最多縮小到整個框都放得進畫面、置中（%.2f）" % camera.zoom.x)
	world.queue_free()
	await _physics_frames(1)


func _physics_frames(count: int) -> void:
	for i: int in count:
		await get_tree().physics_frame


func _test_audio_and_save() -> void:
	print("--- 音量、存檔 ---")
	var before: float = AudioManager.bgm_volume
	AudioManager.set_bgm_volume(0.3)
	_expect(is_equal_approx(AudioManager.bgm_volume, 0.3), "音樂音量設成 0.3")
	AudioManager.set_bgm_volume(before)
	_expect(AudioServer.get_bus_index("BGM") >= 0 and AudioServer.get_bus_index("SFX") >= 0, "有 BGM、SFX 兩條匯流排")
	var slot: int = 9
	_expect(SaveManager.save({"score": 42}, slot), "存檔成功")
	var data: Dictionary = SaveManager.load_data(slot)
	_expect(int(data.get("score", 0)) == 42, "讀檔讀回 42")
	SaveManager.delete_save(slot)
	_expect(not SaveManager.has_save(slot), "刪掉存檔")


func _test_flow() -> void:
	print("--- 畫面流程 ---")
	SceneManager.default_fade_time = 0.05
	SceneManager.change_scene(GameConfig.TITLE_SCENE, 0.0)
	await _wait_scene("TitleScreen")
	var title: Node = get_tree().current_scene
	_expect(title.name == "TitleScreen", "到標題畫面")
	_expect(_pause_menu() == null, "標題畫面沒有暫停選單")
	_expect((title.get_node("%GameName") as Label).text == GameConfig.current().game_name, "標題顯示 game_config 的遊戲名稱")

	# 只留第一關（專案自己有幾關都可以測），進度存到測試用的檔案，測完還原
	var config: GameConfig = GameConfig.current()
	var own_levels: Array[String] = config.levels
	var own_path: String = LevelProgress.save_path
	LevelProgress.save_path = "user://_test_flow_progress.json"
	var start: String = config.level_paths()[0]
	config.levels = []
	(title.get_node("%StartButton") as Button).pressed.emit()
	_expect((title.get_node("%MessageLabel") as Label).visible and not SceneManager.is_transitioning(), "Levels 空著：提示去設定，不會換場景")
	config.levels = [start]
	var start_name: String = (load(start) as PackedScene).get_state().get_node_name(0)
	(title.get_node("%StartButton") as Button).pressed.emit()
	await _wait_scene(start_name)
	_expect(get_tree().current_scene.scene_file_path == start, "只有一關：按開始遊戲直接進去（%s）" % start)
	var menu: CanvasLayer = _pause_menu()
	_expect(menu != null, "遊戲場景自動有暫停選單")
	if menu != null:
		menu.call("open_menu")
		_expect(get_tree().paused, "打開選單：暫停")
		menu.call("close_menu")
		_expect(not get_tree().paused, "關掉選單：繼續")

	GameFlow.win("測試勝利")
	await get_tree().process_frame
	_expect(GameFlow.is_finished() and get_tree().paused, "GameFlow.win()：顯示勝利畫面、暫停")
	GameFlow.lose("不該出現")
	_expect(_count_results() == 1, "已經贏了：再呼叫 lose 不會重複跳")
	var result: Node = _result()
	(result.get_node("%RetryButton") as Button).pressed.emit()
	await _wait_scene(start_name, true)
	await get_tree().process_frame
	_expect(not GameFlow.is_finished() and not get_tree().paused, "再玩一次：重新載入、取消暫停、勝利畫面不見")

	# 「回標題」換成別的（例如編輯器裡試玩時「回編輯器」）
	var owner_node: Node = Node.new()
	add_child(owner_node)
	var pressed: Array[int] = [0]
	GameFlow.set_title_button("回編輯器", func() -> void: pressed[0] += 1)
	menu = _pause_menu()
	menu.call("open_menu")
	var title_button: Button = menu.get_node("%TitleButton")
	_expect(title_button.text == "回編輯器", "換掉回標題：暫停選單的按鈕寫「回編輯器」")
	title_button.pressed.emit()
	await get_tree().process_frame
	_expect(pressed[0] == 1 and get_tree().current_scene.scene_file_path == start and not get_tree().paused, "按下去：做換的事、不換場景、取消暫停")
	GameFlow.win("換掉回標題")
	await get_tree().process_frame
	title_button = _result().get_node("%TitleButton")
	_expect(title_button.text == "回編輯器", "勝敗畫面的按鈕也換掉")
	title_button.pressed.emit()
	await get_tree().process_frame
	_expect(pressed[0] == 2 and not GameFlow.is_finished() and not get_tree().paused, "勝敗畫面按下去：做換的事、勝敗畫面關掉、取消暫停")
	GameFlow.set_title_button("回編輯器", owner_node.queue_free)
	owner_node.free()
	_expect(GameFlow.title_button_text().is_empty(), "設定它的節點不見了：自動換回回標題")
	GameFlow.set_title_button("回編輯器", func() -> void: pass)
	GameFlow.reset_title_button()
	menu.call("open_menu")
	_expect((menu.get_node("%TitleButton") as Button).text == "回到標題", "reset_title_button()：換回原本的字（%s）" % (menu.get_node("%TitleButton") as Button).text)
	menu.call("close_menu")

	# 暫時關掉暫停選單（例如編輯器在編輯時）
	var menu_button: Button = menu.get_node("%MenuButton")
	var esc: InputEventAction = InputEventAction.new()
	esc.action = "pause"
	esc.pressed = true
	menu.call("open_menu")
	GameFlow.set_pause_enabled(false)
	_expect(not menu_button.visible and not (menu.get_node("%MenuPanel") as Control).visible and not get_tree().paused, "set_pause_enabled(false)：選單按鈕藏起來，打開著的選單關掉")
	menu.call("_unhandled_input", esc)
	_expect(not get_tree().paused and not (menu.get_node("%MenuPanel") as Control).visible, "關掉時：按 Esc 不會打開")
	GameFlow.set_pause_enabled(true)
	_expect(menu_button.visible, "set_pause_enabled(true)：選單按鈕回來")
	menu.call("_unhandled_input", esc)
	_expect(get_tree().paused, "打開後：按 Esc 會打開")
	menu.call("close_menu")
	GameFlow.set_pause_enabled(false)

	GameFlow.lose("測試失敗")
	await get_tree().process_frame
	_expect((_result().get_node("%ResultTitle") as Label).text.contains("失敗"), "GameFlow.lose()：顯示失敗畫面")
	(_result().get_node("%TitleButton") as Button).pressed.emit()
	await _wait_scene("TitleScreen")
	_expect(get_tree().current_scene.name == "TitleScreen" and not get_tree().paused, "回到標題")
	_expect(GameFlow.is_pause_enabled(), "換場景：關掉的暫停選單自動恢復")

	await _test_levels()
	config.levels = own_levels
	LevelProgress.clear()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(LevelProgress.save_path))
	LevelProgress.save_path = own_path

	(get_tree().current_scene.get_node("%CreditsButton") as Button).pressed.emit()
	await _wait_scene("CreditsScreen")
	var list: Node = get_tree().current_scene.get_node("%CreditsList")
	_expect(list.get_child_count() == GameConfig.current().credit_lines().size(), "Credits 照設定檔產生 %d 行" % list.get_child_count())


## 關卡清單、關卡選擇、下一關、過關進度。用測試自己的場景和進度檔，測完還原（從標題畫面開始、回到標題畫面）
func _test_levels() -> void:
	print("--- 關卡 ---")
	var config: GameConfig = GameConfig.current()
	var old_levels: Array[String] = config.levels
	var old_names: String = config.level_names
	var old_order: bool = config.unlock_in_order
	var old_path: String = LevelProgress.save_path
	LevelProgress.save_path = "user://_test_level_progress.json"
	LevelProgress.clear()
	config.levels = []
	_expect(not config.has_level_select() and config.next_level(GameConfig.TITLE_SCENE) == "", "清單空著：沒有關卡選擇、沒有下一關")

	# 做三個只有一個節點的關卡
	var paths: Array[String] = []
	for i: int in 3:
		var node: Node2D = Node2D.new()
		node.name = "TestLevel%d" % (i + 1)
		var packed: PackedScene = PackedScene.new()
		packed.pack(node)
		node.free()
		paths.append("user://_test_level_%d.tscn" % (i + 1))
		ResourceSaver.save(packed, paths[i])
	config.levels = [paths[0], "", paths[1], "res://沒有這個檔案.tscn", paths[2]]
	config.level_names = "開頭\n（空的）\n\n（不見的）\n最後"
	config.unlock_in_order = true
	_expect(Array(config.level_paths()) == paths and config.has_level_select(), "空的、找不到的關卡跳過")
	_expect([config.level_name(0), config.level_name(1), config.level_name(2)] == ["開頭", "第 2 關", "最後"], "關卡名字：照格子對，沒寫的叫第幾關（%s）" % [[config.level_name(0), config.level_name(1), config.level_name(2)]])
	_expect(config.next_level(paths[0]) == paths[1] and config.next_level(paths[2]) == "", "下一關；最後一關沒有下一關")
	_expect(LevelProgress.is_unlocked(0) and not LevelProgress.is_unlocked(1) and not LevelProgress.is_unlocked(9), "照順序解鎖：一開始只有第 1 關")

	var uid: int = ResourceUID.create_id()
	ResourceUID.add_id(uid, paths[1])
	config.levels = [paths[0], ResourceUID.id_to_text(uid), paths[2]]
	_expect(Array(config.level_paths()) == paths and config.next_level(paths[0]) == paths[1], "檢查器存成 uid:// 也一樣")
	config.level_names = "開頭\n\n最後"
	(get_tree().current_scene.get_node("%StartButton") as Button).pressed.emit()
	await _wait_scene("LevelSelectScreen")
	var grid: GridContainer = get_tree().current_scene.get_node("%LevelGrid")
	_expect(grid.get_child_count() == 3 and not (grid.get_child(0) as Button).disabled and (grid.get_child(1) as Button).disabled, "開始遊戲 → 關卡選擇：3 顆按鈕，第 2 關還沒解鎖")
	_expect(_pause_menu() == null, "關卡選擇沒有暫停選單")
	(grid.get_child(0) as Button).pressed.emit()
	await _wait_scene("TestLevel1")
	_expect(get_tree().current_scene.name == "TestLevel1", "按第 1 關：進去")
	_pause_menu().call("open_menu")
	_expect((_pause_menu().get_node("%LevelsButton") as Button).visible, "暫停選單：有「關卡選擇」")
	_pause_menu().call("close_menu")
	GameFlow.lose("測試")
	await get_tree().process_frame
	_expect(not (_result().get_node("%NextButton") as Button).visible and (_result().get_node("%LevelsButton") as Button).visible and not LevelProgress.is_cleared(paths[0]), "輸了：沒有下一關、有關卡選擇、不算過關")
	(_result().get_node("%RetryButton") as Button).pressed.emit()
	await _wait_scene("TestLevel1", true)
	await get_tree().process_frame
	GameFlow.win("測試")
	await get_tree().process_frame
	_expect((_result().get_node("%NextButton") as Button).visible and LevelProgress.is_cleared(paths[0]) and LevelProgress.is_unlocked(1) and not LevelProgress.is_unlocked(2), "贏了：有下一關、記住過關、第 2 關解鎖")
	(_result().get_node("%NextButton") as Button).pressed.emit()
	await _wait_scene("TestLevel2")
	_expect(get_tree().current_scene.name == "TestLevel2" and not get_tree().paused and not GameFlow.is_finished(), "下一關：換到第 2 關")

	# 進度有存檔
	LevelProgress.save_path = "user://_test_level_other.json"
	_expect(not LevelProgress.is_cleared(paths[0]), "換一個進度檔：沒有過關")
	LevelProgress.save_path = "user://_test_level_progress.json"
	_expect(LevelProgress.is_cleared(paths[0]), "重新讀進度檔：過關還在")
	LevelProgress.mark_cleared(GameConfig.TITLE_SCENE)
	_expect(not LevelProgress.is_cleared(GameConfig.TITLE_SCENE), "不在清單裡的場景不記")

	SceneManager.change_scene(paths[2], 0.0)
	await _wait_scene("TestLevel3")
	GameFlow.win("最後一關")
	await get_tree().process_frame
	_expect(not (_result().get_node("%NextButton") as Button).visible and (_result().get_node("%RetryButton") as Button).visible, "最後一關：沒有下一關")
	(_result().get_node("%LevelsButton") as Button).pressed.emit()
	await _wait_scene("LevelSelectScreen")
	grid = get_tree().current_scene.get_node("%LevelGrid")
	_expect((grid.get_child(0) as Button).text.contains("過關") and not (grid.get_child(1) as Button).disabled, "回關卡選擇：過了的打勾、第 2 關可以玩")
	config.unlock_in_order = false
	LevelProgress.clear()
	_expect(LevelProgress.is_unlocked(2), "取消照順序解鎖：全部可以玩")
	config.unlock_in_order = true
	LevelProgress.mark_cleared(paths[0])
	var clear_button: Button = get_tree().current_scene.get_node("%ClearButton")
	clear_button.pressed.emit()
	_expect(LevelProgress.is_cleared(paths[0]), "清除進度：按一次只是確認")
	clear_button.pressed.emit()
	_expect(not LevelProgress.is_cleared(paths[0]) and (grid.get_child(1) as Button).disabled, "再按一次：進度清掉")
	(get_tree().current_scene.get_node("%BackButton") as Button).pressed.emit()
	await _wait_scene("TitleScreen")
	_expect(get_tree().current_scene.name == "TitleScreen", "返回：回標題")

	for path: String in paths + ["user://_test_level_progress.json", "user://_test_level_other.json"]:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	config.levels = old_levels
	config.level_names = old_names
	config.unlock_in_order = old_order
	LevelProgress.save_path = old_path


## 等到目前的場景換成 scene_name（reload 時名字一樣，用 changed 判斷有沒有真的換過）
func _wait_scene(scene_name: String, reloaded: bool = false) -> void:
	var start: Node = get_tree().current_scene
	for i: int in 300:
		await get_tree().process_frame
		var current: Node = get_tree().current_scene
		if current != null and current.name == scene_name and (not reloaded or current != start) and not SceneManager.is_transitioning():
			return


func _pause_menu() -> CanvasLayer:
	for child: Node in GameFlow.get_children():
		if child.scene_file_path.ends_with("pause_menu.tscn") and not child.is_queued_for_deletion():
			return child
	return null


func _result() -> Node:
	for child: Node in GameFlow.get_children():
		if child.scene_file_path.ends_with("result_screen.tscn") and not child.is_queued_for_deletion():
			return child
	return null


func _count_results() -> int:
	return GameFlow.get_children().filter(func(n: Node) -> bool: return n.name.begins_with("ResultScreen") and not n.is_queued_for_deletion()).size()


func _expect(ok: bool, description: String) -> void:
	print("  %s %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_failures += 1
