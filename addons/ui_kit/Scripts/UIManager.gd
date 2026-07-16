extends Node

###以下皆為暫停選單相關###

#請在編輯器中把玩家節點拖進來，玩家節點需要有player_died signal
@export var player_path: NodePath

#onready是電腦載入順序，等到PauseMenu載入好了，才能使用。
@onready var pause_menu = $Canvas/PauseMenu

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	#連接玩家死亡事件
	if player_path.is_empty():
		return
	var player = get_node(player_path)
	player.player_died.connect(show_death_menu)

#ui_cancel是內建的ESC離開按鍵綁定
#接下來使用toggle_pause
func _process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		toggle_pause()

#.paused是bool值，只有true/false
#!是使其相反，只能用在bool值
func toggle_pause():
	#死亡選單顯示時，忽略ESC，避免在死亡畫面下把遊戲解除暫停
	if death_menu.visible:
		return

	get_tree().paused = !get_tree().paused

	pause_menu.visible = get_tree().paused
	
###以上皆為暫停選單相關###

###以下為死亡選單###

@onready var death_menu = $Canvas/DeathMenu

func show_death_menu():	
	await get_tree().create_timer(0.1).timeout
	# 顯示死亡畫面
	death_menu.visible = true
	# 停止遊戲
	get_tree().paused = true
