class_name HealthBar
extends ProgressBar
## 血條：damage(10) 扣血、heal(10) 補血，扣到 0 發出 died。
## 可以放在畫面上（CanvasLayer 底下）當玩家血條，也可以放在角色底下當頭上的小血條。
## 扣到 0 想直接輸：打勾「死掉就輸」，或在檢查器把 died 連到 GameFlow 的 lose。

## 血量變了
signal health_changed(health: float)
## 扣到 0 了
signal died()

## 最多幾滴血
@export_range(1, 10000, 1) var max_health: float = 100.0
## 扣到 0 就呼叫 GameFlow.lose()
@export var lose_when_dead: bool = false
## 血量高時的顏色
@export var full_color: Color = Color("4ab86a")
## 血量低時的顏色
@export var low_color: Color = Color("d94a4a")

## 現在幾滴血
var health: float = 0.0

var _fill: StyleBoxFlat


func _ready() -> void:
	min_value = 0.0
	max_value = max_health
	show_percentage = false
	_fill = StyleBoxFlat.new()
	_fill.set_corner_radius_all(3)
	add_theme_stylebox_override("fill", _fill)
	var background: StyleBoxFlat = StyleBoxFlat.new()
	background.bg_color = Color(0, 0, 0, 0.6)
	background.set_corner_radius_all(3)
	add_theme_stylebox_override("background", background)
	set_health(max_health)


## 扣血
func damage(amount: float) -> void:
	set_health(health - amount)


## 補血（不會超過上限）
func heal(amount: float) -> void:
	set_health(health + amount)


func set_health(amount: float) -> void:
	var was_alive: bool = health > 0.0
	health = clampf(amount, 0.0, max_health)
	value = health
	_fill.bg_color = low_color.lerp(full_color, health / max_health)
	health_changed.emit(health)
	if was_alive and health <= 0.0:
		died.emit()
		if lose_when_dead:
			GameFlow.lose()


func is_dead() -> bool:
	return health <= 0.0
