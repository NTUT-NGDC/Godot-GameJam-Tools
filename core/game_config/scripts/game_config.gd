class_name GameConfig
extends Resource
## 遊戲設定檔：遊戲名稱、關卡、Credits 名單都在這裡。
## 實際的設定在專案最上層的 game_config.tres，雙擊它就能在檢查器改。
## 標題畫面、Credits 會自動讀這份設定，改了就跟著變。
##
## 程式裡要讀設定：GameConfig.current().game_name

## 設定檔放在哪（專案最上層，大家一打開就看得到）
const PATH: String = "res://game_config.tres"
## 起手包的標題畫面
const TITLE_SCENE: String = "res://core/screens/title_screen.tscn"
## 起手包的關卡選擇畫面
const LEVEL_SELECT_SCENE: String = "res://core/screens/level_select_screen.tscn"

## 遊戲名稱：標題畫面最上面的大字
@export var game_name: String = "我們的遊戲"
## 標題畫面遊戲名稱底下的一句話（例如「經典玩法＋一個變化」）
@export var tagline: String = ""
## 關卡：一格拖一個關卡場景，順序就是關卡順序（通常是 levels/ 裡的場景）。
## 只有一關：「開始遊戲」直接進去。兩關以上：先進關卡選擇畫面，勝利畫面會有「下一關」
@export_file("*.tscn") var levels: Array[String] = []
## 關卡名字：一行一個，跟上面的順序一樣（沒寫的就叫「第 1 關」「第 2 關」……）
@export_multiline var level_names: String = ""
## 照順序解鎖：過了前一關才能玩下一關（測試時可以先取消打勾）
@export var unlock_in_order: bool = true
## Credits 名單：一行一個，格式「職位：名字」，例如「程式：小明」。
## 空白行會留成間隔；離開的人名字也留著
@export_multiline var credits: String = ""

static var _cached: GameConfig


## 讀目前的設定（找不到設定檔就用預設值，不會當掉）
static func current() -> GameConfig:
	if _cached == null:
		_cached = load(PATH) as GameConfig if ResourceLoader.exists(PATH) else null
		if _cached == null:
			push_warning("[GameConfig] 找不到 %s，先用預設值。" % PATH)
			_cached = GameConfig.new()
	return _cached


## 關卡場景的路徑（空的、找不到的跳過）
func level_paths() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for index: int in _valid_levels():
		result.append(_to_path(levels[index]))
	return result


## 第幾關的名字（從 0 開始數）
func level_name(index: int) -> String:
	var valid: Array[int] = _valid_levels()
	if index < 0 or index >= valid.size():
		return ""
	var names: PackedStringArray = level_names.split("\n")
	var text: String = names[valid[index]].strip_edges() if valid[index] < names.size() else ""
	return text if not text.is_empty() else "第 %d 關" % (index + 1)


## 這個場景是第幾關（從 0 開始數；不在清單裡＝-1）
func level_index(scene_path: String) -> int:
	return level_paths().find(scene_path)


## 下一關的場景（沒有下一關、不在清單裡＝空字串）
func next_level(scene_path: String) -> String:
	var paths: PackedStringArray = level_paths()
	var index: int = paths.find(scene_path)
	return paths[index + 1] if index >= 0 and index + 1 < paths.size() else ""


## 要不要有關卡選擇畫面（兩關以上）
func has_level_select() -> bool:
	return _valid_levels().size() >= 2


## 清單裡第幾格是有效的
func _valid_levels() -> Array[int]:
	var result: Array[int] = []
	for i: int in levels.size():
		if not levels[i].is_empty() and ResourceLoader.exists(levels[i]):
			result.append(i)
	return result


## 檢查器選的檔案可能存成 uid://，換回一般的路徑才能比對
func _to_path(file: String) -> String:
	return ResourceUID.uid_to_path(file) if file.begins_with("uid://") else file


## Credits 名單拆成一行一行（去掉前後空白，保留空白行當間隔）
func credit_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	for line: String in credits.split("\n"):
		lines.append(line.strip_edges())
	while not lines.is_empty() and lines[lines.size() - 1] == "":
		lines.remove_at(lines.size() - 1)
	return lines
