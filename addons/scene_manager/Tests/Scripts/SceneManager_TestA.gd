extends Control

const SCENE_B := "res://addons/scene_manager/Tests/Scenes/SceneManager_TestB.tscn"


func _on_go_to_b_pressed() -> void:
	SceneManager.change_scene(SCENE_B)


## 示範用 scene_list 的索引切換,不用打完整路徑。
## SceneManager.tscn 內建的 scene_list 是 [TestA, TestB],所以 index 1 = TestB。
func _on_go_to_b_by_index_pressed() -> void:
	SceneManager.change_scene_by_index(1)


## 驗收標準:連續快速觸發不應該讓遊戲卡死或跳轉錯誤。
## 這裡故意在同一畫格內連續呼叫五次,SceneManager 應該只真的切換一次,
## 其餘四次會被忽略並在 Output 印出警告。
func _on_spam_pressed() -> void:
	for i in range(5):
		SceneManager.change_scene(SCENE_B)
