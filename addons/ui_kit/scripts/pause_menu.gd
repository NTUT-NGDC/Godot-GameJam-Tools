extends CanvasLayer

func _on_resume_button_pressed():
	get_tree().paused = false
	hide()

func _on_quit_button_pressed():
	get_tree().quit()
