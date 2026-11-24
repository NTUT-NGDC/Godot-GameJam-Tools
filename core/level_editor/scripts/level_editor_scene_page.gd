class_name LevelEditorScenePage
extends PanelContainer
## 編輯器的「一類場景」頁（怪物、棋子……）：左邊清單（新的、複製、刪掉）、中間改數值和勾掛件、右邊預覽，存成一般場景。
## 做自己的：extends LevelEditorScenePage，在 _setup() 填 scenes、thing、fields，要算數值就覆寫 _preview_text()。

## 存了一個（其他頁要更新清單）
signal saved(path: String)
## 刪了一個（其他頁要更新清單）
signal deleted(path: String)

const MAX_HISTORY: int = 50

# ---- 設定（在 _setup() 裡改） ----

## 讀寫哪些場景
var scenes: LevelEditorScenes
## 這種東西叫什麼（「怪」「棋子」）
var thing: String = "東西"
## 可以改的欄位（LevelEditorForm 的欄位；名字 display_name 會自動放在最上面，腳本沒有這個欄位就存在 metadata）
var fields: Array[Dictionary] = []
## 掛件叫什麼（「掛件」「特性」）
var trait_title: String = "掛件"
## 欄位排成幾欄（欄位很多的話用 2）
var form_columns: int = 1
## 預覽的背景色、放大幾倍
var preview_color: Color = Color("6b5340")
var preview_scale: float = 4.0
## 預覽放在框裡的哪裡（框是 280×240）
var preview_at: Vector2 = Vector2(140, 120)

# ---- 狀態 ----

## 正在改的（試玩按「重來」時場景會重新載入，改到一半的留著）：{欄位…, "traits"}
var data: Dictionary:
	get: return _session.get("data", {})
	set(value): _session["data"] = value
## 現在改的檔案（空的＝還沒存過的）
var path: String:
	get: return _session.get("path", "")
	set(value): _session["path"] = value
## 改了還沒存
var dirty: bool:
	get: return _session.get("dirty", false)
	set(value): _session["dirty"] = value
var say: Callable = func(_text: String) -> void: pass
## 編輯器裡還沒存檔的地方有沒有用到這個場景（回傳哪裡，沒有＝空字串；編輯器給的）
var used_in_editor: Callable = func(_path: String) -> String: return ""

var _session: Dictionary = LevelEditor.session_of((get_script() as Script).resource_path)
var _history: Array[Dictionary] = []
var _future: Array[Dictionary] = []
var _list: ItemList
var _paths: PackedStringArray = PackedStringArray()
var _form: VBoxContainer
var _preview_box: Control
var _preview: Node2D
var _stats: Label
var _save_button: Button
var _new_button: Button
var _copy_button: Button
var _delete_button: Button
## 按過一次「刪掉」了（再按一次才真的刪）
var _delete_armed: bool = false
var _title: Label


# ---- 給各頁覆寫 ----

func _setup() -> void:
	pass


## 列出哪些（預設：資料夾裡全部）
func _list_paths() -> PackedStringArray:
	return scenes.paths()


## 這個不能改（例如積木本身）
func is_locked() -> bool:
	return false


## 預覽旁邊的字（preview 已經在場景裡，掛件有作用）
func _preview_text(_preview_node: Node2D) -> String:
	return ""


## 預覽放進場景之前
func _preview_made(_preview_node: Node2D) -> void:
	pass


## 預覽放進場景之後（例如從群組拿掉，不要被當成場上的）
func _preview_added(_preview_node: Node2D) -> void:
	pass


## 存好了（通知其他頁之前）
func _scene_saved(_path: String) -> void:
	pass


# ---- 選 ----

func _ready() -> void:
	_setup()
	_build_ui()
	if data.is_empty():
		open(_first_path())
	refresh()


func _first_path() -> String:
	return _list_paths()[0] if not _list_paths().is_empty() else scenes.base_path


func open(to: String) -> void:
	remember()                                                    # 沒存檔的按上一步拿得回來
	path = to
	data = scenes.read(to)
	dirty = false
	refresh()


