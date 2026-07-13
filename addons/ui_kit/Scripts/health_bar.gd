extends Control

@onready var hp_bar = $HealthBar
@onready var player = $"../UI_testbot"

func _process(delta):
	hp_bar.value = player.hp
