@tool
class_name PanCamera
extends Camera2D
## 可以移動、縮放的鏡頭（策略、塔防、經營遊戲用）：
##   ・鍵盤：WASD／方向鍵移動（打字的時候不會動）
##   ・滑鼠：移到畫面邊緣移動、按住中鍵拖曳
##   ・滾輪縮放（可以設成要按住 Ctrl／Shift 才縮放），往滑鼠指的地方放大
##   ・可以設一個長方形邊界：鏡頭不會看到外面，縮小也不會超過邊界
##
## 用法：把 core/camera/pan_camera.tscn 拖進關卡（一個關卡放一個），擺在一開始要看的地方。
## 跟著玩家走的鏡頭用 follow_camera.tscn。

@export_group("移動")
## 用 WASD／方向鍵移動
@export var keyboard_pan: bool = true
## 移動速度（畫面上每秒幾像素，縮放後感覺一樣快）
@export_range(50, 3000, 10, "suffix:px/s") var pan_speed: float = 700.0
## 滑鼠移到畫面邊緣就移動
@export var edge_scroll: bool = true
## 離邊緣幾像素以內算「在邊緣」
@export_range(1, 100, 1, "suffix:px") var edge_margin: int = 12
## 按住滑鼠中鍵拖曳移動
@export var middle_drag: bool = true

@export_group("縮放")
## 用滾輪縮放
@export var wheel_zoom: bool = true
## 滾輪要按住哪個鍵才縮放（其他時候滾輪可以給別的功能用，例如調筆刷大小）
@export_enum("不用按", "Ctrl", "Shift") var zoom_modifier: int = 0
## 最多縮小到幾倍（0.5＝看得到兩倍大的範圍）
@export_range(0.1, 1.0, 0.05) var min_zoom: float = 0.5
## 最多放大到幾倍
@export_range(1.0, 8.0, 0.1) var max_zoom: float = 3.0
## 滾一格縮放多少
@export_range(1.01, 2.0, 0.01) var zoom_step: float = 1.15

@export_group("邊界")
## 打勾：鏡頭不會看到下面的長方形外面
@export var use_limits: bool = false:
	set(value):
		use_limits = value
		queue_redraw()
## 長方形的寬、高（像素）
@export var limit_size: Vector2 = Vector2(1280, 720):
	set(value):
		limit_size = value.max(Vector2.ZERO)
		queue_redraw()
## 長方形的中心離這個節點多遠（像素）
@export var limit_offset: Vector2 = Vector2.ZERO:
	set(value):
		limit_offset = value
		queue_redraw()
## 編輯器裡框的顏色（遊戲中不會顯示）
@export var limit_color: Color = Color(0.4, 0.8, 1.0, 0.9):
	set(value):
		limit_color = value
		queue_redraw()

## 邊界的範圍（全域座標）。遊戲開始時照節點的位置算一次；地圖大小變了用 set_limit_rect() 改
var limit_rect: Rect2 = Rect2()

var _dragging: bool = false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	add_to_group("pan_camera")
	limit_rect = Rect2(global_position + limit_offset - limit_size / 2.0, limit_size)
	make_current()
	clamp_to_limits()


## 換邊界（全域座標），例如讀了一張不一樣大的地圖
func set_limit_rect(rect: Rect2) -> void:
	use_limits = true
	limit_rect = rect
	clamp_to_limits()


## 移動鏡頭（世界座標的位移）
func move_by(offset: Vector2) -> void:
	global_position += offset
	clamp_to_limits()


## 縮放：factor > 1 放大；screen_point 是畫面上不動的那一點（通常是滑鼠）
func zoom_by(factor: float, screen_point: Vector2) -> void:
	var before: Vector2 = screen_to_world(screen_point)
	var value: float = clampf(zoom.x * factor, _min_zoom_now(), max_zoom)
	zoom = Vector2(value, value)
	global_position += before - screen_to_world(screen_point)     # 滑鼠指的地方留在原位
	clamp_to_limits()