## 新的（還沒存檔）
func new_scene() -> void:
	commit()
	remember()
	data = scenes.read(scenes.base_path)
	_use_new("新" + thing)
	say.call("新%s：改好名字和數值，按「存檔」" % thing)


## 把現在這個複製成新的
func copy_scene() -> void:
	commit()
	remember()
	data = data.duplicate(true)
	_use_new(String(data["display_name"]) + "2")
	say.call("複製了一個：改好名字和數值，按「存檔」")


func _use_new(text: String) -> void:
	var free_name: String = text
	var n: int = 2
	while LevelEditorScenes.exists(scenes.path_for(free_name)):      # 還沒有同名檔案的名字
		free_name = "%s%d" % [text, n]
		n += 1
	data["display_name"] = free_name
	path = ""
	dirty = true
	refresh()


# ---- 改 ----

func set_value(field: String, value: Variant) -> void:
	if is_locked() or data[field] == value:
		return
	remember()
	data[field] = value
	_changed()


func set_trait(trait_path: String, on: bool) -> void:
	if is_locked() or data["traits"].has(trait_path) == on:
		return
	remember()
	if on:
		data["traits"][trait_path] = scenes.trait_defaults(trait_path)
	else:
		data["traits"].erase(trait_path)
	_changed()
	_rebuild_form.call_deferred()                                 # 掛件的欄位要多出來／收起來


func set_trait_value(trait_path: String, field: String, value: Variant) -> void:
	if is_locked() or not data["traits"].has(trait_path) or data["traits"][trait_path][field] == value:
		return
	remember()
	data["traits"][trait_path][field] = value
	_changed()


func _changed() -> void:
	dirty = path.is_empty() or data != scenes.read(path)          # 改回原本的樣子就不算沒存
	_update_preview()
	_update_title()


## 存檔（新的：用名字當檔名）。回傳存到哪裡（失敗＝空字串）
func save() -> String:
	commit()
	if is_locked():
		say.call("這個不能改。按「複製成新%s」拿來改" % thing)
		return ""
	var text: String = String(data["display_name"]).strip_edges()
	if text.is_empty():
		say.call("先打%s的名字" % thing)
		return ""
	var to: String = path
	if to.is_empty():
		to = scenes.path_for(text)
		if LevelEditorScenes.exists(to):
			say.call("已經有叫「%s」的%s了，換個名字" % [text, thing])
			return ""
	var error: Error = scenes.write(to, data)
	if error != OK:
		say.call("存檔失敗：%s（匯出的遊戲不能存，要在 Godot 編輯器裡按 F6）" % error_string(error))
		return ""
	path = to
	dirty = false
	_scene_saved(to)
	saved.emit(to)
	refresh()
	say.call("存好了：%s" % to)
	return to


# ---- 刪 ----

## 為什麼不能刪（可以刪＝空字串）
func delete_problem() -> String:
	if path == scenes.base_path or is_locked():
		return "這個不能刪"
	if path.is_empty():
		return ""                                                 # 還沒存過的，直接丟掉
	if _list_paths().size() <= 1:
		return "至少要留一個"
	var where: String = used_in_editor.call(path)
	if not where.is_empty():
		return "%s有用到「%s」，先換成別種" % [where, data["display_name"]]
	var files: PackedStringArray = LevelEditorScenes.used_by(path)
	if files.is_empty():
		return ""
	var names: PackedStringArray = PackedStringArray()
	for file: String in files.slice(0, 3):
		names.append(file.get_file())
	return "%s%s 有用到「%s」，先換成別種" % ["、".join(names), " 等 %d 個檔案" % files.size() if files.size() > 3 else "", data["display_name"]]


## 「刪掉」：按第一次先問，再按一次才刪
func press_delete() -> void:
	commit()
	var trouble: String = delete_problem()
	if not trouble.is_empty():
		say.call("不能刪：" + trouble)
		return
	if not _delete_armed:
		_delete_armed = true
		_delete_button.text = "再按一次就刪掉"
		say.call("再按一次就刪掉「%s」" % data["display_name"])
		return
	delete_scene()


