extends Control

func _ready() -> void:
	AudioManager.play_bgm(preload("res://addons/audio_manager/Resources/The Insulindian Miracle.mp3"))
	print("開場BGM播放：第二首")

func _on_button_pressed() -> void:
	AudioManager.play_sfx(preload("res://addons/audio_manager/Resources/Retro Blop 22.wav"))
	get_tree().change_scene_to_file("res://addons/audio_manager/Audio_TEST.tscn")


func _on_play_sfx_pressed() -> void:
	AudioManager.play_sfx(preload("res://addons/audio_manager/Resources/Retro Blop 22.wav"))
