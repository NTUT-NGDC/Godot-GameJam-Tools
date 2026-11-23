extends Node2D
## 主場景範本：還沒開始做的時候，按「開始遊戲」會來到這裡。
## 主場景負責人把 features/ 做好的功能（場景）拖進來組裝；這個腳本可以整個換掉。
## 兩個按鈕是用來試勝利／失敗畫面的，做好遊戲後刪掉。


func _ready() -> void:
	(%WinButton as Button).pressed.connect(func() -> void: GameFlow.win("這是勝利畫面"))
	(%LoseButton as Button).pressed.connect(func() -> void: GameFlow.lose("這是失敗畫面"))
	(%ScoreButton as Button).pressed.connect(func() -> void: (%ScoreDisplay as ScoreDisplay).add(10))
	(%DamageButton as Button).pressed.connect(func() -> void: (%HealthBar as HealthBar).damage(25))
