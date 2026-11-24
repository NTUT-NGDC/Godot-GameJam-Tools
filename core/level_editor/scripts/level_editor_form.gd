class_name LevelEditorForm
extends RefCounted
## 編輯器的表單：把「可以改的欄位」變成數字框、勾選、下拉選單、文字、顏色。
## 欄位可以自己寫（number()、text()……），也可以從節點的 @export 自動讀（fields_of()）：
## 範圍、單位讀 @export_range，選項讀 @export_enum，中文名字和說明讀上面那行 ## 註解。
##
## 一個欄位：{"name", "kind"（"number"、"bool"、"options"、"text"、"color"）, "label", "tip", "min", "max", "step", "suffix", "whole"（整數）, "options", "values"（選項存的值）, "max_length"}

static var _docs: Dictionary[String, Dictionary] = {}


static func number(name: String, label: String, from: float, to: float, step: float, suffix: String = "", tip: String = "", whole: bool = false) -> Dictionary:
	return {"name": name, "kind": "number", "label": label, "tip": tip, "min": from, "max": to, "step": step, "suffix": suffix, "whole": whole}


static func text(name: String, label: String, max_length: int = 0, tip: String = "") -> Dictionary:
	return {"name": name, "kind": "text", "label": label, "tip": tip, "max_length": max_length}


static func color(name: String, label: String, tip: String = "") -> Dictionary:
	return {"name": name, "kind": "color", "label": label, "tip": tip}


static func check(name: String, label: String, tip: String = "") -> Dictionary:
	return {"name": name, "kind": "bool", "label": label, "tip": tip}


## values＝每個選項存的值（不給＝存第幾個）
static func options(name: String, label: String, choices: Array, tip: String = "", values: Array = []) -> Dictionary:
	return {"name": name, "kind": "options", "label": label, "tip": tip, "options": choices, "values": values if not values.is_empty() else range(choices.size())}


## 讀一個節點（或資源）的 @export 欄位。only＝只要這幾個，照 only 的順序（空的＝全部，照宣告的順序）、skip＝不要這幾個。
## 節點有 labels()（欄位 → 中文）的話，名字用它的
static func fields_of(object: Object, only: Array = [], skip: Array = []) -> Array[Dictionary]:
	var labels: Dictionary = object.call("labels") if object.has_method("labels") else {}
	var docs: Dictionary = docs_of(object.get_script())
	var result: Array[Dictionary] = []
	for property: Dictionary in object.get_property_list():
		var name: String = property["name"]
		if not (property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE and property["usage"] & PROPERTY_USAGE_EDITOR):
			continue
		if skip.has(name) or not (only.is_empty() or only.has(name)):
			continue
		var doc: String = docs.get(name, "")
		var field: Dictionary = _field_of(property, labels.get(name, _short(doc) if not doc.is_empty() else name), doc)
		if not field.is_empty():
			result.append(field)
	if not only.is_empty():
		result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return only.find(a["name"]) < only.find(b["name"]))
	return result


static func _field_of(property: Dictionary, label: String, tip: String) -> Dictionary:
	var name: String = property["name"]
	var parts: PackedStringArray = String(property["hint_string"]).split(",")
	if property["hint"] == PROPERTY_HINT_ENUM:
		if property["type"] == TYPE_STRING:
			return options(name, label, Array(parts), tip, Array(parts))
		var choices: Array = []
		var values: Array = []
		for i: int in parts.size():                               # "名字" 或 "名字:值"
			choices.append(parts[i].get_slice(":", 0))
			values.append(parts[i].get_slice(":", 1).to_int() if parts[i].contains(":") else i)
		return options(name, label, choices, tip, values)
	match int(property["type"]):
		TYPE_BOOL:
			return check(name, label, tip)
		TYPE_STRING:
			return text(name, label, 0, tip)
		TYPE_COLOR:
			return color(name, label, tip)
		TYPE_INT, TYPE_FLOAT:
			var whole: bool = property["type"] == TYPE_INT
			var field: Dictionary = number(name, label, 0.0, 1000.0, 1.0 if whole else 0.1, "", tip, whole)
			if property["hint"] == PROPERTY_HINT_RANGE:
				if parts.size() >= 2:
					field["min"] = parts[0].to_float()
					field["max"] = parts[1].to_float()
				if parts.size() >= 3 and parts[2].is_valid_float():
					field["step"] = parts[2].to_float()
				for part: String in parts:
					if part.begins_with("suffix:"):
						field["suffix"] = part.trim_prefix("suffix:")
			return field
	return {}


