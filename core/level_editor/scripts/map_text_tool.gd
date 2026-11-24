extends Node
## 命令列把地圖轉成文字、從文字寫回去，用法看 map_text.gd。

func _ready() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var problem: String = _run(args)
	print("完成" if problem.is_empty() else "失敗：" + problem)
	get_tree().quit(0 if problem.is_empty() else 1)


func _run(args: PackedStringArray) -> String:
	if args.size() < 3 or not ["export", "import", "new"].has(args[0]):
		return "要寫 export／import 地圖 文字檔，或 new 新地圖 文字檔 地圖的腳本"
	var map: Resource = null
	if args[0] == "new":
		if FileAccess.file_exists(args[1]):
			return "%s 已經有了，改用 import" % args[1]
		if args.size() < 4 or not ResourceLoader.exists(args[3]):
			return "new 要給地圖的腳本"
		map = (load(args[3]) as GDScript).new()
		map.set("map_name", args[1].get_file().get_basename())
	elif ResourceLoader.exists(args[1]):
		map = load(args[1])
	if map == null or not map.has_method("text_letters"):
		return "讀不到 %s，或它不能轉成文字（要有 text_letters()）" % args[1]
	if args[0] == "export":
		var file: FileAccess = FileAccess.open(args[2], FileAccess.WRITE)
		if file == null:
			return "寫不了 %s" % args[2]
		file.store_string(MapText.to_text(map))
		return ""
	if not FileAccess.file_exists(args[2]):
		return "沒有 %s" % args[2]
	var problem: String = MapText.apply(map, FileAccess.get_file_as_string(args[2]))
	if not problem.is_empty():
		return problem
	var error: Error = ResourceSaver.save(map, args[1])
	return "" if error == OK else error_string(error)
