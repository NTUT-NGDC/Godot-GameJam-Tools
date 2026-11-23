extends Node
## 起手包的自動測試：
## 1. 設定檔：game_config.tres 讀得到，Credits 拆行
## 2. 按鍵：每個常用動作都有設定
## 3. 畫面流程：標題（沒有暫停選單）→ 開始遊戲 → 主場景（有暫停選單）→ 暫停／繼續 → 贏 → 再玩一次 → 輸 → 回標題 → Credits
## 4. HUD：分數、計時、血條
## 5. 音量、存讀檔
##
## 在命令列執行：
##   godot --headless --path . res://core/tests/core_test.tscn

const EXPECTED_ACTIONS: Array[String] = [
	"move_up", "move_down", "move_left", "move_right", "run", "interact", "attack", "pause",
	"skill_1", "skill_2", "skill_3", "mouse_left", "mouse_right",
	"debug_1", "debug_2", "debug_3", "debug_4", "debug_5"]
const SCORE_SCENE: PackedScene = preload("res://core/hud/score_display.tscn")
const TIMER_SCENE: PackedScene = preload("res://core/hud/timer_display.tscn")
const HEALTH_SCENE: PackedScene = preload("res://core/hud/health_bar.tscn")

var _failures: int = 0


func _ready() -> void:
	# 測試自己不能是「目前的場景」，不然換場景時會被換掉
	get_tree().current_scene = null
	_test_config()
	_test_actions()
	await _test_hud()
	_test_audio_and_save()
	await _test_flow()

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
	_expect(ResourceLoader.exists(config.start_scene), "開始場景存在（%s）" % config.start_scene)
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

	var start: String = GameConfig.current().start_scene
	var start_name: String = (load(start) as PackedScene).get_state().get_node_name(0)
	(title.get_node("%StartButton") as Button).pressed.emit()
	await _wait_scene(start_name)
	_expect(get_tree().current_scene.scene_file_path == start, "按開始遊戲 → 開始場景（%s）" % start)
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

	GameFlow.lose("測試失敗")
	await get_tree().process_frame
	_expect((_result().get_node("%ResultTitle") as Label).text.contains("失敗"), "GameFlow.lose()：顯示失敗畫面")
	(_result().get_node("%TitleButton") as Button).pressed.emit()
	await _wait_scene("TitleScreen")
	_expect(get_tree().current_scene.name == "TitleScreen" and not get_tree().paused, "回到標題")

	(get_tree().current_scene.get_node("%CreditsButton") as Button).pressed.emit()
	await _wait_scene("CreditsScreen")
	var list: Node = get_tree().current_scene.get_node("%CreditsList")
	_expect(list.get_child_count() == GameConfig.current().credit_lines().size(), "Credits 照設定檔產生 %d 行" % list.get_child_count())


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
		if child.name == "PauseMenu" and not child.is_queued_for_deletion():
			return child
	return null


func _result() -> Node:
	for child: Node in GameFlow.get_children():
		if child.name == "ResultScreen" and not child.is_queued_for_deletion():
			return child
	return null


func _count_results() -> int:
	return GameFlow.get_children().filter(func(n: Node) -> bool: return n.name.begins_with("ResultScreen") and not n.is_queued_for_deletion()).size()


func _expect(ok: bool, description: String) -> void:
	print("  %s %s" % ["PASS" if ok else "FAIL", description])
	if not ok:
		_failures += 1
