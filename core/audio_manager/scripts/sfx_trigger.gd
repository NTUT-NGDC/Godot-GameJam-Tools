class_name SFXTrigger
extends Node
## 呼叫 play() 就播放一個音效（名字要先在 SoundBank 登記）

## 要播的音效名字
@export var sfx_name: String = ""

func play() -> void:
	if sfx_name != "":
		AudioManager.play_sfx(sfx_name)
