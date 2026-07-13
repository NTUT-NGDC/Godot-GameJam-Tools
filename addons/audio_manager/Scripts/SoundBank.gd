extends Node
class_name SoundBank

@export var bgm_entries: Array[SoundEntry] = []
@export var sfx_entries: Array[SoundEntry] = []

func _ready() -> void:
	for entry in bgm_entries:
		if entry != null and entry.sound_name != "":
			AudioManager.register_bgm(entry.sound_name, entry.stream)

	for entry in sfx_entries:
		if entry != null and entry.sound_name != "":
			AudioManager.register_sfx(entry.sound_name, entry.stream)
