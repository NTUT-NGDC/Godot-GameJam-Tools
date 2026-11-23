extends Control
## 標題畫面：開始遊戲／設定／Credits／離開遊戲。這是專案的主場景，按 F5 會先看到它。
##
## 遊戲名稱、標語、開始場景不用改這裡：改專案最上層的 game_config.tres。
## 想改字的大小、顏色、背景圖：打開 title_screen.tscn，點節點在右邊的檢查器改。
##   ・背景圖：把圖片拖進 BackgroundImage 的 Texture

const CREDITS_SCENE: String = "res://core/screens/credits_screen.tscn"

@onready var _message: Label = %MessageLabel
@onready var _settings: Control = %SettingsPanel


func _enter_tree() -> void:
	add_to_group("no_pause")


func _ready() -> void:
	var config: GameConfig = GameConfig.current()
	(%GameName as Label).text = config.game_name
	(%Tagline as Label).text = config.tagline
	(%Tagline as Label).visible = config.tagline != ""
	_message.hide()
	_settings.hide()
	# Web 版沒辦法用程式關掉瀏覽器分頁，按了不會有反應，所以藏起來
	(%QuitButton as Button).visible = not OS.has_feature("web")
	(%StartButton as Button).pressed.connect(_on_start_pressed)
	(%SettingsButton as Button).pressed.connect(_settings.show)
	(%CreditsButton as Button).pressed.connect(func() -> void: SceneManager.change_scene(CREDITS_SCENE))
	(%QuitButton as Button).pressed.connect(GameSession.request_quit)
	_settings.connect("closed", _on_settings_closed)
	(%StartButton as Button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if _settings.visible and event.is_action_pressed("pause"):
		_on_settings_closed()
		get_viewport().set_input_as_handled()


func _on_settings_closed() -> void:
	_settings.hide()
	(%SettingsButton as Button).grab_focus()


## 開始遊戲：換到 game_config.tres 設定的開始場景
func _on_start_pressed() -> void:
	var start: String = GameConfig.current().start_scene
	if start == "" or not ResourceLoader.exists(start):
		_message.text = "還沒有設定開始場景。\n請雙擊專案最上層的 game_config.tres，設定「Start Scene」。"
		_message.show()
		return
	SceneManager.change_scene(start)
