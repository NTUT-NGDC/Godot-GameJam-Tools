extends Node
## GameFlow（autoload）- 遊戲流程：贏了、輸了、暫停。
##
## 遊戲裡贏了或輸了，呼叫一行就好，會跳出勝利／失敗畫面（再玩一次、回標題）：
##   GameFlow.win()                 GameFlow.win("你逃出去了！")
##   GameFlow.lose()                GameFlow.lose("被抓到了……")
## 也可以在檢查器把 signal 連到 GameFlow 的 win／lose（例如生怪器的 reached_goal → lose）。
##
## 暫停選單不用自己放：遊戲中按 Esc（或右上角的「選單」）就會打開。
## 標題畫面、Credits 這種不需要暫停的場景，把最上層節點加進 group「no_pause」就好。

## 贏了（勝利畫面跳出來的那一刻）
signal won(message: String)
## 輸了
signal lost(message: String)

const PAUSE_MENU_SCENE: PackedScene = preload("res://core/screens/pause_menu.tscn")
const RESULT_SCENE: PackedScene = preload("res://core/screens/result_screen.tscn")

var _pause_menu: CanvasLayer
var _result: CanvasLayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().scene_changed.connect(_on_scene_changed)
	_on_scene_changed.call_deferred()


## 贏了：暫停遊戲、顯示勝利畫面
func win(message: String = "") -> void:
	_show_result(true, message)
	won.emit(message)


## 輸了：暫停遊戲、顯示失敗畫面
func lose(message: String = "") -> void:
	_show_result(false, message)
	lost.emit(message)


## 現在是不是正在顯示勝敗畫面
func is_finished() -> bool:
	return _result != null and is_instance_valid(_result)


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
