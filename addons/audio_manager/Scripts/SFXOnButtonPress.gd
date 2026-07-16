extends SFXTrigger
class_name SFXOnButtonPress


func _ready() -> void:
	var parent := get_parent()
	if parent is BaseButton:
		parent.pressed.connect(play)
	else:
		push_warning("[SFXOnButtonPress] 這個節點必須放在 Button 底下才會生效")
