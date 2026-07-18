extends Control

func _on_button_quit_pressed() -> void:
	GameSession.request_quit()
