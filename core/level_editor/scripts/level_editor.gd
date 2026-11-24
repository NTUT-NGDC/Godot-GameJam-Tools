class_name LevelEditor
extends Node2D
## 關卡編輯器的底：遊戲裡的編輯器（打開場景按 F6），不用學 Godot 的場景、檢查器就能做關卡。
## 這裡有：分頁、畫格子和放東西的工具、上一步／下一步、存檔讀檔、沒存檔會變黃、直接試玩、鏡頭、做成關卡。
## 做自己的編輯器：extends LevelEditor，覆寫「給各個編輯器覆寫」那一段，完整步驟看 core/level_editor/README.md。
##
## 正在編輯的東西叫 map，是一個 Resource，要有：
##   var map_name: String、var size: Vector2i（格數）
##   ensure()      補齊資料（新地圖、舊檔案）
##   snapshot()    現在的樣子（Dictionary；上一步、有沒有改過都看這個，所以要複製、不能給原本的陣列）
##   restore(資料) 變回 snapshot() 的樣子
##   resize(格數)
##
## 存檔是寫進專案資料夾，只有在 Godot 編輯器裡按 F6 才能存（匯出的遊戲不能存）。

## 畫地形的方式
enum Shape { BRUSH, RECT, ELLIPSE, FILL }
const SHAPE_NAMES: Array[String] = ["畫筆", "矩形", "圓形", "油漆桶"]
const MAX_HISTORY: int = 60
const PAINT_HINT: String = "左鍵畫、右鍵擦、滾輪調筆刷大小、Ctrl＋滾輪縮放"

## 各個編輯器編到一半的東西（暫停選單按「重來」時場景會重新載入，要留著）：腳本路徑 → 資料
static var _sessions: Dictionary[String, Dictionary] = {}

# ---- 設定（在 _setup() 裡改） ----

## 左上角的標題
var title: String = "關卡編輯器"
## 試玩時，暫停選單、勝敗畫面的「回標題」換成什麼字
var back_text: String = "回編輯器"
## 地圖存在這個資料夾（最後要有 /）
var maps_dir: String = ""
## 試玩用的關卡
var play_scene: PackedScene
## 地圖放在畫面的哪裡
var origin: Vector2 = Vector2(64, 48)
## 一格幾像素
var cell_size: int = 32
var min_size: Vector2i = Vector2i(4, 4)
var max_size: Vector2i = Vector2i(200, 200)
var min_brush: float = 8.0
var max_brush: float = 120.0
## 滾輪一格調多少
var brush_step: float = 4.0
## 一定照格子畫（不能圓滑）
var grid_only: bool = false
## 有問題（check_map()）的時候不能存檔；false＝可以存，只提醒
var save_needs_ok: bool = false
## 鏡頭可以超出地圖多少：左、上、右、下
var camera_margin: Vector4 = Vector4(64, 48, 64, 160)
## 工具列離左邊多遠
var ui_left: float = 16.0
var stop_position: Vector2 = Vector2(1020, 22)
## 工具：{"name": 名字, "paint": 是不是畫地形的, "gap": 後面要不要隔線, "category": 分類}，用 add_tool() 加
var tools: Array[Dictionary] = []
## 分頁：{"name", "panel", "hint", "own_save"}，用 add_page() 加。第一頁是地圖
var pages: Array[Dictionary] = []
## 工具的分類（沒有＝不分類）。add_tool() 給了分類就會自動加，也可以用 add_category() 先排順序
var categories: PackedStringArray = PackedStringArray()

# ---- 狀態 ----

var map: Resource
var tool: int = 0
## 現在在哪個分類
var category: String = ""
var shape: int = Shape.BRUSH
## 筆刷半徑（像素）
var brush: float = 28.0

## 正在編輯的地圖（重新載入時留著）
var editing: Resource:
	get: return _session.get("editing")
	set(value): _session["editing"] = value
## 重新載入時要不要接著試玩（試玩中按了暫停選單的「重來」）
var resume_test: bool:
	get: return _session.get("resume_test", false)
	set(value): _session["resume_test"] = value
## 上次存檔（讀檔、新地圖）時的樣子，用來看有沒有東西還沒存
var saved_state: Dictionary:
	get: return _session.get("saved_state", {})
	set(value): _session["saved_state"] = value
var saved_name: String:
	get: return _session.get("saved_name", "")
	set(value): _session["saved_name"] = value
## 現在在哪一頁
var page: int:
	get: return _session.get("page", 0)
	set(value): _session["page"] = value
## 對齊格子畫（關掉＝圓滑的）
var snap: bool:
	get: return grid_only or _session.get("snap", false)
	set(value): _session["snap"] = value