## 畫面座標 → 世界座標
func screen_to_world(screen_point: Vector2) -> Vector2:
	var view: Vector2 = get_viewport_rect().size
	return global_position + offset + (screen_point - view / 2.0) / zoom   # 不用 get_screen_center_position()：它下一幀才更新


## 不要看到邊界外面：邊界比畫面小的那一邊就置中
func clamp_to_limits() -> void:
	if not use_limits or limit_rect.size == Vector2.ZERO:
		return
	var value: float = maxf(zoom.x, _min_zoom_now())
	zoom = Vector2(value, value)
	var half: Vector2 = get_viewport_rect().size / zoom / 2.0
	var center: Vector2 = global_position
	for axis: int in 2:
		if limit_rect.size[axis] <= half[axis] * 2.0:
			center[axis] = limit_rect.get_center()[axis]
		else:
			center[axis] = clampf(center[axis], limit_rect.position[axis] + half[axis], limit_rect.end[axis] - half[axis])
	global_position = center


## 有邊界時，最多縮小到剛好整個邊界放進畫面（地圖比例跟畫面不一樣時，另一邊會留空、置中）
func _min_zoom_now() -> float:
	if not use_limits or limit_rect.size == Vector2.ZERO:
		return min_zoom
	var view: Vector2 = get_viewport_rect().size
	var fit: float = minf(view.x / limit_rect.size.x, view.y / limit_rect.size.y)
	return minf(maxf(min_zoom, fit), max_zoom)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var direction: Vector2 = Vector2.ZERO
	if keyboard_pan and not _typing():
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if edge_scroll and direction == Vector2.ZERO and not _dragging:
		direction = _edge_direction()
	if direction != Vector2.ZERO:
		move_by(direction * pan_speed * delta / zoom.x)


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null:
		if wheel_zoom and button.pressed and _modifier_ok(button) and \
				(button.button_index == MOUSE_BUTTON_WHEEL_UP or button.button_index == MOUSE_BUTTON_WHEEL_DOWN):
			zoom_by(zoom_step if button.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / zoom_step, button.position)
			get_viewport().set_input_as_handled()
		elif middle_drag and button.button_index == MOUSE_BUTTON_MIDDLE:
			_dragging = button.pressed
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _dragging:
		move_by(-motion.relative / zoom)


func _modifier_ok(event: InputEventWithModifiers) -> bool:
	match zoom_modifier:
		1: return event.ctrl_pressed
		2: return event.shift_pressed
	return not event.ctrl_pressed and not event.shift_pressed


## 滑鼠在畫面邊緣的方向（不在邊緣就是 0）
func _edge_direction() -> Vector2:
	if not get_window().has_focus():
		return Vector2.ZERO
	var view: Vector2 = get_viewport_rect().size
	var mouse: Vector2 = get_viewport().get_mouse_position()
	if mouse.x < 0 or mouse.y < 0 or mouse.x > view.x or mouse.y > view.y:
		return Vector2.ZERO                                       # 滑鼠在視窗外面
	var direction: Vector2 = Vector2.ZERO
	if mouse.x <= edge_margin: direction.x = -1
	elif mouse.x >= view.x - edge_margin: direction.x = 1
	if mouse.y <= edge_margin: direction.y = -1
	elif mouse.y >= view.y - edge_margin: direction.y = 1
	return direction


## 正在輸入框裡打字：鍵盤不要移動鏡頭
func _typing() -> bool:
	var focus: Control = get_viewport().gui_get_focus_owner()
	return focus is LineEdit or focus is TextEdit


func _draw() -> void:
	if not Engine.is_editor_hint() or not use_limits:
		return
	var rect: Rect2 = Rect2(limit_offset - limit_size / 2.0, limit_size)
	draw_rect(rect, limit_color, false, 3.0)
