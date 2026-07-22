extends Node2D
## DemoScene 用的示範角色：血量、扣血、死亡 signal（給 ui_kit 的 HealthBar / UIManager 使用），
## 扣血時同步累加 GameSession 的分數，示範存檔資料如何隨遊戲進行而更新。

signal player_died
signal stats_changed

const MOVE_SPEED := 220.0

var hp: int = 10
var dead: bool = false


func _ready() -> void:
	position = get_viewport_rect().size / 2
	stats_changed.emit()


## 上下左右移動:讀 Project Settings -> Input Map 裡設定的 move_up/move_down/move_left/move_right
func _physics_process(delta: float) -> void:
	if dead:
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	position += input_dir * MOVE_SPEED * delta


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("damage_test"):
		take_damage(1)


func take_damage(amount: int) -> void:
	if dead:
		return

	hp = max(0, hp - amount)
	if not GameSession.game_data.is_empty():
		GameSession.game_data["score"] = GameSession.game_data.get("score", 0) + 1
	stats_changed.emit()

	if hp <= 0:
		die()


func die() -> void:
	dead = true
	player_died.emit()
