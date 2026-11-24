# 關卡編輯器的底

在遊戲裡做關卡的編輯器（打開場景按 `F6`），不用學 Godot 的場景和檢查器。這裡是共用的部分，**每個遊戲只寫自己的東西**：有哪些工具、放下去做什麼、試玩時怎麼把地圖交給關卡。

已經有的：分頁、工具分類、畫筆／矩形／圓形／油漆桶、右鍵擦、滾輪調筆刷、上一步／下一步、存檔讀檔、沒存檔按鈕變黃、改大小、鏡頭移動縮放、直接試玩和停止、做成關卡、試玩前問要不要存檔。

## 用這個底做好的編輯器

塔防、戰棋、追逐在尋路積木的 repo（[Pathfinding-Template](https://github.com/NTUT-NGDC/Pathfinding-Template)）。

| 編輯器 | 特色 | 想做類似的就看它 |
| --- | --- | --- |
| [sample/](sample/) | 最小範例：畫牆、放起點和星星，地圖用 `.tres` | 第一次做 |
| 塔防 `examples/tower_defense/map_editor/` | 圓滑地形、波次頁、怪物頁 | 要有自己的資料頁、掛件 |
| 戰棋 `examples/tactics/map_editor/` | 五頁、可以切換對齊格子、隊伍 | 很多種東西、規則頁 |
| 追逐 `examples/chase/map_editor/` | 直接讀寫關卡 `.tscn`，物件放上去，右邊面板改數值；同一種物件可以有好幾「種類」 | 關卡是場景、物件是場景、工具很多要分類 |

## 做一個自己的編輯器

1. 複製 `sample/` 的三個腳本和兩個場景到 `features/<名字>/`，改 `class_name` 和**全部的 `res://core/level_editor/sample/` 路徑**（兩個 `.tscn` 裡、編輯器的 `maps_dir`、`play_scene`、`_level_request()`）
2. **地圖**：一個 `Resource`，要有 `map_name`、`size`、`ensure()`、`snapshot()`、`restore()`、`resize()`。要存的欄位加 `@export`（沒加不會存！）、也要放進 `snapshot()`／`restore()`（不然上一步、「有沒有改過」會漏掉）。用 `Array[Vector2i]`、`Dictionary` 這種看得懂的型別，不要用 `PackedByteArray`。想讓 AI 能看、能畫地圖就加 `text_letters()` 那四個函式（看下面「地圖變成文字」）
3. **關卡**：`_ready()` 讀 `static var test_map`（試玩）或 `@export var map`（平常）。試玩時關卡加在編輯器底下的 (0, 0)，放一個 `Camera2D` 就會用它，停止試玩會自己換回來
4. **編輯器**：`extends LevelEditor`，覆寫下面這些

| 覆寫 | 做什麼 | 一定要嗎 |
| --- | --- | --- |
| `_setup()` | `title`、`maps_dir`（最後要有 `/`）、`play_scene`，用 `add_tool()` 加工具 | 要 |
| `_new_map()` | 一張新地圖 | 要 |
| `_before_test()` | 試玩前把地圖的**複本**交給關卡 | 要 |
| `place(cell)`、`unplace(cell)` | 左鍵放、右鍵拿掉；**確定會改才 `remember()`**，回傳有沒有改到 | 有放東西的工具 |
| `_paint_dab(at)`、`_paint_rect(from, to)`、`_paint_ellipse(from, to)`、`_paint_fill(at)` | 畫地形；`_erasing`＝右鍵（擦）。不用自己 `remember()`；`_paint_fill` 什麼都沒換要回傳 0，這一步才不算。只照格子的話設 `grid_only = true`，用 `brush_cells(at)`、`cells_between(from, to)` | 有畫地形的工具 |
| `_draw_map(canvas)` | 把地圖上的東西畫出來：`canvas.draw_circle(cell_center(cell), …)` | 通常要 |
| `_make_view()` | 地形要用自己的節點畫（TileMapLayer……）時；有 `map` 屬性的話會自動給它 | 選 |
| `check_map()` | 少了什麼不能玩（回傳問題） | 選 |
| `_clear()` | 「清空地形」 | 選 |
| `_map_shown()` | 換了地圖、上一步、改大小之後，更新自己的畫面 | 選 |
| `_build_rows()` | 工具列。`add_row(592)`、`add_row(626)`、`add_row(660)` 三排；`add_file_controls()` 一定要有。**工具超過十個就分類**（看下面） | 選 |
| `_build_pages()` | 多加幾頁：先 `add_page("地圖")`。規則頁一行：`add_form_page("規則", ["hint", "max_moves"])`，改 map 的 `@export` 欄位，上一步、讀檔都會自動更新。自己的面板：`add_page("名字", 面板)`，要改 map 之前呼叫編輯器的 `remember()`，在 `_map_shown()` 重新讀；面板有 `say`、`commit()`、`undo()`、`redo()`、`update_save_button()` 的話會自動用到；有自己存檔鈕（`own_save`）的頁要有 `is_dirty()`、`save()`，試玩前才會問它 | 選 |
| `_used_in_editor(path)`、`_scene_deleted(path)` | 有「一類場景」頁時：編輯器裡還沒存的地方有沒有用到（預設看 `map.snapshot()` 有沒有這個路徑）；刪掉之後更新清單（記得 `super`） | 選 |
| `_level_request(map_path)` | 「做成關卡」：`{"path": 存到哪, "base": 繼承哪個關卡, "values": {節點路徑: {屬性: 資源檔案}}}`，關卡腳本在最上面的節點就寫 `"."` | 選 |
| `_write(path)`、`_read(path)`、`_path_of(text)` | 不存成 `.tres` 時 | 選 |

**工具分類**：`add_tool("敵人", false, false, "角色")` 最後一個是分類（空的＝一直看得到），`_build_rows()` 用 `add_category_rows()` 取代 `add_tool_buttons()`：

```gdscript
var row: HBoxContainer = add_category_rows()                  # 第一排：分類（按 1、2、3……）；第二排：這一類的工具
add_shape_buttons(add_category_box(row, ["地形"]))            # 只在某些分類出現的東西（形狀、下拉選單……）
add_file_controls(add_row(660))
```

其他可以調的（格子大小、筆刷範圍、地圖大小範圍、鏡頭邊界……）在 [level_editor.gd](scripts/level_editor.gd) 最上面的「設定」。自己的編輯器記得放一個 `.tscn`（最上面 `Node2D` 掛腳本）。

## 其他可以拿來用的

| 類別 | 做什麼 |
| --- | --- |
| `LevelEditorForm` | 表單。`LevelEditorForm.fields_of(節點)` 自動讀 `@export`：範圍、單位讀 `@export_range`、選項讀 `@export_enum`、**中文名字讀上面那行 `##` 註解的第一小句**（到第一個「，。：（」為止），整句變成滑鼠停著的說明；`only` 可以只要幾個、照給的順序；`LevelEditorForm.add(GridContainer, 欄位, 值, func(欄位名, 新值))` 變成介面 |
| `LevelEditorScenePage`＋`LevelEditorScenes` | 「一類場景」頁（怪物、棋子）：清單、改數值、勾掛件、預覽、存成一般場景、刪掉（專案裡有檔案用到就不給刪；丟資源回收桶）。看塔防的 `enemy_page.gd`，50 行；一頁好幾類看追逐的 `kind_page.gd`。腳本有 `display_name` 就用它當名字，沒有就存在 metadata。欄位很多設 `form_columns = 2` |
| `LevelEditorFormPage` | 規則頁，用 `add_form_page()` 加 |
| `LevelMaker` | 寫一個繼承某關卡的場景；`save_scene()` 存場景但不弄掉 uid |
| `LevelEditorStyle` | 按鈕顏色 |

`LevelEditorScenes` 的資料夾**第一層的 `.tscn` 全部都算**：測試場景不要放在怪物、掛件的資料夾裡（放子資料夾就好）。

## 地圖變成文字（給 AI 看、畫草稿）

地圖有 `text_letters()`、`text_kind()`、`set_text_kind()`、`text_fields()`（看 `sample_map.gd`）就能轉：

```
godot --headless --path . res://core/level_editor/map_text.tscn -- export res://…/maps/a.tres a.txt
godot --headless --path . res://core/level_editor/map_text.tscn -- import res://…/maps/a.tres a.txt
godot --headless --path . res://core/level_editor/map_text.tscn -- new res://…/maps/b.tres b.txt res://…/scripts/xxx_map.gd
```

地圖是場景（追逐的關卡 `.tscn`）：三個都在最後加地圖的腳本（`res://examples/chase/map_editor/scripts/chase_map.gd`），它要有 `read(路徑)`（static）和 `write(路徑)`。不是欄位的東西（追逐的物件）自己寫 `text_cells()`、`set_text_cells()`、`text_problem()`，看 `chase_text.gd`。可以再寫 `text_help()`（最上面的說明）、`text_warning()`（寫完的提醒，例如走不到）。

寫回去只改不一樣的格子。文字檔放專案外面或用完刪掉。規則這種一般欄位直接改 `.tres` 裡的文字就好。

## 注意

- 存檔是寫進專案資料夾，只有在 Godot 編輯器裡按 F6 才能存
- 編到一半按「重來」會重新載入場景，東西靠 `LevelEditor.session_of()` 留著；自己的變數要留的話：`get: return _session.get("名字", 預設)`、`set(v): _session["名字"] = v`
- 介面的按鈕 `focus_mode` 都是 NONE，不會搶 WASD；自己加按鈕用 `add_button()`、`add_toggle()`
- 測試：在腳本裡載入編輯器場景，用 `call("set_tool", n)`、`call("press", 位置, false)`、`call("release", 位置)`、`call("place", 格子)` 模擬滑鼠，看 `get("map")`；最後 `LevelEditor.forget_sessions()`。參考 `core/tests/scripts/core_test.gd`
