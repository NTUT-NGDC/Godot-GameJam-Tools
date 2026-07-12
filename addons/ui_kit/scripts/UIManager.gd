extends Node

###以下皆為暫停選單相關###

@onready var pause_menu = $"../PauseMenu"

func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()


func toggle_pause():
	get_tree().paused = !get_tree().paused
	
	pause_menu.visible = get_tree().paused
	
###以上皆為暫停選單相關###
