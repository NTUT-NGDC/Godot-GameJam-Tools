extends Control
## 設定面板：音樂、音效音量、全螢幕。標題畫面和暫停選單共用這一個。
## 音量交給 AudioManager（會自動記住），全螢幕直接切視窗。

## 按了「返回」
signal closed()

@onready var _music: HSlider = %MusicSlider
@onready var _sfx: HSlider = %SfxSlider
@onready var _fullscreen: CheckBox = %FullscreenCheck


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_music.value = AudioManager.bgm_volume
	_sfx.value = AudioManager.sfx_volume
	_fullscreen.button_pressed = is_fullscreen()
	_music.value_changed.connect(AudioManager.set_bgm_volume)
	_sfx.value_changed.connect(AudioManager.set_sfx_volume)
	_fullscreen.toggled.connect(set_fullscreen)
	(%BackButton as Button).pressed.connect(closed.emit)
	visibility_changed.connect(_on_visibility_changed)


func _on_visibility_changed() -> void:
	if visible:
		_fullscreen.set_pressed_no_signal(is_fullscreen())
		(%BackButton as Button).grab_focus()


static func is_fullscreen() -> bool:
	return DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN


static func set_fullscreen(on: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if on else DisplayServer.WINDOW_MODE_WINDOWED)
