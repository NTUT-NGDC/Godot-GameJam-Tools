# UI Kit

## 功能說明

拖入 `Scenes` 資料夾內對應的 `.tscn`，以及其附加的 `Scripts` 即可使用。

### UI.tscn

內含暫停選單 PauseMenu、死亡選單 DeathMenu。

**PauseMenu（暫停選單）**
按下 ESC 暫停遊戲，再按一次 ESC 回到遊戲。包含「離開遊戲」與「繼續遊戲」按鈕。

**DeathMenu（死亡選單）**
角色血量歸零後，間隔 0.1 秒跳出。包含「重來遊戲」（重新開始當前場景）與「離開遊戲」按鈕。
需要在 UI 節點的 `player_path` 欄位，把玩家節點拖進去（玩家腳本需要有 `player_died` signal），才能觸發死亡選單。

### UI_testbot

UI 測試用機器人，會不停在畫面中旋轉，且包含簡易的扣血設計。
放在 `Tests` 資料夾（測試用，非正式功能腳本）。
完整展示可參考 `Tests/UIKitDemo.tscn`（開啟後用「執行目前場景」測試，專案本身的 main_scene 維持空白）。

### HealthBar

血量條。
需要在 HealthBar 節點的 `player_path` 欄位，把玩家節點拖進去（玩家腳本需要有 `hp` 屬性），才能顯示血量。

### Textures 資料夾

現階段包含血量條的三張圖片，資料夾內有附 PSD 檔案，可自由修改。

### Button_QUIT

離開遊戲按鈕。按下去後遊戲就會結束。

### Button_Start

開始遊戲按鈕，適用於遊戲開場主選單，按下後即可進入遊戲。

- 需要在 Button_Start 節點的 `target_scene` 欄位，把想要的遊戲主場景拖進去。
- 若 `target_scene` 留空，按下去會改成重新載入目前場景（例如 `Tests/UIKitDemo.tscn` 就是用這個預設行為）。
