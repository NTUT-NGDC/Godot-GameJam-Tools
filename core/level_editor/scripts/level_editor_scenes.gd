class_name LevelEditorScenes
extends RefCounted
## 編輯器用：一個資料夾裡的同一類場景（怪物、棋子……）和可以掛上去的掛件：列出來、讀、寫。
## 存成一般的 .tscn（繼承 base_path＋掛件），跟在 Godot 裡手動做的一樣，兩邊都可以改。
##   var enemies: LevelEditorScenes = LevelEditorScenes.new("res://…/enemies/", "res://…/enemy_traits/", "res://…/walker.tscn", ["speed", "color"])

## 場景的資料夾、掛件的資料夾（沒有掛件＝空字串），最後要有 /。資料夾第一層的 .tscn 都算，測試場景不要放進去
var scenes_dir: String
var traits_dir: String
## 新的場景繼承這個
var base_path: String
## 存哪些欄位
var fields: Array[String] = []
## base_path 在清單裡叫什麼（空的＝照 name_of()）
var base_name: String = ""


func _init(scenes: String, traits: String, base: String, saved_fields: Array[String]) -> void:
	scenes_dir = scenes
	traits_dir = traits
	base_path = base
	fields = saved_fields


func paths() -> PackedStringArray:
	return _scenes_in(scenes_dir)


func trait_paths() -> PackedStringArray:
	return _scenes_in(traits_dir)


## 叫這個名字的話存在哪
func path_for(text: String) -> String:
	return scenes_dir + text.strip_edges().validate_filename() + ".tscn"


## 清單裡的名字
func label_of(path: String) -> String:
	return base_name if path == base_path and not base_name.is_empty() else name_of(path)


## 場景的名字：display_name 欄位，腳本沒有這個欄位就看最上面節點的 metadata「display_name」，都沒有就用檔名
static func name_of(path: String) -> String:
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return path.get_file().get_basename()
	var node: Node = scene.instantiate()
	var text: Variant = node.get("display_name")
	if text == null:
		text = node.get_meta("display_name", "")
	node.free()
	return String(text) if text != null and not String(text).is_empty() else path.get_file().get_basename()


## 讀一個場景：{欄位…, "traits": {掛件路徑: {欄位: 值}}}
func read(path: String) -> Dictionary:
	var root: Node = (load(path) as PackedScene).instantiate()
	var data: Dictionary = {"traits": {}, "display_name": label_of(path)}
	for field: String in fields:
		data[field] = root.get(field)
	for child: Node in root.get_children():
		if trait_paths().has(child.scene_file_path) and not data["traits"].has(child.scene_file_path):
			data["traits"][child.scene_file_path] = _read_trait(child)
	root.free()
	return data


## 掛件的預設值
func trait_defaults(path: String) -> Dictionary:
	var node: Node = (load(path) as PackedScene).instantiate()
	var values: Dictionary = _read_trait(node)
	node.free()
	return values


## 把 data 寫進場景（沒有這個檔案就先做一個繼承 base_path 的）。其他手動加的節點不會動到
func write(path: String, data: Dictionary) -> Error:
	if not exists(path):
		var made: Error = _make_scene(path)
		if made != OK:
			return made
	var scene: PackedScene = load(path) as PackedScene
	if scene == null:
		return ERR_CANT_OPEN
	if not OS.has_feature("editor"):
		return ERR_UNAVAILABLE                                    # 匯出的遊戲不能存
	var root: Node = scene.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	for field: String in fields:
		root.set(field, data[field])
	if not "display_name" in root:
		root.set_meta("display_name", data["display_name"])
	var wanted: Dictionary = data["traits"]
	var have: Dictionary = {}
	for child: Node in root.get_children():
		var trait_path: String = child.scene_file_path
		if not trait_paths().has(trait_path) or have.has(trait_path):
			continue
		if wanted.has(trait_path):
			have[trait_path] = child
		else:
			root.remove_child(child)
			child.free()
	for trait_path: String in wanted:
		var node: Node = have.get(trait_path)
		if node == null:
			node = (load(trait_path) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
			root.add_child(node)
			node.owner = root
		for key: String in wanted[trait_path]:
			node.set(key, wanted[trait_path][key])
	var error: Error = scene.pack(root)                           # 改同一份場景：已經在用的地方馬上是新的
	root.free()
	return LevelMaker.save_scene(scene, path) if error == OK else error


## 有沒有這個檔案（剛刪掉的可能還在快取裡，所以也看檔案；匯出的遊戲只看快取）
static func exists(path: String) -> bool:
	return FileAccess.file_exists(path) if OS.has_feature("editor") else ResourceLoader.exists(path)


## 專案裡哪些檔案用到這個場景（.tscn、.tres、.gd）
static func used_by(path: String, dir: String = "res://") -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	var uid: int = ResourceLoader.get_resource_uid(path)
	var uid_text: String = ResourceUID.id_to_text(uid) if uid != ResourceUID.INVALID_ID else ""
	for file: String in DirAccess.get_files_at(dir):
		if file.get_extension() in ["tscn", "tres", "gd"] and dir + file != path:
			var text: String = FileAccess.get_file_as_string(dir + file)
			if text.contains(path) or (not uid_text.is_empty() and text.contains(uid_text)):
				result.append(dir + file)
	for sub_dir: String in DirAccess.get_directories_at(dir):
		if not sub_dir.begins_with("."):
			result.append_array(used_by(path, dir + sub_dir + "/"))
	return result


## 刪掉場景檔（丟到資源回收桶，刪錯撿得回來）
func delete(path: String) -> Error:
	if not OS.has_feature("editor"):
		return ERR_UNAVAILABLE                                    # 匯出的遊戲不能刪
	var file: String = ProjectSettings.globalize_path(path)
	var error: Error = DirAccess.remove_absolute(file) if DisplayServer.get_name() == "headless" else OS.move_to_trash(file)   # 自動測試就直接刪
	if error == OK and ResourceLoader.has_cached(path):
		(load(path) as PackedScene).resource_path = ""            # 同名的再做一次才不會讀到舊的
	return error


## 做一隻給預覽用的（path 是空的＝新的）
func make_preview(path: String, data: Dictionary) -> Node2D:
	var root: Node2D = (load(path if not path.is_empty() else base_path) as PackedScene).instantiate() as Node2D
	for child: Node in root.get_children():
		if trait_paths().has(child.scene_file_path):
			root.remove_child(child)
			child.free()
	for field: String in fields:
		root.set(field, data[field])
	for trait_path: String in data["traits"]:
		var node: Node = (load(trait_path) as PackedScene).instantiate()
		for key: String in data["traits"][trait_path]:
			node.set(key, data["traits"][trait_path][key])
		root.add_child(node)
	return root


func _read_trait(node: Node) -> Dictionary:
	var values: Dictionary = {}
	for field: Dictionary in LevelEditorForm.fields_of(node):
		values[field["name"]] = node.get(field["name"])
	return values


## 新的：寫一個繼承 base_path 的空場景
func _make_scene(path: String) -> Error:
	if OS.has_feature("editor"):
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))   # 第一個：資料夾還沒有
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var node_name: String = path.get_file().get_basename().validate_node_name()
	file.store_string("[gd_scene format=3]\n\n[ext_resource type=\"PackedScene\" path=\"%s\" id=\"1_base\"]\n\n[node name=\"%s\" instance=ExtResource(\"1_base\")]\n" % [base_path, node_name])
	file.close()
	return OK


static func _scenes_in(dir: String) -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	if not dir.is_empty() and DirAccess.dir_exists_absolute(dir):
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with(".tscn"):
				result.append(dir + file)
	return result
