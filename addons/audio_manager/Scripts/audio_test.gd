extends Control

func _ready() -> void:
	AudioManager.play_bgm(preload("res://addons/audio_manager/Resources/Your Body Betrays Your Degeneracy.mp3"))
	print("開場BGM播放：第一首")

func _on_button_pressed() -> void:
	AudioManager.play_sfx(preload("res://addons/audio_manager/Resources/Retro Blop 22.wav"))
	get_tree().change_scene_to_file("res://addons/audio_manager/Audio_TEST2.tscn")


func _on_play_sfx_pressed() -> void:
	AudioManager.play_sfx(preload("res://addons/audio_manager/Resources/Retro Blop 22.wav"))
