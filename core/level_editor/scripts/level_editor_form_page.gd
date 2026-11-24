class_name LevelEditorFormPage
extends PanelContainer
## 編輯器的「規則」頁：改 map 上的幾個 @export 欄位，跟地圖一起存，上一步也算。
## 一行就好：add_form_page("規則", ["hint", "max_moves"])

## 哪個編輯器的
var editor: LevelEditor
## 改哪幾個欄位（照這個順序）
var names: Array = []
var say: Callable = func(_text: String) -> void: pass

var _grid: GridContainer


func _ready() -> void:
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(_grid)


func set_value(field: String, value: Variant) -> void:
	if editor.map.get(field) == value:
		return
	editor.remember()
	editor.map.set(field, value)
	editor.map.emit_changed()


func commit() -> void:
	LevelEditorForm.commit(self)


## 換了地圖、上一步：重新讀
func refresh() -> void:
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	for field: Dictionary in LevelEditorForm.fields_of(editor.map, names):
		LevelEditorForm.add(_grid, field, editor.map.get(field["name"]), set_value, 200, 18)
