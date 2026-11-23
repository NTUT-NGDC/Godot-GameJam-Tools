class_name SoundEntry
extends Resource
## 一個音效：名字＋音檔（給 SoundBank 用）

## 播放時用的名字，整個專案不能重複
@export var sound_name: String = ""
## 音檔（.wav、.ogg、.mp3）
@export var stream: AudioStream