## 刪掉現在這個（丟到資源回收桶；按上一步拿得回來，變成還沒存檔的）。回傳有沒有刪
func delete_scene() -> bool:
	var trouble: String = delete_problem()
	if not trouble.is_empty():
		say.call("不能刪：" + trouble)
		return false
	var old: String = path
	var text: String = data["display_name"]
	if not old.is_empty():
		var error: Error = scenes.delete(old)
		if error != OK:
			say.call("刪不掉：%s" % error_string(error))
			return false
		for state: Dictionary in _history + _future:
			if state["path"] == old:
				state["path"] = ""                                # 檔案沒了：上一步回來就是還沒存過的
	path = ""
	open(_first_path())
	if not old.is_empty():
		deleted.emit(old)
	say.call("刪掉了「%s」%s" % [text, "" if old.is_empty() else "（在資源回收桶；按上一步再存檔也可以救回來）"])
	return true


func _disarm_delete() -> void:
	_delete_armed = false
	_delete_button.text = "刪掉"
	_delete_button.disabled = path == scenes.base_path or is_locked()


# ---- 上一步、下一步 ----

func remember() -> void:
	if data.is_empty():
		return
	_history.append(_state())
	if _history.size() > MAX_HISTORY:
		_history.pop_front()
	_future.clear()


func undo() -> bool:
	if _history.is_empty():
		say.call("沒有上一步了")
		return false
	_future.append(_state())
	_use(_history.pop_back())
	say.call("上一步（還可以退 %d 步）" % _history.size())
	return true


func redo() -> bool:
	if _future.is_empty():
		say.call("沒有下一步了")
		return false
	_history.append(_state())
	_use(_future.pop_back())
	say.call("下一步")
	return true


## 現在改的是哪一個、改成什麼樣子（上一步用）
func _state() -> Dictionary:
	return {"data": data.duplicate(true), "path": path}


func _use(state: Dictionary) -> void:
	data = state["data"]
	path = state["path"]
	dirty = path.is_empty() or data != scenes.read(path)
	refresh()


# ---- 介面 ----

## 打到一半的字先算數（存檔、試玩、換一個、換頁之前）
func commit() -> void:
	LevelEditorForm.commit(self)


func _build_ui() -> void:
	var columns: HBoxContainer = HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	add_child(columns)

	var left: VBoxContainer = VBoxContainer.new()
	left.custom_minimum_size = Vector2(200, 0)
	columns.add_child(left)
	_list = ItemList.new()
	_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list.focus_mode = Control.FOCUS_NONE
	_list.item_selected.connect(_on_selected)
	left.add_child(_list)
	_new_button = _button(left, "＋ 新" + thing, new_scene)
	_copy_button = _button(left, "複製成新" + thing, copy_scene)
	_delete_button = _button(left, "刪掉", press_delete)
	LevelEditorStyle.paint(_delete_button, LevelEditorStyle.DANGER)
	visibility_changed.connect(_disarm_delete)

	var middle: VBoxContainer = VBoxContainer.new()
	middle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(middle)
	var top: HBoxContainer = HBoxContainer.new()
	middle.add_child(top)
	_save_button = _button(top, "存檔", save)
	_title = _label(top, "", 14)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	middle.add_child(scroll)
	_form = VBoxContainer.new()
	_form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_form)

	var right: VBoxContainer = VBoxContainer.new()
	right.custom_minimum_size = Vector2(280, 0)
	columns.add_child(right)
	_label(right, "預覽", 14)
	_preview_box = Control.new()
	_preview_box.custom_minimum_size = Vector2(280, 240)
	_preview_box.clip_contents = true
	right.add_child(_preview_box)
	var background: ColorRect = ColorRect.new()
	background.color = preview_color
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_box.add_child(background)
	_stats = _label(right, "", 14)


func _on_selected(index: int) -> void:
	commit()
	if dirty and _paths[index] != path:
		say.call("剛剛改的「%s」沒有存檔（按上一步拿得回來）" % data["display_name"])
	open(_paths[index])