var _session: Dictionary = session_of((get_script() as Script).resource_path)
var _view: Node2D
## 畫在地形上面的東西（物件、筆刷）
var _overlay: Node2D
var _camera: PanCamera
var _camera_tween: Tween
## 試玩中的關卡（沒在試玩＝null）
var _play: Node
var _painting: bool = false
var _erasing: bool = false
var _last_paint: Vector2
## 矩形、圓形：拖曳的起點（沒在拖＝null）
var _drag_from: Variant = null
var _history: Array[Dictionary] = []
var _future: Array[Dictionary] = []
var _ui: CanvasLayer
## 地圖頁的工具列（換頁時藏起來）
var _map_tools: Control
## 第幾個工具 → 按鈕
var _tool_buttons: Dictionary[int, Button] = {}
## 第幾種形狀 → 按鈕
var _shape_buttons: Dictionary[int, Button] = {}
var _page_buttons: Array[Button] = []
## 分類 → 按鈕
var _category_buttons: Dictionary[String, Button] = {}
## 只在某些分類出現的東西：{"node", "categories"}
var _category_parts: Array[Dictionary] = []
## 分類 → 上次用第幾個工具
var _category_tools: Dictionary[String, int] = {}
var _snap_button: Button
var _name_edit: LineEdit
var _load_list: OptionButton
var _width: SpinBox
var _height: SpinBox
var _save_button: Button
var _stop_button: Button
## 試玩前問要不要存檔的視窗，和問完怎麼開始
var _ask: ConfirmationDialog
var _test_start: Callable
var _status: Label
var _status_text: String = ""
## 每隔一小段時間看一次有沒有東西還沒存
var _check_time: float = 0.0


## 某個編輯器（或某一頁）編到一半的東西
static func session_of(key: String) -> Dictionary:
	if not _sessions.has(key):
		_sessions[key] = {}
	return _sessions[key]


## 全部忘掉（測試用）
static func forget_sessions() -> void:
	for key: String in _sessions:
		_sessions[key].clear()


# ---- 給各個編輯器覆寫 ----

## 設定：標題、資料夾、試玩的關卡、add_tool()……
func _setup() -> void:
	pass


## 一張新的地圖
func _new_map() -> Resource:
	return null


## 畫出地圖的節點（會放在 origin；有 map 屬性的話會自動給它現在的地圖）
func _make_view() -> Node2D:
	return Node2D.new()


## 加分頁：add_page()，第一頁一定是地圖
func _build_pages() -> void:
	add_page("地圖")


## 地圖頁的工具列：預設第一排工具、第二排檔案和大小。要加自己的按鈕就覆寫（檔案那組一定要有）
func _build_rows() -> void:
	var row: HBoxContainer = add_row(592)
	add_tool_buttons(row)
	add_shape_buttons(row)
	row = add_row(626)
	add_file_controls(row)
	add_size_boxes(row)


## 換了地圖、上一步、改大小：更新自己的畫面
func _map_shown() -> void:
	pass


## 換到第幾頁了
func _page_shown(_index: int) -> void:
	pass


## 畫在地形上面的東西（物件、路線）：用 canvas.draw_xxx()，座標是地圖裡的像素
func _draw_map(_canvas: Node2D) -> void:
	pass


## 筆刷畫一下（at＝地圖裡的像素座標；_erasing＝右鍵；snap＝要照格子，用 brush_cells(at)）
func _paint_dab(_at: Vector2) -> void:
	pass


## 拖曳畫矩形、圓形（snap＝要照格子，用 cells_between(from, to)）
func _paint_rect(_from: Vector2, _to: Vector2) -> void:
	pass


func _paint_ellipse(_from: Vector2, _to: Vector2) -> void:
	pass


## 油漆桶。回傳換掉了多少（0＝什麼都沒換，這一步不算）
func _paint_fill(_at: Vector2) -> int:
	return 0


## 用現在的工具（tool）在格子上放東西、拿掉東西。確定會改才 remember()，回傳有沒有改到
func place(_cell: Vector2i) -> bool:
	return false


func unplace(_cell: Vector2i) -> bool:
	return false


## 滑鼠移動（拖著東西走用）
func _mouse_moved(_at: Vector2) -> void:
	pass


## 地圖少了什麼不能玩（回傳問題，沒問題＝空字串）
func check_map() -> String:
	return ""


## 清空地形
func _clear() -> void:
	pass


## 放試玩的關卡之前：把地圖交給關卡（例如放進關卡腳本的 static 變數）
func _before_test() -> void:
	pass


## 編輯器裡還沒存檔的東西有沒有用到這個場景（有的話不給刪；回傳哪裡，沒有＝空字串）
func _used_in_editor(path: String) -> String:
	return "現在編的地圖" if str(map.call("snapshot")).contains(path) else ""


## 場景頁刪掉了一個場景：有用到它的上一步也不要了（不然退回去會讀不到）。要更新清單就覆寫（記得 super）
func _scene_deleted(path: String) -> void:
	var gone: Callable = func(state: Dictionary) -> bool: return not str(state).contains(path)
	_history.assign(_history.filter(gone))
	_future.assign(_future.filter(gone))


## 停止試玩
func _after_test() -> void:
	pass


## 試玩中按「重來」，場景重新載入之後
func _resume() -> void:
	start_test()


## 地圖叫這個名字時存在哪
func _path_of(text: String) -> String:
	return maps_dir + text.validate_filename() + ".tres"


## 寫檔、讀檔（不是存成 .tres 的才要覆寫）
func _write(path: String) -> Error:
	var error: Error = ResourceSaver.save(map, path)
	if error == OK:
		map.take_over_path(path)
	return error


func _read(path: String) -> Resource:
	return ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE_DEEP)


## 做成關卡：回傳 {"path": 存到哪, "base": 繼承哪個關卡, "values": {節點: {屬性: 資源路徑}}}；不能做就 say() 原因、回傳 {}
func _level_request(_map_path: String) -> Dictionary:
	return {}


