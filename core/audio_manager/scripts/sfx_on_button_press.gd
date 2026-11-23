class_name SFXOnButtonPress
extends SFXTrigger
## 放在按鈕底下：按下按鈕就播音效


func _ready() -> void:
	var parent: BaseButton = get_parent() as BaseButton
	if parent != null:
		parent.pressed.connect(play)
	else:
		push_warning("[SFXOnButtonPress] 這個節點必須放在 Button 底下才會生效")
