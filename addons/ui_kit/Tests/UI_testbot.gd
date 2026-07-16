extends Node2D

#雖然是測試用的但我想把它保持在中立位置
func _ready():
	position = get_viewport_rect().size / 2

#穩定且持續運轉的函數
#delta是幀與幀之間的時間
func _physics_process(delta):
	rotation += delta

#以下為測試扣血用
#扣血按鈕在專案設定中，按鍵為B。
var hp = 10
var dead = false
signal player_died

func take_damage(amount):
	
	if dead:
		return
	
	hp = max(0 , hp-amount)
	print("目前血量:", hp)
	
	if hp <= 0:
		die()
		
func die():
	dead = true
	print("玩家死亡")
	player_died.emit()

func _process(delta):
	if Input.is_action_just_pressed("damage_test"):
		take_damage(1)
		
#以上為測試扣血用