## 最上面那排的最後面（預設：做成關卡）
func _build_top(row: Control) -> void:
	row.add_child(VSeparator.new())
	add_button(row, "做成關卡", make_level).tooltip_text = "把現在的地圖（要先存檔）做成一個關卡場景"


# ---- 開始 ----

func _ready() -> void:
	Engine.time_scale = 1.0
	_setup()
	map = editing if editing != null else _new_map()
	map.call("ensure")
	if editing == null:
		_mark_saved()
	editing = map
	_view = _make_view()
	_view.name = "Terrain"
	_view.position = origin
	add_child(_view)
	_overlay = Node2D.new()
	_overlay.name = "Overlay"
	_overlay.position = origin
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_camera = (load("res://core/camera/pan_camera.tscn") as PackedScene).instantiate()
	_camera.zoom_modifier = 1                                     # Ctrl＋滾輪縮放；滾輪留給筆刷
	add_child(_camera)
	_build_ui()
	refresh_files()
	show_map()
	set_tool(tool)
	set_shape(shape)
	GameFlow.set_pause_enabled(false)                             # 編輯時不要暫停選單（試玩時才有）
	set_page(page)
	if resume_test:
		_resume.call_deferred()


func _exit_tree() -> void:
	GameFlow.set_pause_enabled(true)
	GameFlow.reset_title_button()


## 換了地圖（讀檔、新地圖、上一步……）：更新所有畫面
func show_map() -> void:
	_view.set("map", map)
	_name_edit.text = map.get("map_name")
	var cells: Vector2i = map.get("size")
	if _width != null:
		_width.set_value_no_signal(cells.x)
		_height.set_value_no_signal(cells.y)
	_camera.set_limit_rect(Rect2(origin, Vector2(cells * cell_size)).grow_individual(camera_margin.x, camera_margin.y, camera_margin.z, camera_margin.w))
	for item: Dictionary in pages:
		if item["panel"] is LevelEditorFormPage:
			(item["panel"] as LevelEditorFormPage).refresh()
	_map_shown()
	_view.queue_redraw()


# ---- 滑鼠、鍵盤 ----

