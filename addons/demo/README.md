# Demo

整合 `audio_manager`、`save_system`、`scene_manager`、`ui_kit` 四個工具的示範場景，讓人一次看到工具彼此怎麼搭配，不是獨立的工具本身。這裡的程式碼可以當範例參考，不用當成正式功能來維護。

## 場景流程

`title_scene.tscn`（主選單）→ `demo_scene.tscn`（遊戲畫面）

專案的 `run/main_scene` 已經指向 `title_scene.tscn`，直接按 F5 執行專案，或開啟其中一個場景後按 F6 單獨測試。

### TitleScene（主選單）

- **開始新遊戲**：`GameSession.start_new_game()` 建立新存檔 → `SceneManager.change_scene()` 切到 DemoScene
- **繼續遊戲**：`GameSession.continue_game()` 讀檔成功才切場景；沒有存檔時這個按鈕會被 disable（用 `SaveManager.has_save()` 判斷）
- **選項**：開啟音量設定面板（`audio_manager` 提供）
- **離開遊戲**：`GameSession.request_quit()`，離開前會自動存檔

### DemoScene（遊戲畫面）

- 進場時用 `AudioManager` 註冊並播放 BGM、註冊兩個 SFX（點擊音效目前沒有實際綁按鈕，扣血音效同上，可當註冊範例看）
- `DemoPlayer`：WASD 移動、按 **B** 觸發扣血測試（`damage_test` 這個 Input Action），扣血時分數 +1 並同步寫進 `GameSession.game_data`
- 血量/分數即時顯示在畫面上方；血量歸零會跳出 `ui_kit` 的死亡選單
- 按 **ESC** 開關 `ui_kit` 的暫停選單，暫停選單的「離開遊戲」按鈕被改成「返回主選單」，會呼叫 `SceneManager.change_scene()` 切回 TitleScene
- `SaveManager.set_autosave_source()` 指到 `GameSession.game_data`，離開遊戲或返回主選單時的存檔都是讀這包資料

## 依賴的 Autoload

`AudioManager`、`SaveManager`、`GameSession`、`SceneManager` 都要設定在 **專案設定 → Autoload**（本專案已經內建設定好，可以在 `project.godot` 裡直接看到，順序要照這個排：`SaveManager` 要在 `GameSession` 前面）。

## 檔案結構

```
addons/demo/
├── Scenes/
│   ├── title_scene.tscn   # 主選單
│   └── demo_scene.tscn    # 遊戲畫面
└── Scripts/
    ├── title_scene.gd
    ├── demo_scene.gd
    └── demo_player.gd     # 示範用角色（血量、移動、扣血）
```

## 想拿這裡的寫法當範本？

想知道「怎麼串起這些工具」的實際寫法，直接看 `Scripts/demo_scene.gd` 和 `Scripts/title_scene.gd` 最快；各工具詳細的 API 說明還是要看各自的 README（[audio_manager](../audio_manager/README.md)、[save_system](../save_system/README.md)、[scene_manager](../scene_manager/README.md)、[ui_kit](../ui_kit/README.md)）。
