extends Control

func _ready():
	hide()

func _on_quit_button_pressed():
	get_tree().quit()

func _on_restart_button_pressed() -> void:
	print("重新開始按鈕被按")
	get_tree().paused = false
	get_tree().reload_current_scene()
