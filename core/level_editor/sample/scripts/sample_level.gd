class_name SampleLevel
extends Node2D
## 最小範例的關卡：讀地圖、WASD 走、撿完星星就贏。
## 編輯器試玩時會先把地圖放進 test_map；平常用檢查器的 map。

## 編輯器試玩用的地圖（用過就清掉）
static var test_map: SampleMap

## 這一關的地圖
@export var map: SampleMap

var player: Vector2
var stars: Array[Vector2i] = []


func _ready() -> void:
	if test_map != null:
		map = test_map
		test_map = null
	if map == null:
		map = SampleMap.new()
	player = center(map.start_cell)
	stars = map.stars.duplicate()


func center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * SampleMap.CELL


func _physics_process(delta: float) -> void:
	var move: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down") * map.speed * delta
	for step: Vector2 in [Vector2(move.x, 0), Vector2(0, move.y)]:
		if can_stand(player + step):
			player += step
	var cell: Vector2i = Vector2i((player / SampleMap.CELL).floor())
	if stars.has(cell):
		stars.erase(cell)
		if stars.is_empty():
			GameFlow.win("撿完了！")
	queue_redraw()


func can_stand(at: Vector2) -> bool:
	for corner: Vector2 in [Vector2(-10, -10), Vector2(10, -10), Vector2(-10, 10), Vector2(10, 10)]:
		var cell: Vector2i = Vector2i(((at + corner) / SampleMap.CELL).floor())
		if map.walls.has(cell) or not Rect2i(Vector2i.ZERO, map.size).has_point(cell):
			return false
	return true


func _draw() -> void:
	var one: Vector2 = Vector2.ONE * SampleMap.CELL
	draw_rect(Rect2(Vector2.ZERO, Vector2(map.size) * SampleMap.CELL), Color("8fb06a"))
	for cell: Vector2i in map.walls:
		draw_rect(Rect2(Vector2(cell) * SampleMap.CELL, one), Color("4a4a52"))
	for cell: Vector2i in stars:
		draw_circle(center(cell), 8.0, Color("ffd447"))
	draw_circle(player, 12.0, Color("3a7ae0"))
