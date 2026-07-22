extends Node2D
## DemoScene - 整合示範：音效/BGM（AudioManager）、暫停/死亡選單與血條（ui_kit）、
## 存檔自動存檔（SaveManager/GameSession）、返回主選單（SceneManager）。

const TITLE_SCENE_PATH := "res://addons/demo/Scenes/title_scene.tscn"

@onready var player: Node2D = $DemoPlayer
@onready var stats_label: Label = $Canvas/TopBar/StatsLabel
@onready var pause_menu: Control = $UI/Canvas/PauseMenu


func _ready() -> void:
	AudioManager.register_bgm("DemoBGM", load("res://addons/audio_manager/Tests/Resources/The Insulindian Miracle.mp3"))
	AudioManager.register_sfx("DemoClick", load("res://addons/audio_manager/Tests/Resources/Retro Blop 22.wav"))
	AudioManager.register_sfx("DemoHit", load("res://addons/audio_manager/Tests/Resources/Retro PowerUP 23.wav"))
	AudioManager.play_bgm("DemoBGM")

	SaveManager.set_autosave_source(func(): return GameSession.game_data)

	player.stats_changed.connect(_refresh_stats_label)
	pause_menu.configure_quit_button("返回主選單", _go_to_title)
	_refresh_stats_label()


func _refresh_stats_label() -> void:
	var score: int = GameSession.game_data.get("score", 0)
	stats_label.text = "血量：%d　分數：%d" % [player.hp, score]


func _go_to_title() -> void:
	get_tree().paused = false
	SceneManager.change_scene(TITLE_SCENE_PATH)