func _unhandled_input(event: InputEvent) -> void:
	if is_testing():
		return
	var key: InputEventKey = event as InputEventKey
	if key != null and key.pressed and key.is_command_or_control_pressed():
		if key.keycode == KEY_Z and not key.shift_pressed:
			undo()
		elif key.keycode == KEY_Y or (key.keycode == KEY_Z and key.shift_pressed):
			redo()
		else:
			return
		get_viewport().set_input_as_handled()
		return
	if page != 0:
		return
	if key != null:
		var number: int = key.keycode - KEY_1                     # 1、2、3……換分類
		if key.pressed and not key.echo and number >= 0 and number < mini(categories.size(), 9):
			set_category(categories[number])
			get_viewport().set_input_as_handled()
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if button.ctrl_pressed and (button.button_index == MOUSE_BUTTON_WHEEL_UP or button.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			return                                                # Ctrl＋滾輪是鏡頭縮放
		if button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_UP:
			brush = minf(brush + brush_step, max_brush)
			say()
		elif button.pressed and button.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			brush = maxf(brush - brush_step, min_brush)
			say()
		elif button.button_index == MOUSE_BUTTON_LEFT or button.button_index == MOUSE_BUTTON_RIGHT:
			if button.pressed:
				press(mouse(), button.button_index == MOUSE_BUTTON_RIGHT)
			else:
				release(mouse())
		return
	if event is InputEventMouseMotion:
		if _painting:
			_stroke(mouse())
		else:
			_mouse_moved(mouse())


## 滑鼠在地圖裡的哪裡（像素座標）
func mouse() -> Vector2:
	return _overlay.get_local_mouse_position()


func cell_at(at: Vector2) -> Vector2i:
	return Vector2i((at / cell_size).floor())


func has_cell(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, map.get("size")).has_point(cell)


## 現在的工具是畫地形的嗎
func is_paint_tool() -> bool:
	return tools[tool]["paint"]


## 按下去（at＝地圖裡的像素座標）
func press(at: Vector2, erase: bool) -> void:
	_erasing = erase
	if not is_paint_tool():
		if erase:
			unplace(cell_at(at))
		else:
			place(cell_at(at))
		return
	match shape:
		Shape.BRUSH:
			remember()                                            # 一筆＝一步
			_painting = true
			_last_paint = at
			_paint_dab(at)
		Shape.RECT, Shape.ELLIPSE:
			_drag_from = at
		Shape.FILL:
			remember()
			if _paint_fill(at) == 0:
				_history.pop_back()                               # 什麼都沒換：這一步不算
				say("那一塊不用換")


## 放開
func release(at: Vector2) -> void:
	_painting = false
	if _drag_from == null:
		return
	var from: Vector2 = _drag_from
	_drag_from = null
	remember()
	if shape == Shape.RECT:
		_paint_rect(from, at)
	else:
		_paint_ellipse(from, at)


## 拖曳：每隔一小段畫一下，線才會連續
func _stroke(at: Vector2) -> void:
	var spacing: float = cell_size / 2.0 if snap else maxf(brush * 0.3, 2.0)
	var steps: int = ceili(_last_paint.distance_to(at) / spacing)
	for i: int in range(1, steps + 1):
		_paint_dab(_last_paint.lerp(at, float(i) / steps))
	if steps > 0:
		_last_paint = at


## 兩個位置圍起來的格子
func cells_between(a: Vector2, b: Vector2) -> Rect2i:
	var from: Vector2i = cell_at(a)
	var to: Vector2i = cell_at(b)
	return Rect2i(from.min(to), (from - to).abs() + Vector2i.ONE)


## 筆刷蓋到的格子（對齊格子時）
func brush_cells(at: Vector2) -> Rect2i:
	var count: int = maxi(roundi(brush * 2.0 / cell_size), 1)
	var corner: Vector2i = cell_at(at - Vector2.ONE * (count - 1) * cell_size / 2.0)
	return Rect2i(corner, Vector2i(count, count))


## 改地圖大小（格數）
func resize_map(to: Vector2i) -> void:
	to = to.clamp(min_size, max_size)
	if to == map.get("size"):
		return
	remember()
	map.call("resize", to)
	show_map()
	say("地圖大小 %d×%d 格" % [to.x, to.y])


func clear_terrain() -> void:
	remember()
	_clear()
	show_map()


func set_tool(to: int) -> void:
	tool = to
	var in_category: String = tools[to]["category"]
	if not in_category.is_empty():
		_category_tools[in_category] = to
		category = in_category
	elif category.is_empty() and not categories.is_empty():
		category = categories[0]
	_show_category()
	for i: int in _tool_buttons:
		_tool_buttons[i].button_pressed = i == to
	for button: Button in _shape_buttons.values():
		button.disabled = not is_paint_tool()                     # 放東西不用選形狀
	if _snap_button != null:
		_snap_button.disabled = not is_paint_tool()
	say()


## 換分類：用這個分類上次用的工具（沒用過＝第一個；一個都沒有＝不分類的那個，例如「選取」）
func set_category(to: String) -> void:
	category = to
	var found: int = _category_tools.get(to, -1)
	for i: int in tools.size():
		if found < 0 and tools[i]["category"] == to:
			found = i
	for i: int in tools.size():
		if found < 0 and (tools[i]["category"] as String).is_empty():
			found = i
	set_tool(found if found >= 0 else tool)


func _show_category() -> void:
	for text: String in _category_buttons:
		_category_buttons[text].button_pressed = text == category
	for part: Dictionary in _category_parts:
		(part["node"] as Control).visible = (part["categories"] as Array).has(category)


func set_shape(to: int) -> void:
	shape = to
	for i: int in _shape_buttons:
		_shape_buttons[i].button_pressed = i == to
	say()


# ---- 上一步、下一步 ----

## 改地圖之前呼叫：記住現在的樣子（下一步的紀錄清掉）
func remember() -> void:
	_history.append(map.call("snapshot"))
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	_future.clear()


## 上一步（Ctrl＋Z）：有自己上一步的頁（有 undo()）就叫那一頁的
func undo() -> bool:
	if _page_has("undo"):
		return _page_panel().call("undo")
	if _history.is_empty():
		say("沒有上一步了")
		return false
	_future.append(map.call("snapshot"))
	map.call("restore", _history.pop_back())
	show_map()
	say("上一步（還可以退 %d 步）" % _history.size())
	return true


## 下一步（Ctrl＋Y）
func redo() -> bool:
	if _page_has("redo"):
		return _page_panel().call("redo")
	if _future.is_empty():
		say("沒有下一步了")
		return false
	_history.append(map.call("snapshot"))
	map.call("restore", _future.pop_back())
	show_map()
	say("下一步")
	return true


func _process(delta: float) -> void:
	if is_testing():
		return
	_overlay.queue_redraw()                                       # 筆刷跟著滑鼠
	_check_time -= delta
	if _check_time <= 0.0:
		_check_time = 0.25
		update_save_buttons()


## 地圖有沒有東西還沒存
func is_dirty() -> bool:
	return _name_edit.text.strip_edges() != saved_name or map.call("snapshot") != saved_state


func _mark_saved() -> void:
	saved_state = map.call("snapshot")
	saved_name = map.get("map_name")


## 「存檔」：有東西沒存就變黃、多一個＊
func update_save_buttons() -> void:
	LevelEditorStyle.paint_save(_save_button, is_dirty())
	for item: Dictionary in pages:
		if item["panel"] != null and (item["panel"] as Object).has_method("update_save_button"):
			(item["panel"] as Object).call("update_save_button")


# ---- 畫 ----

func _draw_overlay() -> void:
	if is_testing():
		return
	if snap and page == 0 and is_paint_tool():                    # 對齊格子：畫出格子線
		var cells: Vector2i = map.get("size")
		for x: int in cells.x + 1:
			_overlay.draw_line(Vector2(x, 0) * cell_size, Vector2(x, cells.y) * cell_size, Color(0, 0, 0, 0.18))
		for y: int in cells.y + 1:
			_overlay.draw_line(Vector2(0, y) * cell_size, Vector2(cells.x, y) * cell_size, Color(0, 0, 0, 0.18))
	_draw_map(_overlay)
	if page == 0:
		_draw_cursor(mouse())


## 滑鼠：筆刷、拖曳中的形狀、要放的格子
func _draw_cursor(at: Vector2) -> void:
	var white: Color = Color(1, 1, 1, 0.8)
	if not is_paint_tool():
		if has_cell(cell_at(at)):
			_overlay.draw_rect(cells_rect(Rect2i(cell_at(at), Vector2i.ONE)), white, false, 2.0)
	elif shape == Shape.BRUSH:
		if snap:
			_overlay.draw_rect(cells_rect(brush_cells(at)), white, false, 2.0)
		else:
			_overlay.draw_arc(at, brush, 0.0, TAU, 48, white, 2.0)
	elif shape == Shape.FILL or _drag_from == null:
		_overlay.draw_line(at - Vector2(8, 0), at + Vector2(8, 0), white, 2.0)
		_overlay.draw_line(at - Vector2(0, 8), at + Vector2(0, 8), white, 2.0)
	else:
		var rect: Rect2 = cells_rect(cells_between(_drag_from, at)) if snap else Rect2(_drag_from, at - (_drag_from as Vector2)).abs()
		if shape == Shape.RECT:
			_overlay.draw_rect(rect, white, false, 2.0)
		else:
			var line: PackedVector2Array = PackedVector2Array()
			for i: int in 49:
				line.append(rect.get_center() + Vector2.from_angle(TAU * i / 48.0) * rect.size / 2.0)
			_overlay.draw_polyline(line, white, 2.0)


## 幾格在地圖裡的範圍（像素）
func cells_rect(cells: Rect2i) -> Rect2:
	return Rect2(cells.position * cell_size, cells.size * cell_size)


func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * cell_size


## 把畫面移到 rect（地圖裡的像素），放在 free（螢幕上沒被面板擋住的地方）中間，太大就縮小到看得完
func look_at_rect(rect: Rect2, free: Rect2, max_zoom: float) -> void:
	var fit: float = minf(free.size.x / rect.size.x, free.size.y / rect.size.y)
	var value: float = clampf(minf(max_zoom, fit), 0.2, 3.0)
	var to: Vector2 = origin + rect.get_center() - (free.get_center() - get_viewport_rect().size / 2.0) / value
	if _camera_tween != null:
		_camera_tween.kill()
	_camera_tween = create_tween().set_parallel()
	_camera_tween.tween_property(_camera, "global_position", to, 0.2).set_trans(Tween.TRANS_SINE)
	_camera_tween.tween_property(_camera, "zoom", Vector2(value, value), 0.2)


# ---- 換頁 ----

func set_page(to: int) -> void:
	commit_pages()
	page = to
	_painting = false
	_drag_from = null
	_map_tools.visible = page == 0
	for i: int in pages.size():
		_page_buttons[i].button_pressed = i == page
		if pages[i]["panel"] != null:
			(pages[i]["panel"] as Control).visible = i == page
	_save_button.visible = not pages[page]["own_save"]
	_camera.process_mode = Node.PROCESS_MODE_INHERIT if page == 0 and not is_testing() else Node.PROCESS_MODE_DISABLED
	if page == 0:
		if _camera_tween != null:
			_camera_tween.kill()
		_camera.clamp_to_limits()
	_page_shown(page)
	say(pages[page]["hint"])


## 打到一半的字先算數（存檔、試玩、換頁之前）：叫每一頁的 commit()
func commit_pages() -> void:
	for item: Dictionary in pages:
		if item["panel"] != null and (item["panel"] as Object).has_method("commit"):
			(item["panel"] as Object).call("commit")


func _page_panel() -> Control:
	return pages[page]["panel"]


func _page_has(method: String) -> bool:
	return _page_panel() != null and _page_panel().has_method(method)


# ---- 試玩 ----

## 正在試玩嗎
func is_testing() -> bool:
	return _play != null and is_instance_valid(_play)


## 按「▶ 試玩」：有東西沒存就先問，都存好了就直接開始。start＝怎麼開始
func request_test(start: Callable = start_test) -> void:
	commit_pages()
	if is_testing() or unsaved().is_empty() or not check_map().is_empty():
		start.call()
		return
	_test_start = start
	_ask.dialog_text = "還沒存檔：%s\n\n「不存」的話，地圖用現在改的，其他的用上次存的" % "、".join(unsaved())
	_ask.popup_centered()


## 哪些東西還沒存檔（名字）
func unsaved() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if is_dirty():
		result.append(pages[0]["name"])
	for item: Dictionary in pages:
		if _is_page_dirty(item):
			var scene_page: LevelEditorScenePage = item["panel"] as LevelEditorScenePage
			result.append(item["name"] if scene_page == null else "%s「%s」" % [item["name"], scene_page.data.get("display_name", "")])
	return result


func _is_page_dirty(item: Dictionary) -> bool:
	return item["own_save"] and item["panel"] != null and (item["panel"] as Object).has_method("is_dirty") and (item["panel"] as Object).call("is_dirty")


## 全部存檔。回傳都存好了沒
func save_all() -> bool:
	commit_pages()
	for item: Dictionary in pages:
		if _is_page_dirty(item):
			(item["panel"] as Object).call("save")
			if _is_page_dirty(item):
				return false                                      # 存不了（原因那一頁會說）
	return not is_dirty() or not save_map().is_empty()


func _save_and_test() -> void:
	if save_all():
		_test_start.call()


## 開始試玩：在編輯器裡放一個關卡（不換場景）
func start_test() -> bool:
	if is_testing():
		return false
	commit_pages()
	if not check_map().is_empty():
		say("不能試玩：" + check_map())
		resume_test = false
		return false
	map.set("map_name", _name_edit.text.strip_edges())            # 還沒存檔也記住名字
	_before_test()
	_play = play_scene.instantiate()
	_camera.enabled = false                                       # 關卡有自己的 Camera2D 就用它，沒有就是畫面左上角＝(0, 0)
	add_child(_play)
	resume_test = true                                            # 暫停選單按「重來」：重新載入後接著試玩
	GameFlow.set_title_button(back_text, stop_test)               # 暫停選單、勝敗畫面的「回標題」換成回來編輯
	_set_editing(false)
	return true


## 停止試玩：拿掉關卡，回到編輯
func stop_test() -> void:
	resume_test = false
	_after_test()
	GameFlow.reset_title_button()
	if is_testing():
		_play.queue_free()
	_play = null
	Engine.time_scale = 1.0
	get_tree().paused = false
	for child: Node in GameFlow.get_children():
		if child.scene_file_path.ends_with("result_screen.tscn"):
			child.queue_free()                                    # 試玩中贏了或輸了：關掉勝敗畫面
	_camera.enabled = true
	_camera.make_current()
	_set_editing(true)


func _set_editing(on: bool) -> void:
	GameFlow.set_pause_enabled(not on)
	_view.visible = on
	_overlay.visible = on
	_ui.visible = on
	_camera.process_mode = Node.PROCESS_MODE_INHERIT if on and page == 0 else Node.PROCESS_MODE_DISABLED
	_stop_button.visible = not on


# ---- 存檔、讀檔 ----

## 存檔。回傳存到哪裡（失敗＝空字串）
func save_map() -> String:
	commit_pages()
	var text: String = _name_edit.text.strip_edges()
	if text.is_empty():
		say("先打地圖名稱")
		return ""
	var trouble: String = check_map()
	if save_needs_ok and not trouble.is_empty():
		say("不能存檔：" + trouble)
		return ""
	map.set("map_name", text)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(maps_dir))
	var path: String = _path_of(text)
	var error: Error = _write(path)
	if error != OK:
		say("存檔失敗：%s（匯出的遊戲不能存，要在 Godot 編輯器裡按 F6）" % error_string(error))
		return ""
	_mark_saved()
	update_save_buttons()
	refresh_files()
	say("存好了：%s%s" % [path, "" if trouble.is_empty() else "（提醒：%s）" % trouble])
	return path