## 腳本裡 @export 上面的 ## 註解：欄位 → 說明（繼承的也算；匯出的遊戲讀不到，會用欄位名字）
static func docs_of(script: Script) -> Dictionary:
	if script == null:
		return {}
	if _docs.has(script.resource_path):
		return _docs[script.resource_path]
	var result: Dictionary = docs_of(script.get_base_script()).duplicate()
	var doc: PackedStringArray = PackedStringArray()
	for line: String in script.source_code.split("\n"):
		if line.begins_with("##"):
			doc.append(line.trim_prefix("##").strip_edges())
			continue
		if line.begins_with("@export") and line.contains("var ") and not doc.is_empty():
			result[line.get_slice("var ", 1).get_slice(":", 0).get_slice("=", 0).strip_edges()] = "\n".join(doc)
		doc.clear()
	if not script.resource_path.is_empty():
		_docs[script.resource_path] = result
	return result


## 說明的第一小句當名字（「打勾：……」看後面那句）
static func _short(doc: String) -> String:
	var result: String = doc.get_slice("\n", 0)
	for prefix: String in ["打勾：", "打勾＝", "勾起來："]:
		result = result.trim_prefix(prefix)
	for mark: String in ["（", "：", "。", "，", "；", "＝", "("]:
		result = result.get_slice(mark, 0)
	return result.strip_edges()


# ---- 變成介面 ----

## 在 parent（通常是 2 欄的 GridContainer）加一個欄位：名字＋可以改的東西。改了就叫 changed(欄位名, 新的值)
static func add(parent: Control, field: Dictionary, value: Variant, changed: Callable, label_width: int = 110, font_size: int = 15) -> Control:
	var label: Label = Label.new()
	label.text = field["label"]
	label.tooltip_text = field["tip"]
	label.mouse_filter = Control.MOUSE_FILTER_PASS                # 滑鼠停著看得到說明
	label.custom_minimum_size = Vector2(label_width, 0)
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	var name: String = field["name"]
	var control: Control
	match String(field["kind"]):
		"number":
			var box: SpinBox = SpinBox.new()
			box.min_value = field["min"]
			box.max_value = field["max"]
			box.step = field["step"]
			box.suffix = field["suffix"]
			box.custom_minimum_size = Vector2(110, 0)
			box.set_value_no_signal(value)
			var whole: bool = field["whole"] or value is int
			box.value_changed.connect(func(v: float) -> void:
				if whole:
					changed.call(name, int(v))
				else:
					changed.call(name, v))
			control = box
		"bool":
			var box: CheckBox = CheckBox.new()
			box.button_pressed = value
			box.focus_mode = Control.FOCUS_NONE
			box.toggled.connect(func(on: bool) -> void: changed.call(name, on))
			control = box
		"options":
			var box: OptionButton = OptionButton.new()
			for choice: Variant in field["options"]:
				box.add_item(str(choice))
			box.select((field["values"] as Array).find(value))
			box.focus_mode = Control.FOCUS_NONE
			box.item_selected.connect(func(index: int) -> void: changed.call(name, field["values"][index]))
			control = box
		"color":
			var box: ColorPickerButton = ColorPickerButton.new()
			box.color = value
			box.edit_alpha = false
			box.custom_minimum_size = Vector2(160, 30)
			box.focus_mode = Control.FOCUS_NONE
			box.popup_closed.connect(func() -> void: changed.call(name, box.color))
			control = box
		_:
			var box: LineEdit = LineEdit.new()
			box.text = value
			box.max_length = field["max_length"]
			box.custom_minimum_size = Vector2(160, 0)
			box.expand_to_text_length = true
			box.focus_exited.connect(func() -> void: changed.call(name, box.text))
			box.text_submitted.connect(func(_text: String) -> void: box.release_focus())
			control = box
	control.tooltip_text = field["tip"]
	parent.add_child(control)
	return control


## 打到一半的字先算數：panel 裡正在打字的格子
static func commit(panel: Control) -> void:
	var focus: Control = panel.get_viewport().gui_get_focus_owner() if panel.is_inside_tree() else null
	if focus != null and panel.is_ancestor_of(focus):
		if focus.get_parent() is SpinBox:
			(focus.get_parent() as SpinBox).apply()
		focus.release_focus()
