extends Node
class_name SoundBank

@export var bgm_entries: Array[SoundEntry] = []
@export var sfx_entries: Array[SoundEntry] = []

## 新增:場景一開始要自動播放的BGM名稱,留空就不自動播放
@export var auto_play_bgm: String = ""

## 新增:BGM淡入淡出秒數,方便在 Inspector 微調
@export var auto_play_fade_time: float = 1.0


func _ready() -> void:
	# 先把所有音效註冊給 AudioManager
	for entry in bgm_entries:
		if entry != null and entry.sound_name != "":
			AudioManager.register_bgm(entry.sound_name, entry.stream)

	for entry in sfx_entries:
		if entry != null and entry.sound_name != "":
			AudioManager.register_sfx(entry.sound_name, entry.stream)

	# 註冊完之後,如果有設定自動播放的BGM,就自動播放
	if auto_play_bgm != "":
		AudioManager.play_bgm(auto_play_bgm, auto_play_fade_time)