func load_map(path: String) -> bool:
	var loaded: Resource = _read(path)
	if loaded == null:
		say("讀不到：%s" % path)
		return false
	map = loaded
	_use_map()
	_load_list.select(0)                                          # 清單回到「讀檔…」，同一張也能再讀一次
	say("讀進來了：%s" % path)
	return true


func new_map() -> void:
	map = _new_map()
	_use_map()
	say("新地圖")


func _use_map() -> void:
	map.call("ensure")
	editing = map
	_mark_saved()
	_history.clear()
	_future.clear()
	show_map()


## 資料夾裡有哪些地圖
func map_files() -> PackedStringArray:
	var files: PackedStringArray = PackedStringArray()
	if not DirAccess.dir_exists_absolute(maps_dir):
		return files
	for file: String in DirAccess.get_files_at(maps_dir):
		if file.get_extension() == _path_of("x").get_extension():
			files.append(maps_dir + file)
	return files


func refresh_files() -> void:
	_load_list.clear()
	_load_list.add_item("讀檔…")
	_load_list.set_item_disabled(0, true)
	for path: String in map_files():
		_load_list.add_item(path.get_file().get_basename())
		_load_list.set_item_metadata(_load_list.item_count - 1, path)
	_load_list.select(0)


## 把存好的地圖做成一個關卡場景。回傳存到哪裡（失敗＝空字串）
func make_level() -> String:
	commit_pages()
	var map_path: String = _path_of(saved_name)
	if is_dirty() or not ResourceLoader.exists(map_path):
		say("地圖還沒存檔，先到「地圖」頁按存檔")
		return ""
	var request: Dictionary = _level_request(map_path)
	if request.is_empty():
		return ""
	var path: String = request["path"]
	var error: Error = LevelMaker.make(path, request["base"], request["values"])
	if error == ERR_ALREADY_EXISTS:
		say("已經有這一關了：%s（它會自動用最新存檔的，不用重做）" % path)
		return ""
	if error != OK:
		say("做不了：%s（匯出的遊戲不能存，要在 Godot 編輯器裡按 F6）" % error_string(error))
		return ""
	say("做好了：%s，拖進 game_config.tres 的 Levels 就能串關" % path.get_file())
	return path


