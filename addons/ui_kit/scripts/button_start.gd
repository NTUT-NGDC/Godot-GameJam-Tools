extends Control

func _on_button_start_pressed() -> void:
	get_tree().change_scene_to_file("res://addons/demo/demo_scene.tscn")

#請將("res://addons/demo/demo_scene.tscn")換成自己想要的遊戲主場景
