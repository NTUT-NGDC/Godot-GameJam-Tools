extends LevelEditor
## 關卡編輯器的最小範例：畫牆、放起點和星星。打開 sample_editor.tscn 按 F6。
## 做自己的編輯器可以從這份抄。

enum Tool { WALL, START, STAR }

var sample: SampleMap:
	get: return map as SampleMap


func _setup() -> void:
	title = "範例編輯器"
	maps_dir = "res://core/level_editor/sample/maps/"
	play_scene = load("res://core/level_editor/sample/sample_level.tscn")
	grid_only = true                                              # 一格一格畫
	brush = 16.0
	min_brush = 16.0
	brush_step = 16.0
	add_tool("牆", true)                                          # 順序跟 Tool 一樣
	add_tool("起點")
	add_tool("星星")


func _new_map() -> Resource:
	return SampleMap.new()


func check_map() -> String:
	return "至少要放一顆星星" if sample.stars.is_empty() else ""


# ---- 畫牆 ----

func _paint(cells: Rect2i) -> void:
	for x: int in range(cells.position.x, cells.end.x):
		for y: int in range(cells.position.y, cells.end.y):
			sample.set_wall(Vector2i(x, y), not _erasing)


func _paint_dab(at: Vector2) -> void:
	_paint(brush_cells(at))


func _paint_rect(from: Vector2, to: Vector2) -> void:
	_paint(cells_between(from, to))


func _clear() -> void:
	sample.walls.clear()


## 形狀只要畫筆、矩形，不放圓形和油漆桶
func _build_rows() -> void:
	var row: HBoxContainer = add_row(592)
	add_tool_buttons(row)
	add_shape_buttons(row, false, [Shape.BRUSH, Shape.RECT])
	row = add_row(626)
	add_file_controls(row)
	add_size_boxes(row)


func _build_pages() -> void:
	add_page("地圖")                                              # 第一頁一定是地圖
	add_form_page("規則", ["speed"])


# ---- 放東西 ----

func place(cell: Vector2i) -> bool:
	if not has_cell(cell) or sample.walls.has(cell):
		return false
	if tool == Tool.START:
		if sample.start_cell == cell:
			return false
		remember()                                                # 確定會改才記
		sample.start_cell = cell
	else:
		if sample.stars.has(cell):
			return false
		remember()
		sample.stars.append(cell)
	return true


func unplace(cell: Vector2i) -> bool:
	if tool != Tool.STAR or not sample.stars.has(cell):
		return false
	remember()
	sample.stars.erase(cell)
	return true


# ---- 畫出來（東西少的話全部用 draw 畫就好，不用 _make_view） ----

func _draw_map(canvas: Node2D) -> void:
	canvas.draw_rect(cells_rect(Rect2i(Vector2i.ZERO, sample.size)), Color("8fb06a"))
	for cell: Vector2i in sample.walls:
		canvas.draw_rect(cells_rect(Rect2i(cell, Vector2i.ONE)), Color("4a4a52"))
	canvas.draw_circle(cell_center(sample.start_cell), 12.0, Color("3a7ae0"))
	for cell: Vector2i in sample.stars:
		canvas.draw_circle(cell_center(cell), 8.0, Color("ffd447"))


# ---- 試玩、做成關卡 ----

func _before_test() -> void:
	SampleLevel.test_map = sample.duplicate(true) as SampleMap


func _level_request(map_path: String) -> Dictionary:
	return {"path": "res://core/level_editor/sample/levels/%s.tscn" % map_path.get_file().get_basename(),
		"base": play_scene.resource_path, "values": {".": {"map": map_path}}}
