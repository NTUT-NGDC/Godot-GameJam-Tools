class_name GameConfig
extends Resource
## 遊戲設定檔：遊戲名稱、開始場景、Credits 名單都在這裡。
## 實際的設定在專案最上層的 game_config.tres，雙擊它就能在檢查器改。
## 標題畫面、Credits 會自動讀這份設定，改了就跟著變。
##
## 程式裡要讀設定：GameConfig.current().game_name

## 設定檔放在哪（專案最上層，大家一打開就看得到）
const PATH: String = "res://game_config.tres"
## 起手包的標題畫面
const TITLE_SCENE: String = "res://core/screens/title_screen.tscn"

## 遊戲名稱：標題畫面最上面的大字
@export var game_name: String = "我們的遊戲"
## 標題畫面遊戲名稱底下的一句話（例如「經典玩法＋一個變化」）
@export var tagline: String = ""
## 按「開始遊戲」要進去的場景（通常是 levels/ 裡的主場景）
@export_file("*.tscn") var start_scene: String = ""
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


## Credits 名單拆成一行一行（去掉前後空白，保留空白行當間隔）
func credit_lines() -> PackedStringArray:
	var lines: PackedStringArray = []
	for line: String in credits.split("\n"):
		lines.append(line.strip_edges())
	while not lines.is_empty() and lines[lines.size() - 1] == "":
		lines.remove_at(lines.size() - 1)
	return lines