# ---- 介面（做自己的編輯器時，這些都可以拿來用） ----

## 加一個工具。paint＝畫地形的（左鍵畫、右鍵擦、可以選形狀）；gap＝後面隔一條線；
## in_category＝放在哪個分類（用 add_category_rows() 的話；空的＝一直看得到）
func add_tool(text: String, paint: bool = false, gap: bool = false, in_category: String = "") -> void:
	tools.append({"name": text, "paint": paint, "gap": gap, "category": in_category})
	add_category(in_category)


## 加一個分類（還沒有工具的分類也可以先加）
func add_category(text: String) -> void:
	if not text.is_empty() and not categories.has(text):
		categories.append(text)


## 加一頁。panel＝那一頁的面板（地圖頁不用給）；hint＝換到這一頁時的提示；own_save＝那一頁有自己的存檔鈕。
## 面板有這些就會自動用到：say（顯示訊息的 Callable）、undo()、redo()、commit()（打到一半的字先算數）、update_save_button()
func add_page(text: String, panel: PanelContainer = null, area: Rect2 = Rect2(64, 48, 1196, 640), hint: String = "", own_save: bool = false) -> void:
	pages.append({"name": text, "panel": panel, "hint": PAINT_HINT if panel == null and hint.is_empty() else hint, "own_save": own_save})
	if panel != null:
		var scene_page: LevelEditorScenePage = panel as LevelEditorScenePage
		if scene_page != null:
			scene_page.used_in_editor = _used_in_editor
			scene_page.deleted.connect(_scene_deleted)
		add_panel(panel, area)
		panel.visible = false


