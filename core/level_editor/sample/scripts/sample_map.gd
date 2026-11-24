class_name SampleMap
extends Resource
## 關卡編輯器的最小範例：一張地圖（牆、起點、星星）。欄位都有 @export，存成 .tres 就是看得懂的文字。

const CELL: int = 32

@export var map_name: String = "新地圖"
@export var size: Vector2i = Vector2i(20, 12)
## 有牆的格子
@export var walls: Array[Vector2i] = []
@export var start_cell: Vector2i = Vector2i(2, 2)
@export var stars: Array[Vector2i] = []
## 走多快（規則頁可以改）
@export_range(50, 600, 10, "suffix:px/s") var speed: float = 200.0


func ensure() -> void:
	pass


## 現在的樣子。陣列要複製，不然之後改地圖，記住的也會跟著變
func snapshot() -> Dictionary:
	return {"size": size, "walls": walls.duplicate(), "start_cell": start_cell, "stars": stars.duplicate(), "speed": speed}


func restore(state: Dictionary) -> void:
	size = state["size"]
	walls.assign(state["walls"])
	start_cell = state["start_cell"]
	stars.assign(state["stars"])
	speed = state["speed"]


func resize(to: Vector2i) -> void:
	size = to
	var area: Rect2i = Rect2i(Vector2i.ZERO, to)
	walls.assign(walls.filter(area.has_point))
	stars.assign(stars.filter(area.has_point))
	start_cell = start_cell.clamp(Vector2i.ZERO, to - Vector2i.ONE)


func set_wall(cell: Vector2i, on: bool) -> void:
	if on and not walls.has(cell) and Rect2i(Vector2i.ZERO, size).has_point(cell):
		walls.append(cell)
	elif not on:
		walls.erase(cell)


# ---- 轉成文字（MapText 用，給 AI 看地圖） ----

func text_letters() -> Dictionary:
	return {".": 0, "#": 1}


func text_kind(cell: Vector2i) -> int:
	return 1 if walls.has(cell) else 0


func set_text_kind(cell: Vector2i, kind: int) -> void:
	set_wall(cell, kind == 1)


func text_fields() -> Array[String]:
	return ["start_cell", "stars"]