## 整頁重做（換了一個、存檔）
func refresh() -> void:
	if _list == null or data.is_empty():
		return
	_paths = _list_paths()
	_list.clear()
	for i: int in _paths.size():
		_list.add_item(scenes.label_of(_paths[i]) + ("（不能改）" if _paths[i] == scenes.base_path else ""))
		if _paths[i] == path:
			_list.select(i)
	_rebuild_form()
	_update_preview()
	_update_title()


func _update_title() -> void:
	if is_locked():
		_title.text = "　這個不能改；按「複製成新%s」拿來改" % thing
	elif path.is_empty():
		_title.text = "　還沒存檔的新" + thing
	else:
		_title.text = "　%s%s" % [path.get_file(), "　＊改了還沒存檔" if dirty else ""]
	_save_button.disabled = is_locked()
	_disarm_delete()
	update_save_button()


## 改了還沒存（試玩前會問要不要存）
func is_dirty() -> bool:
	return dirty and not is_locked()


func update_save_button() -> void:
	LevelEditorStyle.paint_save(_save_button, dirty and not is_locked())


func _rebuild_form() -> void:
	if data.is_empty():
		return
	for child: Node in _form.get_children():
		_form.remove_child(child)
		child.queue_free()
	var grid: GridContainer = GridContainer.new()
	grid.columns = form_columns * 2
	_form.add_child(grid)
	_lock(LevelEditorForm.add(grid, LevelEditorForm.text("display_name", "名字"), data["display_name"], set_value))
	for field: Dictionary in fields:
		_lock(LevelEditorForm.add(grid, field, data[field["name"]], set_value))
	if scenes.trait_paths().is_empty():
		return
	_form.add_child(HSeparator.new())
	_label(_form, trait_title + "（勾起來就有）", 15)
	for trait_path: String in scenes.trait_paths():
		_add_trait(trait_path)


func _add_trait(trait_path: String) -> void:
	var sample: Node = (load(trait_path) as PackedScene).instantiate()
	var on: bool = data["traits"].has(trait_path)
	var line: HBoxContainer = HBoxContainer.new()
	_form.add_child(line)
	var box: CheckBox = CheckBox.new()
	box.text = sample.call("trait_name") if sample.has_method("trait_name") else String(sample.name)
	box.tooltip_text = sample.call("description") if sample.has_method("description") else ""
	box.custom_minimum_size = Vector2(100, 0)
	box.button_pressed = on
	box.disabled = is_locked()
	box.focus_mode = Control.FOCUS_NONE
	box.toggled.connect(func(pressed: bool) -> void:
		commit()
		set_trait(trait_path, pressed))
	line.add_child(box)
	if on:
		var grid: GridContainer = GridContainer.new()
		grid.columns = 4
		line.add_child(grid)
		for field: Dictionary in LevelEditorForm.fields_of(sample):
			_lock(LevelEditorForm.add(grid, field, data["traits"][trait_path][field["name"]], func(key: String, value: Variant) -> void: set_trait_value(trait_path, key, value), 0, 13))
	sample.free()


## 不能改的時候，格子也不能動
func _lock(control: Control) -> void:
	if not is_locked():
		return
	if control is SpinBox:
		(control as SpinBox).editable = false
	elif control is LineEdit:
		(control as LineEdit).editable = false
	elif control is BaseButton:
		(control as BaseButton).disabled = true


## 預覽：照現在改的數值做一個，放大給你看
func _update_preview() -> void:
	if _preview != null:
		_preview.free()
	_preview = scenes.make_preview(path, data)
	_preview.process_mode = Node.PROCESS_MODE_DISABLED
	_preview_made(_preview)
	_preview_box.add_child(_preview)
	_preview_added(_preview)
	_preview.position = preview_at
	_preview.scale = Vector2.ONE * preview_scale
	_stats.text = _preview_text(_preview)


func _label(parent: Control, text: String, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


func _button(parent: Control, text: String, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: action.call())
	parent.add_child(button)
	return button
