extends Control

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://addons/audio_manager/Tests/Audio_TEST.tscn")
