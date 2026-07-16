extends Control

#請在編輯器中把玩家節點拖進來，玩家節點需要有hp屬性
@export var player_path: NodePath

@onready var hp_bar = $HealthBar
@onready var player = get_node(player_path) if not player_path.is_empty() else null

func _process(delta):
	if player:
		hp_bar.value = player.hp
