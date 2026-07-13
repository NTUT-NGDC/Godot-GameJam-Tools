extends Node
class_name SFXOnButtonPress

## 要播放的音效名稱,跟 SoundBank 裡設定的 Sound Name 要一致
@export var sfx_name: String = ""


func _ready() -> void:
	var parent := get_parent()
	if parent is BaseButton:
		parent.pressed.connect(_on_pressed)
	else:
		push_warning("[SFXOnButtonPress] 這個節點必須放在 Button 底下才會生效")


func _on_pressed() -> void:
	if sfx_name != "":
		AudioManager.play_sfx(sfx_name)