## 加一頁「規則」：改 map 的這幾個 @export 欄位（中文名字讀上面那行 ## 註解），跟地圖一起存、可以上一步
func add_form_page(text: String, names: Array, hint: String = "跟地圖一起存") -> LevelEditorFormPage:
	var form: LevelEditorFormPage = LevelEditorFormPage.new()
	form.editor = self
	form.names = names
	add_page(text, form, Rect2(64, 48, 760, 520), hint)
	return form


## 加一個面板（parent 給 _map_tools 就只在地圖頁出現）
func add_panel(panel: PanelContainer, area: Rect2, parent: Node = _ui) -> void:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.16, 0.16, 0.18)
	style.set_corner_radius_all(6)
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	if "say" in panel:
		panel.set("say", say)
	parent.add_child(panel)
	panel.position = area.position
	panel.size = area.size


## 地圖頁的一排（y＝畫面的高度位置）
func add_row(y: float) -> HBoxContainer:
	return _row(Vector2(ui_left, y), _map_tools)


## 工具的按鈕。很多的話可以分好幾排：from＝從第幾個開始、count＝幾個（-1＝到最後）。再多就分類，用 add_category_rows()
func add_tool_buttons(row: Control, from: int = 0, count: int = -1) -> void:
	for i: int in range(from, tools.size() if count < 0 else from + count):
		_tool_buttons[i] = add_toggle(row, tools[i]["name"], set_tool.bind(i))
		if tools[i]["gap"]:
			row.add_child(VSeparator.new())
	row.add_child(VSeparator.new())


## 工具分類：第一排是不分類的工具和分類（按 1、2、3……切換），第二排只有這個分類的工具。
## 回傳第二排，要加這個分類自己的東西：add_category_box(那一排, ["分類"])
func add_category_rows(first_y: float = 592.0, second_y: float = 626.0) -> HBoxContainer:
	var first: HBoxContainer = add_row(first_y)
	var second: HBoxContainer = add_row(second_y)
	for i: int in tools.size():
		var in_category: String = tools[i]["category"]
		_tool_buttons[i] = add_toggle(first if in_category.is_empty() else second, tools[i]["name"], set_tool.bind(i))
		if not in_category.is_empty():
			_category_parts.append({"node": _tool_buttons[i], "categories": [in_category]})
	if first.get_child_count() > 0:
		first.add_child(VSeparator.new())
	for i: int in categories.size():
		_category_buttons[categories[i]] = add_toggle(first, "%d %s" % [i + 1, categories[i]], set_category.bind(categories[i]))
		_category_buttons[categories[i]].tooltip_text = "按 %d 切換" % (i + 1)
	second.add_child(VSeparator.new())
	return second


## 一格只在這些分類出現的地方（放形狀按鈕、下拉選單……）
func add_category_box(row: Control, in_categories: Array) -> HBoxContainer:
	var box: HBoxContainer = HBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	row.add_child(box)
	_category_parts.append({"node": box, "categories": in_categories})
	return box


## 畫筆、矩形、圓形、油漆桶；with_snap＝可以切換「對齊格子」；shapes＝只要這幾種（空的＝全部）
func add_shape_buttons(row: Control, with_snap: bool = false, shapes: Array = []) -> void:
	for i: int in SHAPE_NAMES.size():
		if shapes.is_empty() or shapes.has(i):
			_shape_buttons[i] = add_toggle(row, SHAPE_NAMES[i], set_shape.bind(i))
	if not with_snap:
		return
	_snap_button = add_toggle(row, "對齊格子", func() -> void:
		snap = _snap_button.button_pressed
		say("對齊格子：一格一格畫" if snap else "圓滑地畫"))
	_snap_button.button_pressed = snap
	_snap_button.tooltip_text = "打開：照格子畫，邊緣是直的。關掉：圓滑的。兩種可以畫在同一張地圖"


## 地圖名稱、讀檔、新地圖、清空；with_save＝存檔鈕放這裡（不然在最上面）
func add_file_controls(row: Control, with_save: bool = false) -> void:
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "地圖名稱"
	_name_edit.custom_minimum_size = Vector2(160, 0)
	row.add_child(_name_edit)
	if with_save:
		_add_save(row)
	_load_list = OptionButton.new()
	_load_list.custom_minimum_size = Vector2(160, 0)
	_load_list.item_selected.connect(func(index: int) -> void: load_map(_load_list.get_item_metadata(index)))
	row.add_child(_load_list)
	add_button(row, "新地圖", new_map)
	LevelEditorStyle.paint(add_button(row, "清空地形", clear_terrain), LevelEditorStyle.DANGER)


