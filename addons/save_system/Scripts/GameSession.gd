extends Node
## GameSession - 管理目前這一輪遊戲的資料（記憶體中），
## 並負責「開始新遊戲 / 繼續遊戲 / 離開時自動存檔」的邏輯。
##
## 設定方式：
## 專案設定 -> Autoload -> 依序加入 SaveManager、GameSession
## （順序很重要，GameSession 會用到 SaveManager）

## 新遊戲的初始資料，依你的遊戲需求自行增減欄位即可
const DEFAULT_DATA := {
	"score": 0,
	"level": 1,
}

## 目前這一輪遊戲的資料。遊戲進行中直接修改這個 Dictionary，
## 存檔/讀檔時整包丟給 SaveManager
var game_data: Dictionary = {}


func _ready() -> void:
	# 關閉「按視窗 X 直接強制關閉」的預設行為，
	# 改成：先收到關閉通知 -> 存檔 -> 才真的呼叫 quit()
	get_tree().set_auto_accept_quit(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		request_quit()


## 開始新遊戲：用預設值覆寫存檔，等同於「初始化存檔」
func start_new_game() -> void:
	game_data = DEFAULT_DATA.duplicate(true)
	SaveManager.save(game_data)


## 繼續遊戲：讀取存檔並放進 game_data，回傳是否成功
## （main_menu 應該搭配 SaveManager.has_save() 先把按鈕 disable 掉，
##  但這裡還是留一層防呆，避免特殊情況下讀到空資料）
func continue_game() -> bool:
	if not SaveManager.has_save():
		return false
	game_data = SaveManager.load()
	return true


## 從遊戲畫面手動存檔並返回主選單
func save_and_return_to_menu() -> void:
	SaveManager.save(game_data)
	get_tree().change_scene_to_file("res://addons/demo/Scenes/title_scene.tscn")


## 離開遊戲的唯一入口：不管是按「離開遊戲」按鈕，
## 還是按視窗右上角 X，都會先自動存檔，才真正結束程式
func request_quit() -> void:
	if not game_data.is_empty():
		SaveManager.save(game_data)
		print("GameSession: 離開前自動存檔完成")
	get_tree().quit()
