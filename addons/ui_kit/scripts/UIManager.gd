extends Node

###以下皆為暫停選單相關###

#onready是電腦載入順序，等到PauseMenu載入好了，才能使用。
@onready var pause_menu = $Canvas/PauseMenu

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

#ui_cancel是內建的ESC離開按鍵綁定
#接下來使用toggle_pause
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

#.paused是bool值，只有true/false
#!是使其相反，只能用在bool值
func toggle_pause():
	get_tree().paused = !get_tree().paused
	
	pause_menu.visible = get_tree().paused
	
###以上皆為暫停選單相關###
