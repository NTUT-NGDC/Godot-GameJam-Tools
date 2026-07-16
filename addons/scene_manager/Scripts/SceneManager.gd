extends Node
## SceneManager - 統一處理遊戲場景（關卡）之間的切換,避免每個人各寫一套轉場邏輯。
##
## 用法：
##   SceneManager.change_scene("res://scenes/level_2.tscn")
##   SceneManager.change_scene("res://scenes/level_2.tscn", 0.6, true)  # 大場景用 Loading 畫面
##   SceneManager.change_scene_by_index(1)  # 用 scene_list 的索引切換,不用每次打完整路徑

## 場景切換時的轉場效果
enum TransitionType {
	FADE,    ## 淡入淡出黑幕(預設)
	INSTANT, ## 直接切換,不做任何轉場效果
}

@export var default_fade_time: float = 0.4
@export var fade_color: Color = Color.BLACK

## 場景清單,在 Inspector 依序拖入場景,之後就能用索引(數字)呼叫 change_scene_by_index()、
## 不用每次都打完整的 res:// 路徑。順序自行決定,例如 0 = 主選單、1 = 第一關...
@export_file("*.tscn") var scene_list: Array[String] = []

## 切換開始/結束時發出,可用來讓遊戲畫面做額外處理(例如暫停玩家輸入)
signal scene_change_started(scene_path: String)
signal scene_change_finished(scene_path: String)
## 只有 use_loading_screen = true 時才會發送,進度為 0.0 ~ 1.0
signal loading_progress_updated(progress: float)

@onready var _fade_rect: ColorRect = $TransitionLayer/FadeRect
@onready var _loading_ui: Control = $TransitionLayer/LoadingUI
@onready var _progress_bar: ProgressBar = $TransitionLayer/LoadingUI/VBoxContainer/ProgressBar

## 切換中的旗標,是驗收標準「連續快速觸發不會導致跳轉錯誤」的關鍵防呆
var _is_transitioning := false


func _ready() -> void:
	# 轉場不應該受遊戲暫停影響(例如切到暫停選單時的場景切換)
	process_mode = Node.PROCESS_MODE_ALWAYS

	_fade_rect.color = fade_color
	_fade_rect.color.a = 0.0
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_loading_ui.visible = false


## 是否正在切換場景中,UI 可以用這個來擋按鈕、顯示轉場圖示等
func is_transitioning() -> bool:
	return _is_transitioning


## 用 scene_list 裡的索引切換場景,參數跟 change_scene() 一樣,只是用數字代替路徑。
## 例如 scene_list = ["res://main_menu.tscn", "res://level_1.tscn"] 時,
## change_scene_by_index(1) 等同 change_scene("res://level_1.tscn")
func change_scene_by_index(index: int, fade_time: float = -1.0, use_loading_screen: bool = false, transition: TransitionType = TransitionType.FADE) -> void:
	if index < 0 or index >= scene_list.size():
		push_error("[SceneManager] scene_list 索引超出範圍: %d(清單共有 %d 個場景)" % [index, scene_list.size()])
		return
	change_scene(scene_list[index], fade_time, use_loading_screen, transition)


## 切換場景的唯一入口。
## scene_path:目標場景的資源路徑,例如 "res://scenes/level_2.tscn"
## fade_time:淡入淡出秒數,< 0 表示使用 default_fade_time
## use_loading_screen:場景較大時開啟,切換中會用 ResourceLoader 非同步載入並顯示 Loading 畫面 + 進度條
## transition:轉場效果,預設 FADE(黑幕淡入淡出),也可選 INSTANT(直接切換)
func change_scene(scene_path: String, fade_time: float = -1.0, use_loading_screen: bool = false, transition: TransitionType = TransitionType.FADE) -> void:
	if _is_transitioning:
		push_warning("[SceneManager] 場景切換中,忽略這次的 change_scene('%s') 呼叫" % scene_path)
		return

	if not ResourceLoader.exists(scene_path):
		push_error("[SceneManager] 找不到場景檔案: %s" % scene_path)
		return

	_is_transitioning = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP  # 轉場期間擋住所有點擊,避免玩家連續觸發
	scene_change_started.emit(scene_path)

	if transition == TransitionType.FADE:
		await _fade(0.0, 1.0, fade_time)

	var packed_scene: PackedScene = null
	if use_loading_screen:
		_loading_ui.visible = true
		packed_scene = await _load_scene_threaded(scene_path)
		_loading_ui.visible = false
	else:
		packed_scene = load(scene_path)

	if packed_scene == null:
		push_error("[SceneManager] 場景載入失敗,取消切換: %s" % scene_path)
		if transition == TransitionType.FADE:
			await _fade(1.0, 0.0, fade_time)
		_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_is_transitioning = false
		return

	get_tree().change_scene_to_packed(packed_scene)
	await get_tree().process_frame  # 等新場景的 _ready() 跑完,避免淡出時看到空白畫面

	if transition == TransitionType.FADE:
		await _fade(1.0, 0.0, fade_time)

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	scene_change_finished.emit(scene_path)


# =========================================================
# 內部工具:黑幕淡入淡出
# =========================================================
func _fade(from_alpha: float, to_alpha: float, fade_time: float) -> void:
	var duration := default_fade_time if fade_time < 0.0 else fade_time
	_fade_rect.color.a = from_alpha
	if duration <= 0.0:
		_fade_rect.color.a = to_alpha
		return

	var tween := create_tween()
	tween.tween_property(_fade_rect, "color:a", to_alpha, duration)
	await tween.finished


# =========================================================
# 內部工具:Loading 畫面(選用功能,大場景用非同步載入)
# =========================================================
func _load_scene_threaded(scene_path: String) -> PackedScene:
	var err := ResourceLoader.load_threaded_request(scene_path)
	if err != OK:
		push_error("[SceneManager] load_threaded_request 失敗(錯誤碼 %s): %s" % [err, scene_path])
		return null

	while true:
		var progress_arr: Array = []
		var status := ResourceLoader.load_threaded_get_status(scene_path, progress_arr)
		match status:
			ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				var progress: float = progress_arr[0] if progress_arr.size() > 0 else 0.0
				loading_progress_updated.emit(progress)
				if _progress_bar:
					_progress_bar.value = progress * 100.0
				await get_tree().process_frame
			ResourceLoader.THREAD_LOAD_LOADED:
				loading_progress_updated.emit(1.0)
				if _progress_bar:
					_progress_bar.value = 100.0
				return ResourceLoader.load_threaded_get(scene_path)
			_:
				push_error("[SceneManager] 場景非同步載入失敗: %s" % scene_path)
				return null

	return null
