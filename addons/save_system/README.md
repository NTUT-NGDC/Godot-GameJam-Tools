# Save System

給 Game Jam 遊戲用的輕量存檔系統。只處理最常見的三件事：**開始新遊戲**、**繼續遊戲**、**離開遊戲時自動存檔**，存檔內容是任意 `Dictionary`，用 JSON 存在 `user://saves/` 底下。

## 安裝 / 設定

1. 把 `addons/save_system/` 整個資料夾複製到你的專案裡。
2. 打開 **專案設定 → Autoload**，依序加入：
   - `SaveManager` → `addons/save_system/Scripts/SaveManager.gd`
   - `GameSession` → `addons/save_system/Scripts/GameSession.gd`

   ⚠️ **順序很重要**：`GameSession` 會用到 `SaveManager`，一定要排在後面。

3. 打開 `GameSession.gd`，把 `DEFAULT_DATA` 改成你遊戲實際需要的欄位：

   ```gdscript
   const DEFAULT_DATA := {
       "score": 0,
       "level": 1,
   }
   ```

## 三個核心流程

遊戲流程幾乎都圍繞這三個 `GameSession` 的函式：

### 開始新遊戲（初始化存檔）

```gdscript
GameSession.start_new_game()
```

用 `DEFAULT_DATA` 覆寫存檔，並把資料放進 `GameSession.game_data`。適合在主選單「開始新遊戲」按鈕裡呼叫。

### 繼續遊戲（讀取存檔）

```gdscript
if GameSession.continue_game():
    # 讀檔成功，GameSession.game_data 已經是存檔內容
    get_tree().change_scene_to_file("res://scenes/game.tscn")
else:
    # 沒有存檔（理論上不該發生，UI 應該先用 has_save() 擋掉）
    pass
```

主選單的「繼續遊戲」按鈕建議先用 `SaveManager.has_save()` 檢查，沒存檔就把按鈕 disable 掉。

### 離開遊戲（自動存檔）

```gdscript
GameSession.request_quit()
```

這是離開遊戲的**唯一入口**——不管是遊戲內的「離開遊戲」按鈕呼叫這個函式，還是玩家直接按視窗右上角的 X，都會先把 `GameSession.game_data` 存檔，才真正呼叫 `quit()`。視窗 X 的攔截已經在 `GameSession._ready()` / `_notification()` 裡處理好了，不用額外接線。

遊戲過程中要更新的資料（分數、關卡進度…）直接改 `GameSession.game_data` 這個 Dictionary 就好，不用手動存檔，等離開時會自動寫入。如果想在遊戲中途手動存一次，也可以呼叫：

```gdscript
GameSession.save_and_return_to_menu()  # 存檔 + 返回主選單（可依需求改成自己想要的場景）
```

## 進階：自動存檔（每隔一段時間存一次）

如果除了「離開遊戲時存檔」以外，還想要每隔幾秒自動存一次（避免當機、跳電等意外），可以設定 `SaveManager`：

1. 選取 Autoload 裡的 `SaveManager` 節點，把 `autosave_interval`（秒）設成大於 0 的值。
2. 在遊戲場景 `_ready()` 裡告訴 `SaveManager` 要存什麼資料：

   ```gdscript
   func _ready() -> void:
       SaveManager.set_autosave_source(func(): return GameSession.game_data)
   ```

   之後每隔 `autosave_interval` 秒，`SaveManager` 就會呼叫這個 Callable 拿到最新資料並存檔。

## SaveManager API（底層存讀檔）

如果不想用 `GameSession` 的流程，也可以直接操作 `SaveManager`：

| 函式 | 說明 |
| --- | --- |
| `save(data: Dictionary, slot: int = 0) -> bool` | 把 `data` 存到指定槽位，成功回傳 `true` |
| `load(slot: int = 0) -> Dictionary` | 讀取指定槽位，沒有存檔或損毀時回傳空 `Dictionary`（不會當機） |
| `has_save(slot: int = 0) -> bool` | 檢查指定槽位是否有存檔 |
| `delete_save(slot: int = 0) -> bool` | 刪除指定槽位的存檔 |
| `get_all_save_slots(max_slots: int = 10) -> Array[int]` | 取得所有有存檔的槽位編號，適合用來畫存檔列表 UI |

存檔預設都是 `slot = 0`，如果遊戲需要多存檔槽，呼叫時自己帶 `slot` 編號即可。

## 範例場景

`Tests/Scenes/SaveSystemDemo.tscn`（腳本在 `Tests/Scripts/SaveSystemDemo.gd`）是一個可以直接執行的範例，示範上面三個流程：

- **開始遊戲** → `GameSession.start_new_game()`
- **繼續遊戲** → `GameSession.continue_game()`（沒存檔時按鈕會自動 disable）
- **分數 +1** → 模擬遊戲中修改 `game_data`
- **離開遊戲** → `GameSession.request_quit()`

在編輯器打開這個場景後按 F6 就能直接測試整套存讀檔流程。

## 存檔位置

存檔實際寫在 `user://saves/slot_<編號>.json`，對應到各平台的使用者資料目錄（Windows 大約在 `%APPDATA%/Godot/app_userdata/<專案名稱>/saves/`），不會混進專案原始碼裡。
