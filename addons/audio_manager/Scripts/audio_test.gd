extends Control

func _on_button_pressed() -> void:
	AudioManager.play_sfx("SFX1")
	get_tree().change_scene_to_file("res://addons/audio_manager/Audio_TEST2.tscn")


func _on_play_sfx_pressed() -> void:
	AudioManager.play_sfx("SFX1")
