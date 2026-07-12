extends Node2D

#雖然是測試用的但我想把它保持在中立位置
func _ready():
	position = get_viewport_rect().size / 2

#穩定且持續運轉的函數
#delta是幀與幀之間的時間
func _physics_process(delta):
	rotation += delta
