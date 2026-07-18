extends Control

@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton

## 讓外部場景（例如 demo_scene）可以自訂「離開遊戲」按鈕的文字與行為，
## 例如改成「返回主選單」並導向 SceneManager，而不是真的結束程式。
## 不呼叫的話維持預設行為：GameSession.request_quit()。
var _quit_action: Callable = Callable()


func _init():
	hide()


func _on_resume_button_pressed():
	get_tree().paused = false
	hide()


func _on_quit_button_pressed():
	if _quit_action.is_valid():
		_quit_action.call()
	else:
		GameSession.request_quit()


func configure_quit_button(text: String, action: Callable = Callable()) -> void:
	quit_button.text = text
	_quit_action = action
