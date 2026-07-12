extends Node2D

func _ready():
	position = get_viewport_rect().size / 2

#穩定且持續運轉的函數
#delta是幀與幀之間的時間
func _physics_process(delta):
	rotation += delta
