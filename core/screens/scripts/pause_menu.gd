extends CanvasLayer
## 暫停選單：遊戲中按 Esc 或右上角的「選單」打開。繼續／重來／設定／回到標題。
## 打開時整個遊戲會暫停，選單本身照常運作。
## GameFlow 會自動把它加進每個遊戲場景，不用自己放。
##
## 想改文字、字的大小、顏色：打開 pause_menu.tscn，點節點在右邊的檢查器改。

@onready var _menu_button: Button = %MenuButton
@onready var _menu_panel: Control = %MenuPanel
@onready var _settings: Control = %SettingsPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_menu_panel.hide()
	_settings.hide()
	_menu_button.pressed.connect(open_menu)
	(%ResumeButton as Button).pressed.connect(close_menu)
	(%RestartButton as Button).pressed.connect(_on_restart_pressed)
	(%SettingsButton as Button).pressed.connect(_settings.show)
	(%TitleButton as Button).pressed.connect(_on_title_pressed)
	_settings.connect("closed", _settings.hide)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause") or GameFlow.is_finished():
		return
	if _settings.visible:
		_settings.hide()
	elif _menu_panel.visible:
		close_menu()
	else:
		open_menu()
	get_viewport().set_input_as_handled()


## 打開選單，暫停遊戲
func open_menu() -> void:
	_menu_panel.show()
	_menu_button.hide()
	get_tree().paused = true
	(%ResumeButton as Button).grab_focus()


## 關掉選單，繼續遊戲
func close_menu() -> void:
	_menu_panel.hide()
	_settings.hide()
	_menu_button.show()
	get_tree().paused = false


func _on_restart_pressed() -> void:
	close_menu()
	SceneManager.reload()


func _on_title_pressed() -> void:
	close_menu()
	SceneManager.change_scene(GameConfig.TITLE_SCENE)
