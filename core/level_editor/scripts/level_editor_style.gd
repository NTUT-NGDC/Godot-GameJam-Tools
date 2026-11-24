class_name LevelEditorStyle
extends RefCounted
## 關卡編輯器的按鈕顏色，都寫在這裡。

## 存檔
const SAVE: Color = Color("2e8b57")
## 有東西還沒存檔
const UNSAVED: Color = Color("e0a526")
## 試玩
const PLAY: Color = Color("2f6fc4")
## 會弄掉東西（清空、停止）
const DANGER: Color = Color("b5403a")
## 選中的分頁、工具
const SELECTED: Color = Color("5aa9ff")
## 沒選的分頁、工具
const PLAIN: Color = Color("2d2d2d")


## 整顆按鈕上色
static func paint(button: Button, color: Color) -> void:
	var text: Color = Color.BLACK if color.get_luminance() > 0.55 else Color.WHITE
	button.add_theme_stylebox_override("normal", _box(color))
	button.add_theme_stylebox_override("hover", _box(color.lightened(0.15)))
	button.add_theme_stylebox_override("pressed", _box(color.darkened(0.2)))
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		button.add_theme_color_override(state, text)


## 只有字上色（一排很多顆的小按鈕，整顆上色會太花）
static func paint_text(button: Button, color: Color) -> void:
	for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		button.add_theme_color_override(state, color.lightened(0.25))


## 可以按住的按鈕（分頁、工具）：選中的時候有亮藍色外框
static func paint_toggle(button: Button) -> void:
	var box: StyleBoxFlat = _box(SELECTED.darkened(0.65))
	box.border_color = SELECTED
	box.set_border_width_all(2)
	button.add_theme_stylebox_override("normal", _box(PLAIN))        # 每個狀態留白一樣，字才不會被切掉
	button.add_theme_stylebox_override("hover", _box(PLAIN.lightened(0.1)))
	button.add_theme_stylebox_override("disabled", _box(PLAIN.darkened(0.2)))
	for state: String in ["pressed", "hover_pressed"]:
		button.add_theme_stylebox_override(state, box)


## 存檔按鈕：沒存的時候變黃、多一個＊
static func paint_save(button: Button, unsaved: bool) -> void:
	var text: String = "存檔＊" if unsaved else "存檔"
	if button.text == text and button.has_theme_stylebox_override("normal"):
		return
	button.text = text
	button.custom_minimum_size = Vector2(72, 0)                   # 多了＊也不會變寬，旁邊的按鈕不會跳
	paint(button, UNSAVED if unsaved else SAVE)


static func _box(color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(3)
	box.content_margin_left = 6.0
	box.content_margin_right = 6.0
	box.content_margin_top = 4.0
	box.content_margin_bottom = 4.0
	return box
