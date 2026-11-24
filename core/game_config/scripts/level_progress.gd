class_name LevelProgress
extends RefCounted
## 過關進度：記住哪些關卡過了（存在 user://，關掉重開還在，網頁版也是）。
## 關卡清單在 game_config.tres 的 Levels。贏了（GameFlow.win()）會自動記，不用自己呼叫。
##
##   LevelProgress.is_cleared("res://levels/level_1.tscn")
##   LevelProgress.is_unlocked(2)          第 3 關能不能玩（從 0 開始數）
##   LevelProgress.clear()                 清除進度

## 存在哪（測試會換掉）
static var save_path: String = "user://level_progress.json"

static var _cleared: PackedStringArray = PackedStringArray()
## 讀過的是哪一個檔案（換了檔案就重讀）
static var _loaded_path: String = ""


## 這個關卡過了沒
static func is_cleared(scene_path: String) -> bool:
	_load()
	return _cleared.has(scene_path)


## 記住這個關卡過了（不在關卡清單裡的不記）
static func mark_cleared(scene_path: String) -> void:
	_load()
	if GameConfig.current().level_index(scene_path) < 0 or _cleared.has(scene_path):
		return
	_cleared.append(scene_path)
	_save()


## 第幾關能不能玩（從 0 開始數）：第一關一定可以；「照順序解鎖」打勾的話，前一關過了才可以
static func is_unlocked(index: int) -> bool:
	var config: GameConfig = GameConfig.current()
	var levels: PackedStringArray = config.level_paths()
	if index < 0 or index >= levels.size():
		return false
	return index == 0 or not config.unlock_in_order or is_cleared(levels[index - 1]) or is_cleared(levels[index])


## 清除進度
static func clear() -> void:
	_loaded_path = save_path
	_cleared.clear()
	_save()


static func _load() -> void:
	if _loaded_path == save_path:
		return
	_loaded_path = save_path
	_cleared.clear()
	if not FileAccess.file_exists(save_path):
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	if data is Array:                                             # 檔案壞了就當作沒有進度，不會當掉
		for path: Variant in data:
			_cleared.append(str(path))


static func _save() -> void:
	var file: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		push_warning("[LevelProgress] 進度存不了：%s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(Array(_cleared)))
