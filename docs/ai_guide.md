# 給 AI 的說明（AI Guide）

這份文件給 AI 助手（Claude Code、Codex、Gemini CLI……）讀。`CLAUDE.md`、`AGENTS.md`、`GEMINI.md` 都指向這裡。
人也可以讀：想知道專案裡「已經有什麼、不要重寫什麼」，看這份就對了。

**有 `docs/architecture.md` 的話先讀它**，跟這份不一樣的以它為準；使用者說不要照的也不用照。只有「只改自己的資料夾」和 Git 那幾條不能省（`AGENTS.md` 的底線）。

## 這是什麼專案

北科遊戲研究社「每週協作專案」的 Godot 起手包。2～3 人一組，一個晚上做出一款小遊戲。

- 引擎：**Godot 4.7.2**，只用 **GDScript**，2D，要能匯出 **Web**（Compatibility 渲染、畫面 1280×720）
- 美術用簡單幾何圖形；介面文字、註解用**繁體中文**
- 字型：`core/fonts/Cubic_11.woff2`（俐方體，像素字），字的大小用 11 的倍數；**不要用 emoji**（Web 版會變方框）

## ⚠️ 最重要的規則：只改自己的資料夾

這是多人協作的專案，**一次改一堆檔案最容易造成衝突**。

1. 先看 `docs/game_overview.md` 的**分工表**，找到現在這個人負責的功能和資料夾（還沒填的話，先請使用者說他負責哪裡，幫他填好再開始；名字不知道就問，不要自己編）
2. **只修改分工表上屬於這個人的資料夾**（通常是 `features/<功能名稱>/`）
3. 要動下面這些，**先停下來問使用者**，不要直接改：
   - 別人的資料夾
   - `core/`（起手包）、`addons/`（技術積木）：更新時會整包換掉，改了會不見
   - 主場景（專案最上層的 `levels/`）：由一個人負責組裝
   - `project.godot`（按鍵、Autoload、開始場景都在裡面，最容易衝突）
   - `shared/`：大家共用的東西
4. 新功能做成**獨立場景**，放在 `features/<功能名稱>/`，附一個 `test.tscn` 可以單獨測試；要放進遊戲時，交給主場景負責人在 `levels/` 放一個實例

## 資料夾

```
core/          起手包（不要改）
addons/        技術積木（不要改），每週一包，從當週的積木 repo 複製進來
features/      每個功能一個資料夾，一個人負責
  <功能名稱>/
    <功能名稱>.tscn   場景直接放
    scripts/          腳本
    data/             資料（.tres）
    test.tscn         自己測試用
levels/        主場景，指定一個人負責組裝
shared/        大家都會用的東西（共用素材、常數），改之前先在組裡講
docs/          遊戲概要、分工表、這份說明
game_config.tres   遊戲名稱、關卡（Levels）、Credits 名單
```

## 已經有的功能（不要重寫）

| 功能 | 怎麼用 | 在哪 |
| --- | --- | --- |
| 標題畫面 | 開始遊戲／設定／製作名單／離開。遊戲名稱、關卡讀 `game_config.tres` | `core/screens/title_screen.tscn`（專案主場景） |
| 暫停選單 | **自動加進每個遊戲場景**，按 Esc 開關：繼續／重來／設定／回標題 | `core/screens/pause_menu.tscn` |
| 設定 | 音樂、音效音量（會記住）、全螢幕 | `core/screens/settings_panel.tscn` |
| 勝利／失敗畫面 | `GameFlow.win("訊息")`、`GameFlow.lose("訊息")`，會暫停遊戲、顯示再玩一次／回標題；「回標題」可以換成別的：`GameFlow.set_title_button("回編輯器", 要做的事)`、`GameFlow.reset_title_button()`；暫時不要暫停選單（藏起「選單」、Esc 沒反應）：`GameFlow.set_pause_enabled(false)`，換場景就恢復 | `core/screens/` |
| 關卡 | 把關卡場景拖進 `game_config.tres` 的 Levels。一關：開始遊戲直接進去；兩關以上：先到**關卡選擇**，勝利畫面有**下一關**，過關自動記住（`LevelProgress`）。換關卡不要自己寫 | `core/screens/level_select_screen.tscn` |
| 製作名單 | 名單寫在 `game_config.tres` 的 Credits（一行一個「職位：名字」） | `core/screens/credits_screen.tscn` |
| 換場景（有轉場） | `SceneManager.change_scene("res://...")`、`SceneManager.reload()`。**不要直接用 `get_tree().change_scene_to_file()`** | `core/scene_manager/` |
| BGM／音效 | 場景裡放 `SoundBank` 節點登記名字，`AudioManager.play_bgm("名字")`、`AudioManager.play_sfx("名字")` | `core/audio_manager/` |
| 存讀檔 | `SaveManager.save({...})`、`SaveManager.load_data()`；`GameSession.game_data` | `core/save_system/` |
| 分數 | `score_display.tscn` 拖進 CanvasLayer，`add(10)` 加分；group `score` | `core/hud/` |
| 計時 | `timer_display.tscn`，正數或倒數，倒數到 0 發 `time_up`（可設定時間到就輸／贏） | `core/hud/` |
| 血條 | `health_bar.tscn`，`damage(10)`、`heal(10)`，到 0 發 `died`（可設定死掉就輸） | `core/hud/` |
| 鏡頭 | `follow_camera.tscn` 拖進關卡：跟隨玩家（group `player`）或固定位置；可設長方形邊界（大小、偏移），編輯器裡會畫框。**不要在角色身上另外放 Camera2D**。策略、塔防用 `pan_camera.tscn`：WASD／方向鍵、滑鼠到邊緣、中鍵拖曳移動，滾輪縮放（可設要按 Ctrl），可設邊界（`set_limit_rect()`） | `core/camera/` |
| 關卡編輯器的底 | 要讓人「在遊戲裡畫關卡、放東西」就 `extends LevelEditor`：分頁、畫筆、上一步、存讀檔、試玩、做成關卡都有了，只寫自己的工具。從 `core/level_editor/sample/` 抄，步驟看 [README](../core/level_editor/README.md)。自動表單 `LevelEditorForm`、怪物／棋子這種場景頁 `LevelEditorScenePage` 也在裡面，**不要自己重寫編輯器** | `core/level_editor/` |
| 遊戲設定 | `GameConfig.current().game_name`、`.level_paths()`、`.credits` | `game_config.tres` |