func add_size_boxes(row: Control) -> void:
	row.add_child(VSeparator.new())
	_width = _size_box(row, "寬", min_size.x, max_size.x)
	_height = _size_box(row, "高", min_size.y, max_size.y)


func _size_box(row: Control, text: String, from: int, to: int) -> SpinBox:
	add_label(row, text)
	var box: SpinBox = SpinBox.new()
	box.min_value = from
	box.max_value = to
	box.suffix = "格"
	box.custom_minimum_size = Vector2(96, 0)
	box.value_changed.connect(func(_value: float) -> void: resize_map(Vector2i(int(_width.value), int(_height.value))))
	row.add_child(box)
	return box


func add_label(parent: Control, text: String) -> Label:
	var label: Label = Label.new()
	label.text = text
	parent.add_child(label)
	return label


func add_button(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE                        # 不要搶鍵盤（打地圖名稱時才不會亂）
	button.pressed.connect(func() -> void: action.call())
	parent.add_child(button)
	return button


func add_toggle(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = add_button(parent, text, action)
	button.toggle_mode = true
	LevelEditorStyle.paint_toggle(button)
	return button


## 下面那行狀態：現在的工具、筆刷大小、最後一個訊息（不給文字＝只更新工具）
func say(text: String = "") -> void:
	if not text.is_empty():
		_status_text = text
	if _status == null:
		return
	if page != 0:
		_status.text = _status_text
		return
	var what: String = tools[tool]["name"]
	if is_paint_tool():
		what += "（%s）　｜　筆刷 %s" % [SHAPE_NAMES[shape], "%d 格" % brush_cells(Vector2.ZERO).size.x if grid_only else "%d px%s" % [int(brush), "（對齊格子）" if snap else ""]]
	_status.text = "%s　｜　%s" % [what, _status_text]


func _build_ui() -> void:
	_ui = CanvasLayer.new()
	_ui.name = "UI"
	add_child(_ui)
	_strip(Rect2(0, 0, 1280, 46), _ui)                            # 最上面、最下面兩條底色，字才看得清楚
	_strip(Rect2(0, 692, 1280, 28), _ui)
	_map_tools = Control.new()
	_map_tools.name = "MapTools"
	_map_tools.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_map_tools)
	_strip(Rect2(0, 586, 1280, 106), _map_tools)
	_build_rows()
	_build_pages()
	_status = Label.new()
	_status.position = Vector2(ui_left, 697)
	_status.add_theme_font_size_override("font_size", 14)
	_ui.add_child(_status)
	var row: HBoxContainer = _row(Vector2(64, 8), _ui)            # 最上面：標題、換頁、上一步、存檔、試玩
	var label: Label = add_label(row, title)
	label.add_theme_font_size_override("font_size", 22)
	label.custom_minimum_size = Vector2(130, 0)
	for i: int in pages.size():
		_page_buttons.append(add_toggle(row, pages[i]["name"], set_page.bind(i)))
	row.add_child(VSeparator.new())
	add_button(row, "↶", undo).tooltip_text = "上一步（Ctrl＋Z）"
	add_button(row, "↷", redo).tooltip_text = "下一步（Ctrl＋Y）"
	row.add_child(VSeparator.new())
	if _save_button == null:
		_add_save(row)
	LevelEditorStyle.paint(add_button(row, "▶ 試玩", request_test), LevelEditorStyle.PLAY)
	_build_top(row)
	_ask = ConfirmationDialog.new()
	_ask.title = "試玩之前"
	_ask.ok_button_text = "存檔並試玩"
	_ask.cancel_button_text = "取消"
	_ask.add_button("不存，直接試玩", true, "skip")
	_ask.confirmed.connect(_save_and_test)
	_ask.custom_action.connect(func(_action: StringName) -> void:
		_ask.hide()
		_test_start.call())
	_ui.add_child(_ask)
	# 試玩時才出現的「停止試玩」（另一層，編輯的介面藏起來時它還在）
	var top: CanvasLayer = CanvasLayer.new()
	top.layer = 25                                                # 在 HUD（20）上面、暫停選單（30）下面
	add_child(top)
	_stop_button = Button.new()
	_stop_button.name = "StopTest"
	_stop_button.text = "■ 停止試玩"
	_stop_button.focus_mode = Control.FOCUS_NONE
	_stop_button.position = stop_position
	_stop_button.visible = false
	_stop_button.pressed.connect(stop_test)
	LevelEditorStyle.paint(_stop_button, LevelEditorStyle.DANGER)
	top.add_child(_stop_button)


func _add_save(row: Control) -> void:
	_save_button = add_button(row, "存檔", save_map)
	LevelEditorStyle.paint_save(_save_button, false)


func _row(at: Vector2, parent: Node) -> HBoxContainer:
	var row: HBoxContainer = HBoxContainer.new()
	row.position = at
	row.add_theme_constant_override("separation", 6)
	parent.add_child(row)
	return row


func _strip(area: Rect2, parent: Node) -> void:
	var background: ColorRect = ColorRect.new()
	background.color = Color(0.13, 0.13, 0.15, 0.96)
	background.position = area.position
	background.size = area.size
	parent.add_child(background)
