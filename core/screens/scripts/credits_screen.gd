extends Control
## Credits 畫面：名單從 game_config.tres 的 Credits 自動產生，不用改這裡。
## 「職位：名字」會排成左右兩欄；沒有冒號的行當成小標題；空白行是間隔。

@onready var _list: VBoxContainer = %CreditsList


func _enter_tree() -> void:
	add_to_group("no_pause")


func _ready() -> void:
	var config: GameConfig = GameConfig.current()
	(%GameName as Label).text = config.game_name
	for line: String in config.credit_lines():
		_list.add_child(_make_row(line))
	if config.credit_lines().is_empty():
		_list.add_child(_make_row("（在 game_config.tres 的 Credits 填名單）"))
	(%BackButton as Button).pressed.connect(_go_back)
	(%BackButton as Button).grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_go_back()
		get_viewport().set_input_as_handled()


func _go_back() -> void:
	SceneManager.change_scene(GameConfig.TITLE_SCENE)


## 一行名單 → 一列：「職位：名字」左右兩欄，其他整行置中
func _make_row(line: String) -> Control:
	var separator: int = line.find("：")
	if separator < 0:
		separator = line.find(":")
	if separator < 0:
		var label: Label = _label(line, HORIZONTAL_ALIGNMENT_CENTER, Color(1, 0.85, 0.5))
		label.custom_minimum_size.y = 22 if line == "" else 0
		return label
	var row: HBoxContainer = HBoxContainer.new()
	row.add_theme_constant_override("separation", 22)
	var role: Label = _label(line.substr(0, separator).strip_edges(), HORIZONTAL_ALIGNMENT_RIGHT, Color(1, 1, 1, 0.65))
	var names: Label = _label(line.substr(separator + 1).strip_edges(), HORIZONTAL_ALIGNMENT_LEFT, Color.WHITE)
	role.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(role)
	row.add_child(names)
	return row


func _label(text: String, align: HorizontalAlignment, color: Color) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.horizontal_alignment = align
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", color)
	return label
