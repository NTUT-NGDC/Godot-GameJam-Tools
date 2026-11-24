extends Control
## 關卡選擇畫面：照 game_config.tres 的 Levels 自動產生按鈕，不用改這裡。
## 有兩關以上時，標題畫面的「開始遊戲」會進來。過了的打勾，還沒解鎖的是灰色。
## 想改字的大小、顏色、背景：打開 level_select_screen.tscn，點節點在右邊的檢查器改。

## 一顆關卡按鈕多大
@export var button_size: Vector2 = Vector2(220, 110)

@onready var _grid: GridContainer = %LevelGrid
@onready var _clear: Button = %ClearButton

## 「清除進度」要按兩次
var _confirming: bool = false


func _enter_tree() -> void:
	add_to_group("no_pause")


func _ready() -> void:
	(%BackButton as Button).pressed.connect(_go_back)
	_clear.pressed.connect(_on_clear_pressed)
	refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_go_back()
		get_viewport().set_input_as_handled()


## 照現在的進度重做按鈕
func refresh() -> void:
	for child: Node in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	var config: GameConfig = GameConfig.current()
	var levels: PackedStringArray = config.level_paths()
	var focus: Button = null
	for i: int in levels.size():
		var button: Button = _make_button(config.level_name(i), LevelProgress.is_cleared(levels[i]), LevelProgress.is_unlocked(i))
		button.pressed.connect(func() -> void: SceneManager.change_scene(levels[i]))
		_grid.add_child(button)
		if focus == null and not button.disabled and not LevelProgress.is_cleared(levels[i]):
			focus = button                                        # 先選到第一個還沒過的
	if focus == null and _grid.get_child_count() > 0:
		focus = _grid.get_child(0)
	if focus != null:
		focus.grab_focus()
	else:
		(%BackButton as Button).grab_focus()


func _make_button(text: String, cleared: bool, unlocked: bool) -> Button:
	var button: Button = Button.new()
	button.text = text + ("\n✓ 過關" if cleared else "\n未解鎖" if not unlocked else "")
	button.disabled = not unlocked
	button.custom_minimum_size = button_size
	button.add_theme_font_size_override("font_size", 22)
	if cleared:
		button.add_theme_color_override("font_color", Color("8fe0a0"))
	return button


func _on_clear_pressed() -> void:
	if not _confirming:
		_confirming = true
		_clear.text = "再按一次就清除"
		return
	_confirming = false
	_clear.text = "清除進度"
	LevelProgress.clear()
	refresh()


func _go_back() -> void:
	SceneManager.change_scene(GameConfig.TITLE_SCENE)
