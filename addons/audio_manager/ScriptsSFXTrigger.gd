extends Node
class_name SFXTrigger

@export var sfx_name: String = ""

func play() -> void:
	if sfx_name != "":
		AudioManager.play_sfx(sfx_name)