### 技術積木（`addons/`）

每週的積木在各自的 repo（例如尋路：NTUT-NGDC/Pathfinding-Template），各組把 `addons/ngdc_<主題>/` 複製進來。**`addons/` 裡有積木的話，先讀它的 README，用現成的積木，不要自己重寫。**

### 已經設定好的按鍵（`project.godot`，不用再加）

| 動作名稱 | 按鍵 |
| --- | --- |
| `move_up`／`move_down`／`move_left`／`move_right` | WASD、方向鍵 |
| `run` | Shift（跑步） |
| `interact` | E |
| `attack` | J、空白鍵 |
| `pause` | Esc（暫停選單已經在用） |
| `skill_1`／`skill_2`／`skill_3` | 1、2、3 |
| `mouse_left`／`mouse_right` | 滑鼠左鍵、右鍵 |
| `debug_1`～`debug_5` | F1～F5（除錯用，積木的除錯顯示會用到） |

讀移動：`Input.get_vector("move_left", "move_right", "move_up", "move_down")`

### 物理層（已經命名好）

| 層 | 名稱 | 用途 |
| --- | --- | --- |
| 1 | 擋路 | 牆、障礙物；角色身體撞這層 |
| 2 | 擋視線 | 視線射線只檢查這層 |
| 3 | 玩家 | |
| 4 | 敵人 | |
| 5 | 互動 | 可以按 E 互動的範圍 |

## 寫程式的規則

- GDScript 一律寫**靜態型別**（`var hp: int = 10`、`func hit() -> void:`），不要有編輯器警告
- 檔案、資料夾、變數 `snake_case`，類別 `PascalCase`，場景和腳本同名
- 場景之間用 **signal** 溝通，不要用很長的節點路徑去抓別人的節點；要找全場唯一的東西用 group
- 給人調的數字用 `@export`，加 `##` 中文說明（會顯示在檢查器），數值用 `@export_range`
- 移動、計時都乘 `delta`
- 要讓人改的資料用 `.tres`（不要用 `.json`／`.txt`，Web 匯出不會帶上）
- `.uid` 檔要 commit（Godot 4.4 之後腳本旁邊都有），`.godot/` 不要
- **改檔案前先關 Godot**：Godot 編輯器開著的時候改了磁碟上的檔案，Godot 會跳出「要不要重新載入」，使用者按錯就會用舊版蓋掉你的修改。所以改任何檔案（`.gd`／`.tscn`／`.tres`／`project.godot`）前，Godot 開著的話先正常關閉（不要強制結束，有沒存的修改 Godot 會先問），改完再用編輯器打開專案；你沒辦法自己關、開 Godot 的話，請使用者先關掉，改完再開。GDScript 不用編譯，重開很快。**只是新增檔案**（沒有改到現有的）不用關。使用者說可以、說關好了、或說他開的是別的專案，就直接做，不要再問一次。`--headless` 的驗證在編輯器開著時也可以跑

## 改完怎麼驗證

改完**一定要跑過**再說做好了。`godot` 換成這台電腦上 Godot 4.7.2 的執行檔路徑；`--headless` 不會開視窗，`--fixed-fps 60` 讓它不等時間、跑得快：

1. 新增了檔案或 `class_name`：先讓 Godot 認得（也會產生 `.uid`；第一次跑會有幾行字型的 `ERROR`，再跑一次就沒有）
   `godot --headless --path . --import`
2. 跑你改的場景約 5 秒，**看輸出有沒有 `ERROR`、`WARNING`**（有錯誤 exit code 也會是 0，一定要看文字）
   `godot --headless --fixed-fps 60 --path . res://features/<功能名稱>/test.tscn --quit-after 300`
3. 改了起手包（`core/`）：`godot --headless --fixed-fps 60 --path . res://core/tests/core_test.tscn`，全部過會印「全部 PASS」，失敗時 exit code 是 1

- 不要用 `--check-only` 檢查腳本，`--script` 也一樣：不會載入 Autoload（GameFlow……），會報假的錯誤。要臨時試東西就做一個場景掛腳本，跑那個場景，試完刪掉
- 一次只跑一個 Godot，不要同時開好幾個
- headless 看不到畫面：跟畫面、手感有關的，請使用者按 F6 試玩

## 給使用者的建議

- 最後一行寫**改了哪些檔案**，方便他們合併
- 使用者講得模糊（「做一個塔防」）、或說「先問我問題」：照 [ai_questions.md](ai_questions.md) 問，不要直接動手
- 使用者大多沒有程式背景：做好了怎麼回報、怎麼教他用編輯器，照 [ai_card.md](ai_card.md) 的「做一張卡」；他問了才講程式
- 做完一張卡、或每 20 分鐘，照 [ai_git.md](ai_git.md) 帶他「同步」
