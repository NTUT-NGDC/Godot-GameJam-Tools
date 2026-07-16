extends Control

const SCENE_A := "res://addons/scene_manager/Tests/Scenes/SceneManager_TestA.tscn"


func _on_go_to_a_pressed() -> void:
	SceneManager.change_scene(SCENE_A)


## 示範用 scene_list 的索引切換,不用打完整路徑。
## SceneManager.tscn 內建的 scene_list 是 [TestA, TestB],所以 index 0 = TestA。
func _on_go_to_a_by_index_pressed() -> void:
	SceneManager.change_scene_by_index(0)


## 示範選用功能:use_loading_screen = true 會走 ResourceLoader 非同步載入,
## 切換中顯示 Loading 畫面 + 進度條(場景較大時才看得出效果)。
func _on_go_to_a_with_loading_pressed() -> void:
	SceneManager.change_scene(SCENE_A, 0.4, true)
