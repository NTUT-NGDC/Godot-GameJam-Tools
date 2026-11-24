class_name MapText
extends RefCounted
## 地圖 ↔ 看得懂的文字（給 AI 看、畫草稿用）。上面一格一個字，下面是「欄位: x,y x,y」。
## 寫回去只改不一樣的格子，所以圓滑的邊緣、沒寫在文字裡的東西（小隊、規則……）都留著。
##
## 地圖要有：
##   text_letters()          {字: 地形代號}
##   text_kind(格子)          那一格的地形代號
##   set_text_kind(格子, 代號)
##   text_fields()           哪些欄位是格子（Vector2i 或 Array[Vector2i]）
##
## 命令列：
##   godot --headless --path . res://core/level_editor/map_text.tscn -- export res://地圖.tres 檔案.txt
##   godot --headless --path . res://core/level_editor/map_text.tscn -- import res://地圖.tres 檔案.txt
##   godot --headless --path . res://core/level_editor/map_text.tscn -- new res://新地圖.tres 檔案.txt res://地圖的腳本.gd

static func to_text(map: Resource) -> String:
	var letters: Dictionary = map.call("text_letters")
	var size: Vector2i = map.get("size")
	var rows: PackedStringArray = PackedStringArray()
	for y: int in size.y:
		var row: String = ""
		for x: int in size.x:
			row += String(letters.find_key(map.call("text_kind", Vector2i(x, y))))
		rows.append(row)
	rows.append("")
	for field: String in map.call("text_fields"):
		var value: Variant = map.get(field)
		var cells: Array = value if value is Array else [value]
		rows.append("%s: %s" % [field, " ".join(cells.map(func(c: Vector2i) -> String: return "%d,%d" % [c.x, c.y]))])
	return "\n".join(rows) + "\n"


## 把文字寫進地圖（大小照文字）。回傳哪裡寫錯了（沒錯＝空字串；寫錯的話地圖不會動）
static func apply(map: Resource, text: String) -> String:
	var letters: Dictionary = map.call("text_letters")
	var rows: PackedStringArray = PackedStringArray()
	var points: Dictionary[String, Array] = {}
	for line: String in text.replace("\r", "").split("\n"):
		if line.contains(":"):
			var field: String = line.get_slice(":", 0).strip_edges()
			if not (map.call("text_fields") as Array).has(field):
				return "沒有「%s」這個欄位" % field
			var cells: Array[Vector2i] = []
			for item: String in line.get_slice(":", 1).split(" ", false):
				if not item.get_slice(",", 0).is_valid_int() or not item.get_slice(",", 1).is_valid_int():
					return "「%s」不是格子，要寫 x,y" % item
				cells.append(Vector2i(item.get_slice(",", 0).to_int(), item.get_slice(",", 1).to_int()))
			points[field] = cells
		elif not line.strip_edges().is_empty():
			rows.append(line.strip_edges())
	if rows.is_empty():
		return "沒有地圖"
	for y: int in rows.size():
		if rows[y].length() != rows[0].length():
			return "第 %d 列有 %d 個字，第 1 列有 %d 個，要一樣長" % [y + 1, rows[y].length(), rows[0].length()]
		for x: int in rows[y].length():
			if not letters.has(rows[y][x]):
				return "第 %d 列的「%s」不認得，可以用：%s" % [y + 1, rows[y][x], " ".join(letters.keys())]
	var size: Vector2i = Vector2i(rows[0].length(), rows.size())
	for field: String in points:
		for cell: Vector2i in points[field]:
			if not Rect2i(Vector2i.ZERO, size).has_point(cell):
				return "%s 的 %d,%d 在地圖外面" % [field, cell.x, cell.y]
		if not map.get(field) is Array and points[field].size() != 1:
			return "%s 要剛好一格" % field
	map.call("ensure")
	if map.get("size") != size:
		map.call("resize", size)
		if map.get("size") != size:
			return "這種地圖不能這麼小：%d×%d" % [size.x, size.y]
	for y: int in size.y:
		for x: int in size.x:
			var kind: int = letters[rows[y][x]]
			if map.call("text_kind", Vector2i(x, y)) != kind:
				map.call("set_text_kind", Vector2i(x, y), kind)
	for field: String in points:
		if map.get(field) is Array:
			(map.get(field) as Array).assign(points[field])
		else:
			map.set(field, points[field][0])
	map.emit_changed()
	return ""
