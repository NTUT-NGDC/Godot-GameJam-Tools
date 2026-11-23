@tool
class_name FollowCamera
extends Camera2D
## 鏡頭：跟著玩家走，或固定在一個位置；可以設一個長方形邊界，鏡頭不會看到外面。
##
## 用法：把 core/camera/follow_camera.tscn 拖進關卡（一個關卡放一個）。
##   ・「跟隨」打勾：鏡頭跟著「跟隨對象」走（空著就自動找 player 群組）
##   ・「跟隨」不打勾：鏡頭固定在這個節點的位置，把它拖到想看的地方
##   ・「使用邊界」打勾：調「邊界大小」「邊界偏移」，編輯器裡的框就是鏡頭最多看得到的範圍
## 想放大縮小畫面：改下面 Camera2D 原本的 Zoom（2 = 放大兩倍）。

@export_group("跟隨")
## 打勾：鏡頭跟著跟隨對象走。不打勾：鏡頭固定在這個節點擺的位置
@export var follow: bool = true
## 要跟著誰。空著的話自動找「跟隨群組」裡的第一個節點
@export var target: Node2D
## 跟隨對象空著時，去這個群組找
@export var target_group: String = "player"
## 跟得多緊：越大越緊，0＝完全不延遲
@export_range(0.0, 20.0, 0.5) var smoothing: float = 8.0

@export_group("邊界")
## 打勾：鏡頭不會超出下面的長方形（看不到地圖外面的空白）
@export var use_limits: bool = false:
	set(value):
		use_limits = value
		queue_redraw()
## 長方形的寬、高（像素）。1280×720 剛好是一個畫面
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
@export var limit_color: Color = Color(1.0, 0.8, 0.2, 0.9):
	set(value):
		limit_color = value
		queue_redraw()

## 邊界的範圍（全域座標）。遊戲開始時照節點的位置算一次，之後鏡頭移動也不會跟著跑
var limit_rect: Rect2 = Rect2()


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	limit_rect = Rect2(global_position + limit_offset - limit_size / 2.0, limit_size)
	apply_limits()
	position_smoothing_enabled = smoothing > 0.0
	position_smoothing_speed = smoothing
	make_current()
	_follow_now()
	reset_smoothing()                                             # 一開始直接在玩家身上，不要從遠處滑過來


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_follow_now()


## 把邊界套到 Camera2D 的 limit 上（改了 use_limits／limit_rect 之後呼叫）
func apply_limits() -> void:
	limit_enabled = use_limits
	if not use_limits:
		return
	limit_left = floori(limit_rect.position.x)
	limit_top = floori(limit_rect.position.y)
	limit_right = ceili(limit_rect.end.x)
	limit_bottom = ceili(limit_rect.end.y)


func _follow_now() -> void:
	if not follow:
		return
	if target == null or not is_instance_valid(target):
		target = get_tree().get_first_node_in_group(target_group) as Node2D
		if target == null:
			return
	global_position = target.global_position


func _draw() -> void:
	if not Engine.is_editor_hint() or not use_limits:
		return
	var rect: Rect2 = Rect2(limit_offset - limit_size / 2.0, limit_size)
	draw_rect(rect, limit_color, false, 3.0)
	draw_line(rect.position, rect.position + Vector2(24, 0), limit_color, 6.0)
	draw_line(rect.position, rect.position + Vector2(0, 24), limit_color, 6.0)
