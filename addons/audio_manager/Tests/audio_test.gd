extends Control

func _on_change_bgm_pressed() -> void:
	get_tree().change_scene_to_file("res://addons/audio_manager/Tests/Audio_TEST2.tscn")
