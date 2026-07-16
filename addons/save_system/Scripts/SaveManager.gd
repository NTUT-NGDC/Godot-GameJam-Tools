extends Node
## 存檔資料夾（user:// 會對應到各平台的使用者資料目錄）
const SAVE_DIR := "user://saves/"
const SAVE_EXT := ".json"

## 自動存檔間隔（秒），0 表示不啟用自動存檔
@export var autosave_interval: float = 0.0

var _autosave_timer: Timer
var _current_slot: int = 0


func _ready() -> void:
	_ensure_save_dir()
	if autosave_interval > 0.0:
		_setup_autosave()


func _ensure_save_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func _get_save_path(slot: int) -> String:
	return "%s/slot_%d%s" % [SAVE_DIR, slot, SAVE_EXT]


## 存檔：把 Dictionary 寫入指定槽位
## 回傳 true 表示成功，false 表示失敗
func save(data: Dictionary, slot: int = 0) -> bool:
	var path := _get_save_path(slot)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: 無法開啟存檔檔案寫入 -> %s (錯誤碼: %s)" % [path, FileAccess.get_open_error()])
		return false

	var json_string := JSON.stringify(data, "\t")
	file.store_string(json_string)
	file.close()
	return true


## 讀檔：讀取指定槽位的資料
## 如果存檔不存在或損毀，回傳空 Dictionary，不會讓遊戲當掉
func load(slot: int = 0) -> Dictionary:
	var path := _get_save_path(slot)

	if not FileAccess.file_exists(path):
		push_warning("SaveManager: 找不到存檔 -> %s，回傳空資料" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("SaveManager: 無法開啟存檔檔案讀取 -> %s" % path)
		return {}

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: 存檔內容格式錯誤或已損毀 -> %s" % path)
		return {}

	return parsed


## 刪除指定槽位的存檔
## 回傳 true 表示成功刪除，false 表示檔案本來就不存在或刪除失敗
func delete_save(slot: int = 0) -> bool:
	var path := _get_save_path(slot)

	if not FileAccess.file_exists(path):
		push_warning("SaveManager: 嘗試刪除不存在的存檔 -> %s" % path)
		return false

	var err := DirAccess.remove_absolute(path)
	if err != OK:
		push_error("SaveManager: 刪除存檔失敗 -> %s (錯誤碼: %s)" % [path, err])
		return false

	return true


## 檢查指定槽位是否有存檔
func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(_get_save_path(slot))


## 取得所有存在的存檔槽位編號（用於顯示存檔列表 UI）
func get_all_save_slots(max_slots: int = 10) -> Array[int]:
	var slots: Array[int] = []
	for i in range(max_slots):
		if has_save(i):
			slots.append(i)
	return slots


# ---------------------------
# 自動存檔（選用功能）
# ---------------------------

## 設定要自動存檔的資料來源函式，遊戲需要自行提供一個
## 「回傳目前要存的資料」的 Callable，例如：
##   SaveManager.set_autosave_source(func(): return {"score": score, "hp": hp})
var _autosave_data_source: Callable = Callable()


func set_autosave_source(data_source: Callable, slot: int = 0) -> void:
	_autosave_data_source = data_source
	_current_slot = slot


func _setup_autosave() -> void:
	_autosave_timer = Timer.new()
	_autosave_timer.wait_time = autosave_interval
	_autosave_timer.autostart = true
	_autosave_timer.timeout.connect(_on_autosave_timeout)
	add_child(_autosave_timer)


func _on_autosave_timeout() -> void:
	if _autosave_data_source.is_valid():
		var data: Dictionary = _autosave_data_source.call()
		save(data, _current_slot)
		print("SaveManager: 自動存檔完成 (slot %d)" % _current_slot)
