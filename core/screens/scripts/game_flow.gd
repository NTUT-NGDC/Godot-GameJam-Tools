extends Node
## GameFlow（autoload）- 遊戲流程：贏了、輸了、暫停。
##
## 遊戲裡贏了或輸了，呼叫一行就好，會跳出勝利／失敗畫面（再玩一次、回標題）：
##   GameFlow.win()                 GameFlow.win("你逃出去了！")
##   GameFlow.lose()                GameFlow.lose("被抓到了……")
## 也可以在檢查器把 signal 連到 GameFlow 的 win／lose（例如生怪器的 reached_goal → lose）。
##
## 有好幾關的話：把關卡場景拖進 game_config.tres 的 Levels，就會有關卡選擇畫面、「下一關」，過關會自動記住。
##
## 暫停選單不用自己放：遊戲中按 Esc（或右上角的「選單」）就會打開。
## 標題畫面、Credits 這種不需要暫停的場景，把最上層節點加進 group「no_pause」就好。
##
## 暫停選單、勝敗畫面的「回標題」可以換成別的（例如編輯器裡試玩時，換成「回編輯器」）：
##   GameFlow.set_title_button("回地圖編輯器", stop_test)
##   GameFlow.reset_title_button()          ← 換回「回標題」
## 設定它的節點不見了（換場景、被刪掉）會自動換回「回標題」。
##
## 暫時不要暫停選單（例如編輯器在編輯時）：GameFlow.set_pause_enabled(false)，
## 右上角的「選單」會藏起來、Esc 也不會打開。只對現在這個場景有效，換場景就恢復。

## 贏了（勝利畫面跳出來的那一刻）
signal won(message: String)
## 輸了
signal lost(message: String)

const PAUSE_MENU_SCENE: PackedScene = preload("res://core/screens/pause_menu.tscn")
const RESULT_SCENE: PackedScene = preload("res://core/screens/result_screen.tscn")

var _pause_menu: CanvasLayer
var _result: CanvasLayer
## 「回標題」換成什麼（沒換＝空字串）
var _title_text: String = ""
var _title_action: Callable = Callable()
## 暫停選單關掉了嗎（只對 _pause_off_scene 這個場景有效）
var _pause_off: bool = false
var _pause_off_scene: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed.call_deferred()


## 贏了：暫停遊戲、顯示勝利畫面
func win(message: String = "") -> void:
	var scene: Node = get_tree().current_scene
	if scene != null and not is_finished():
		LevelProgress.mark_cleared(scene.scene_file_path)         # 在關卡清單裡的話，記住這關過了
	_show_result(true, message)
	won.emit(message)


## 輸了：暫停遊戲、顯示失敗畫面
func lose(message: String = "") -> void:
	_show_result(false, message)
	lost.emit(message)


## 現在是不是正在顯示勝敗畫面
func is_finished() -> bool:
	return _result != null and is_instance_valid(_result)


## 下一關的場景（現在不在關卡清單裡、已經是最後一關＝空字串）
func next_level() -> String:
	var scene: Node = get_tree().current_scene
	return GameConfig.current().next_level(scene.scene_file_path) if scene != null else ""


## 現在這一關可以回關卡選擇嗎（在關卡清單裡、而且有兩關以上）
func can_select_level() -> bool:
	var scene: Node = get_tree().current_scene
	var config: GameConfig = GameConfig.current()
	return scene != null and config.has_level_select() and config.level_index(scene.scene_file_path) >= 0


## 打開或關掉暫停選單（關掉：右上角的「選單」藏起來、Esc 不會打開）。只對現在這個場景有效
func set_pause_enabled(on: bool) -> void:
	_pause_off = not on
	_pause_off_scene = get_tree().current_scene
	if _pause_menu != null and is_instance_valid(_pause_menu):
		_pause_menu.call("refresh")


## 現在可以打開暫停選單嗎
func is_pause_enabled() -> bool:
	return not (_pause_off and is_instance_valid(_pause_off_scene) and _pause_off_scene == get_tree().current_scene)


## 把暫停選單、勝敗畫面的「回標題」換成別的按鈕：text＝按鈕上的字，action＝按下去要做的事
func set_title_button(text: String, action: Callable) -> void:
	_title_text = text
	_title_action = action


## 換回原本的「回標題」
func reset_title_button() -> void:
	_title_text = ""
	_title_action = Callable()


## 「回標題」現在換成什麼字（沒換＝空字串）。暫停選單、勝敗畫面打開時用
func title_button_text() -> String:
	return _title_text if _title_action.is_valid() else ""


## 按下「回標題」：有換就做換的事（關掉勝敗畫面、取消暫停），沒換就回標題
func go_title() -> void:
	if not _title_action.is_valid():
		SceneManager.change_scene(GameConfig.TITLE_SCENE)
		return
	if is_finished():
		_result.queue_free()
	_result = null
	get_tree().paused = false
	_title_action.call()


func _show_result(is_win: bool, message: String) -> void:
	if is_finished():
		return                                                    # 已經贏了或輸了，不重複跳
	_result = RESULT_SCENE.instantiate()
	add_child(_result)
	_result.call("show_result", is_win, message)
	get_tree().paused = true


## 換場景時：拿掉上一個場景的勝敗畫面，需要的話放一個新的暫停選單
func _on_scene_changed() -> void:
	get_tree().paused = false
	if is_finished():
		_result.queue_free()
	_result = null
	if _pause_menu != null and is_instance_valid(_pause_menu):
		_pause_menu.queue_free()
	_pause_menu = null
	var scene: Node = get_tree().current_scene
	if scene == null or scene.is_in_group("no_pause"):
		return
	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	add_child(_pause_menu)
