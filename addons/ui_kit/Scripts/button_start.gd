extends Control

#請在編輯器中把想要的遊戲主場景拖進來；沒設定的話按下去會重新載入目前場景
@export var target_scene: PackedScene

func _on_button_start_pressed() -> void:
	if target_scene:
		get_tree().change_scene_to_packed(target_scene)
	else:
		get_tree().reload_current_scene()
