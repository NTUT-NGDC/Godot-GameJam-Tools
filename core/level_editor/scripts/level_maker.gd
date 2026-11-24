class_name LevelMaker
extends RefCounted
## 做成關卡：寫一個繼承 base 的場景，只換裡面幾個節點的資源（地圖、波次……）。
## 改 base 關卡（畫面、規則），繼承的關卡也會跟著改；資源是用檔案連過去的，之後再改檔案，關卡也會跟著變。

## path＝存到哪、base＝繼承哪個關卡、values＝{節點路徑: {屬性: 資源檔案}}，最上面的節點寫 "."。
## 已經有同名的檔案就不動它（回傳 ERR_ALREADY_EXISTS）
static func make(path: String, base: String, values: Dictionary) -> Error:
	if FileAccess.file_exists(path):
		return ERR_ALREADY_EXISTS
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var head: PackedStringArray = PackedStringArray(["[gd_scene format=3]", "",
		"[ext_resource type=\"PackedScene\" path=\"%s\" id=\"1_base\"]" % base])
	var body: PackedStringArray = PackedStringArray(["",
		"[node name=\"%s\" instance=ExtResource(\"1_base\")]" % path.get_file().get_basename().validate_node_name()])
	if not values.has("."):
		body.append("")
	var number: int = 2
	var nodes: Array = values.keys()
	nodes.sort_custom(func(a: String, _b: String) -> bool: return a == ".")   # 最上面的節點要先寫
	for node: String in nodes:
		var parent: String = node.get_base_dir()
		if node != ".":
			body.append("[node name=\"%s\" parent=\"%s\"]" % [node.get_file(), parent if not parent.is_empty() else "."])
		for property: String in values[node]:
			head.append("[ext_resource type=\"Resource\" path=\"%s\" id=\"%d_value\"]" % [values[node][property], number])
			body.append("%s = ExtResource(\"%d_value\")" % [property, number])
			number += 1
		body.append("")
	file.store_string("\n".join(head) + "\n" + "\n".join(body))
	file.close()
	return OK


## 存場景，uid 不變（在遊戲裡存檔，Godot 會弄掉檔案開頭的 uid，別的檔案用 uid 連過來就會斷）
static func save_scene(scene: PackedScene, path: String) -> Error:
	var uid: String = _uid_of(path)
	var error: Error = ResourceSaver.save(scene, path)
	if error != OK or uid.is_empty() or not _uid_of(path).is_empty():
		return error
	var text: String = FileAccess.get_file_as_string(path)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text.insert(text.find("]"), " uid=\"%s\"" % uid))
	file.close()
	return OK


static func _uid_of(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""
	var head: String = FileAccess.get_file_as_string(path).get_slice("]", 0)
	return head.get_slice("uid=\"", 1).get_slice("\"", 0) if head.contains("uid=\"") else ""
