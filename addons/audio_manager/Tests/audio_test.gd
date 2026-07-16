extends Control

func _ready() -> void:
	AudioManager.register_bgm("BGM1", load("res://addons/audio_manager/Tests/Resources/The Insulindian Miracle.mp3"))
	AudioManager.register_sfx("SFX1", load("res://addons/audio_manager/Tests/Resources/Retro Blop 22.wav"))
	AudioManager.play_bgm("BGM1")

func _on_change_bgm_pressed() -> void:
	get_tree().change_scene_to_file("res://addons/audio_manager/Tests/Audio_TEST2.tscn")
