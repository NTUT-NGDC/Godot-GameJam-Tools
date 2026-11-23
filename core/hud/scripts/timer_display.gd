class_name TimerDisplay
extends Label
## 計時：正數（過了多久）或倒數（剩多久，到 0 發出 time_up）。遊戲暫停時也會停。
## 倒數到 0 想直接輸：在檢查器把 time_up 連到 GameFlow 的 lose，或打勾「時間到就輸」。

## 倒數到 0 了
signal time_up()

## 正數：顯示過了多久；倒數：從「倒數秒數」數到 0
@export_enum("正數", "倒數") var mode: int = 0
## 倒數模式從幾秒開始數
@export_range(1, 3600, 1, "suffix:秒") var countdown_seconds: float = 60.0
## 時間到就呼叫 GameFlow.lose()
@export var lose_when_time_up: bool = false
## 時間到時就贏（例如「撐過 60 秒」），跟上面二選一
@export var win_when_time_up: bool = false
## 字前面的文字
@export var prefix: String = "時間 "

## 正數：過了幾秒；倒數：剩幾秒
var seconds: float = 0.0
## 正在計時嗎（可以呼叫 stop()／start()）
var running: bool = true


func _ready() -> void:
	seconds = countdown_seconds if mode == 1 else 0.0
	_refresh()


func _process(delta: float) -> void:
	if not running:
		return
	if mode == 0:
		seconds += delta
	else:
		seconds = maxf(seconds - delta, 0.0)
		if seconds <= 0.0:
			running = false
			time_up.emit()
			if lose_when_time_up:
				GameFlow.lose("時間到了！")
			elif win_when_time_up:
				GameFlow.win("撐過去了！")
	_refresh()


func start() -> void:
	running = true


func stop() -> void:
	running = false


## 秒數 → 「1:05」
static func format(value: float) -> String:
	var total: int = ceili(value) if value > 0.0 else 0
	return "%d:%02d" % [floori(total / 60.0), total % 60]


func _refresh() -> void:
	text = prefix + format(seconds)
