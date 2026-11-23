extends CanvasLayer
## 勝利／失敗畫面：GameFlow.win()／lose() 時跳出來。再玩一次、回到標題。
## 想改文字、顏色：打開 result_screen.tscn，點節點在右邊的檢查器改。

## 勝利、失敗時大標題的文字和顏色
const WIN_TEXT: String = "勝利！"
const LOSE_TEXT: String = "失敗……"
const WIN_COLOR: Color = Color("ffd75e")
const LOSE_COLOR: Color = Color("ff6b6b")

@onready var _title: Label = %ResultTitle
@onready var _message: Label = %ResultMessage


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	(%RetryButton as Button).pressed.connect(_on_retry_pressed)
	(%TitleButton as Button).pressed.connect(_on_title_pressed)


func show_result(is_win: bool, message: String) -> void:
	_title.text = WIN_TEXT if is_win else LOSE_TEXT
	_title.add_theme_color_override("font_color", WIN_COLOR if is_win else LOSE_COLOR)
	_message.text = message
	_message.visible = message != ""
	var title_text: String = GameFlow.title_button_text()          # 「回標題」可能被換成別的（GameFlow.set_title_button）
	if not title_text.is_empty():
		(%TitleButton as Button).text = title_text
	(%RetryButton as Button).grab_focus()


func _on_retry_pressed() -> void:
	SceneManager.reload()


func _on_title_pressed() -> void:
	GameFlow.go_title()
