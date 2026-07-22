extends Control
## TitleScene - 主選單：開始新遊戲 / 繼續遊戲 / 選項（音量設定）/ 離開遊戲。

const DEMO_SCENE_PATH := "res://addons/demo/Scenes/demo_scene.tscn"

@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var options_button: Button = %OptionsButton
@onready var quit_button: Button = %QuitButton
@onready var options_panel: Control = $OptionsPanel
@onready var close_options_button: Button = $OptionsPanel/Panel/VBoxContainer/CloseButton


func _ready() -> void:
	continue_button.disabled = not SaveManager.has_save()
	options_panel.hide()

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_options_button.pressed.connect(_on_close_options_pressed)


func _on_new_game_pressed() -> void:
	GameSession.start_new_game()
	SceneManager.change_scene(DEMO_SCENE_PATH)


func _on_continue_pressed() -> void:
	if GameSession.continue_game():
		SceneManager.change_scene(DEMO_SCENE_PATH)


func _on_options_pressed() -> void:
	options_panel.show()


func _on_close_options_pressed() -> void:
	options_panel.hide()


func _on_quit_pressed() -> void:
	GameSession.request_quit()
