extends Control

func _ready() -> void:
	AudioManager.register_bgm("BGM2", load("res://addons/audio_manager/Tests/Resources/Your Body Betrays Your Degeneracy.mp3"))
	AudioManager.register_sfx("SFX1", load("res://addons/audio_manager/Tests/Resources/Retro Blop 22.wav"))
	AudioManager.play_bgm("BGM2")

func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://addons/audio_manager/Tests/Audio_TEST.tscn")
