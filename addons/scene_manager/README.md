# Scene Manager

統一處理遊戲場景（關卡）之間的切換，避免每個人各寫一套轉場邏輯。全域單例（Autoload），任何場景都能直接呼叫。

## 安裝 / 設定

1. 把 `addons/scene_manager/` 整個資料夾複製到你的專案裡。
2. 打開 **專案設定 → Autoload**，加入：
   - `SceneManager` → `addons/scene_manager/Scenes/SceneManager.tscn`

   （這個專案已經內建設定好了，`project.godot` 裡可以直接看到。）

## 核心 API

```gdscript
SceneManager.change_scene(scene_path: String, fade_time: float = -1.0, use_loading_screen: bool = false, transition: SceneManager.TransitionType = SceneManager.TransitionType.FADE) -> void
```

| 參數 | 說明 |
| --- | --- |
| `scene_path` | 目標場景的資源路徑，例如 `"res://scenes/level_2.tscn"` |
| `fade_time` | 淡入淡出秒數，`< 0` 表示使用 `default_fade_time`（預設 0.4 秒） |
| `use_loading_screen` | 場景較大時開啟，切換中會用 `ResourceLoader` 非同步載入並顯示 Loading 畫面 + 進度條 |
| `transition` | 轉場效果：`FADE`（黑幕淡入淡出，預設）或 `INSTANT`（直接切換，不做效果） |

最簡單的用法：

```gdscript
SceneManager.change_scene("res://scenes/level_2.tscn")
```

大場景搭配 Loading 畫面：

```gdscript
SceneManager.change_scene("res://scenes/big_level.tscn", 0.6, true)
```

## 用數字代替路徑：scene_list

不想每次呼叫都打完整的 `res://` 路徑的話，可以在 Inspector 選取 Autoload 裡的 `SceneManager` 節點，把要用到的場景依序拖進 `Scene List` 這個陣列，之後就能直接用索引（數字）切換：

```gdscript
SceneManager.change_scene_by_index(1)  # 等同 change_scene(scene_list[1])
```

`fade_time`、`use_loading_screen`、`transition` 這幾個參數用法跟 `change_scene()` 完全一樣。索引順序自己決定，例如習慣上可以讓 `0` = 主選單、`1` = 第一關⋯⋯依此類推。索引超出範圍時會印錯誤訊息並取消切換，不會讓遊戲當掉。

這個專案內建的 `SceneManager.tscn` 已經預設了 `scene_list = [TestA, TestB]`，方便直接測試；複製到你自己的專案後記得改成你的場景。

## 其他 API

| 函式 / 屬性 | 說明 |
| --- | --- |
| `change_scene_by_index(index, fade_time, use_loading_screen, transition) -> void` | 跟 `change_scene()` 一樣,但用 `scene_list` 的索引代替路徑字串 |
| `is_transitioning() -> bool` | 是否正在切換場景中，可用來讓 UI 擋按鈕、顯示轉場圖示 |
| `default_fade_time` (export) | 沒有指定 `fade_time` 時使用的預設淡入淡出秒數 |
| `fade_color` (export) | 轉場黑幕的顏色，預設黑色，也可以改成白色閃屏等效果 |
| `scene_list` (export) | 場景清單，在 Inspector 拖入場景後，就能用索引呼叫 `change_scene_by_index()` |
| `scene_change_started(scene_path)` (signal) | 開始切換場景時發出 |
| `scene_change_finished(scene_path)` (signal) | 切換完成（新場景已經 `_ready()` 且淡出結束）時發出 |
| `loading_progress_updated(progress)` (signal) | `use_loading_screen = true` 時，載入進度 0.0 ~ 1.0 |

## 防止連續觸發

`change_scene()` 呼叫時會先檢查是否已經在切換中，如果是，會直接忽略這次呼叫並在 Output 印出警告，不會造成重複呼叫或跳轉錯誤。轉場期間也會用一層全螢幕的 `ColorRect`（`mouse_filter = STOP`）擋住畫面點擊，玩家連續狂點按鈕也不會觸發第二次切換。

## 範例場景

`Tests/Scenes/SceneManager_TestA.tscn` 和 `SceneManager_TestB.tscn` 是一組可以互相切換的範例場景：

- **前往場景 B / 返回場景 A** → 示範基本的 `change_scene()`
- **用索引 change_scene_by_index(...)** → 示範用數字代替路徑切換
- **連續快速觸發測試** → 在同一畫格內連續呼叫 5 次 `change_scene()`，驗證只會真的切換一次
- **返回場景 A（顯示 Loading 畫面）** → 示範 `use_loading_screen = true`

在編輯器打開 `SceneManager_TestA.tscn` 後按 F6 就能直接測試整套切換流程。

## 注意事項

- `SceneManager` 的轉場黑幕圖層是 `CanvasLayer`（`layer = 128`），會蓋在所有場景 UI 之上；如果你的專案裡有更高層的 UI（例如全域彈窗），要注意 layer 順序不要被蓋住。
- `process_mode` 設成 `ALWAYS`，就算遊戲暫停中（`get_tree().paused = true`）呼叫 `change_scene()` 也能正常轉場。
- `Tests` 資料夾內的文件可以隨意刪除，不影響本工具使用。
