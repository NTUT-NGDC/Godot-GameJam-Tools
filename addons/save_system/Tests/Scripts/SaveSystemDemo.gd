extends Control
## SaveSystemDemo - 存檔系統範例場景
## 示範 Game Jam 遊戲最常用到的三個流程：
## 開始遊戲（初始化存檔）、繼續遊戲（讀取存檔）、離開遊戲（自動存檔）


func _ready() -> void:
	_refresh_ui()


func _on_new_game_button_pressed() -> void:
	GameSession.start_new_game()
	_log("已開始新遊戲，存檔已初始化。")
	_refresh_ui()


func _on_continue_button_pressed() -> void:
	if GameSession.continue_game():
		_log("讀取存檔成功。")
	else:
		_log("讀取存檔失敗，找不到存檔。")
	_refresh_ui()


func _on_add_score_button_pressed() -> void:
	GameSession.game_data["score"] = GameSession.game_data.get("score", 0) + 1
	_log("分數 +1（尚未寫入檔案，離開遊戲時會自動存檔）。")
	_refresh_ui()


func _on_quit_button_pressed() -> void:
	# 不直接呼叫 get_tree().quit()，統一走 GameSession 的離開入口，
	# 確保離開前一定會自動存檔
	GameSession.request_quit()


func _refresh_ui() -> void:
	var has_save := SaveManager.has_save()
	%StatusLabel.text = "狀態：%s" % ("找到存檔" if has_save else "沒有存檔")
	%ContinueButton.disabled = not has_save
	%AddScoreButton.disabled = GameSession.game_data.is_empty()

	if GameSession.game_data.is_empty():
		%DataLabel.text = "目前資料：（尚未載入，請先開始或繼續遊戲）"
	else:
		%DataLabel.text = "目前資料：%s" % [GameSession.game_data]


func _log(text: String) -> void:
	%LogLabel.text = text
	print("SaveSystemDemo: ", text)
