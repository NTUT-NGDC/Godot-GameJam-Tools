extends Node
## 開發用：打開一個場景，做一個動作，截圖存到 user://（不會匯出）。
##   godot --path . res://_dev/screenshot.tscn -- scene=res://core/screens/title_screen.tscn do=settings out=title.png wait=1
## do：pause（打開暫停選單）、settings（打開設定）、win、lose


func _ready() -> void:
	var args: Dictionary[String, String] = {}
	for arg: String in OS.get_cmdline_user_args():
		var parts: PackedStringArray = arg.split("=", true, 1)
		args[parts[0]] = parts[1] if parts.size() > 1 else ""
	get_tree().current_scene = null
	SceneManager.change_scene(args.get("scene", GameConfig.TITLE_SCENE), 0.0)
	await get_tree().create_timer(0.5).timeout
	var scene: Node = get_tree().current_scene
	match args.get("do", ""):
		"win": GameFlow.win("你逃出去了！通關時間 1:23")
		"lose": GameFlow.lose("被抓到了……")
		"pause":
			for child: Node in GameFlow.get_children():
				if child.has_method("open_menu"):
					child.call("open_menu")
		"settings":
			var panel: Node = scene.get_node_or_null("%SettingsPanel")
			if panel != null:
				(panel as Control).show()
	var frames_before: int = Engine.get_frames_drawn()
	var time_before: int = Time.get_ticks_msec()
	await get_tree().create_timer(float(args.get("wait", "0.5"))).timeout
	print("平均 fps：%.0f" % ((Engine.get_frames_drawn() - frames_before) * 1000.0 / maxi(Time.get_ticks_msec() - time_before, 1)))
	var out: String = "user://" + args.get("out", "shot.png")
	get_viewport().get_texture().get_image().save_png(out)
	print("截圖：", ProjectSettings.globalize_path(out))
	get_tree().quit()
