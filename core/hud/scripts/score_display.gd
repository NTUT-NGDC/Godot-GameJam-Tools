class_name ScoreDisplay
extends Label
## 分數：拖進畫面（放在 CanvasLayer 底下），程式裡呼叫 add(10) 就會加分。
## 找它：get_tree().get_first_node_in_group("score")，或在檢查器把別的 signal 連到 add。

## 分數變了
signal score_changed(score: int)

## 分數前面的字
@export var prefix: String = "分數 "
## 一開始的分數
@export var score: int = 0:
	set(value):
		score = value
		_refresh()


func _enter_tree() -> void:
	add_to_group("score")


func _ready() -> void:
	_refresh()


## 加分（負的就是扣分）
func add(amount: int = 1) -> void:
	score += amount
	score_changed.emit(score)


func _refresh() -> void:
	text = "%s%d" % [prefix, score]
