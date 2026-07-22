# NGDC Game Jam 通用工具庫

社團各屆 Game Jam 共用的 Godot 工具箱，把「存讀檔」「場景切換」「音效/BGM」「常用 UI（血條、暫停/死亡選單、開始/離開按鈕）」這些每次組隊都要重寫的東西直接包好，Jam 開場就能拿去用，把時間留給遊戲本身。

## 🔧 需求環境

- 引擎版本：**Godot 4.7 (stable)**
- 下載連結：https://godotengine.org/download/archive/4.7-stable/
- ⚠️ 請使用同一個版本開啟，避免場景檔案版本不相容

## 🚀 先看一次示範效果

1. Clone 這個專案（或直接下載 zip）
2. 用 Godot 4.7 開啟資料夾內的 `project.godot`
3. 按 F5 執行專案（或開啟 `addons/demo/Scenes/title_scene.tscn` 後按 F6）— 會進入整合了四個工具的主選單 → 遊戲畫面
4. 想知道這個 demo 場景怎麼串起所有工具，看 [addons/demo/README.md](addons/demo/README.md)

## 📁 工具一覽

| 工具 | 說明 | 文件 |
| --- | --- | --- |
| `audio_manager` | BGM / 音效播放與音量控制 | [README](addons/audio_manager/README.md) |
| `save_system` | 存讀檔、新遊戲/繼續遊戲/自動存檔 | [README](addons/save_system/README.md) |
| `scene_manager` | 場景切換（淡入淡出、Loading 畫面） | [README](addons/scene_manager/README.md) |
| `ui_kit` | 常用 UI 元件（血條、暫停/死亡選單、開始/離開按鈕） | [README](addons/ui_kit/README.md) |
| `demo` | 整合以上四個工具的示範場景（主選單 + 遊戲畫面） | [README](addons/demo/README.md) |

## 📦 怎麼把工具用到自己的專案

每個工具都是獨立的資料夾，不需要整包一起拿：

1. 把需要的 `addons/工具名稱/` 資料夾複製到你自己的專案裡
2. 照該工具 README 的「安裝 / 設定」步驟設定 Autoload（大部分工具都是單例，需要在 **專案設定 → Autoload** 加入）
3. 依 README 的 API 說明呼叫即可

工具之間也可以互相搭配（例如 `scene_manager` 切換場景時，讓 `save_system` 在切換前自動存檔），實際搭配範例可以參考 `demo` 場景怎麼寫。

## 🤝 想一起開發這個工具庫？

貢獻流程、PR 規範、分支/合併方式都寫在 [CONTRIBUTING.md](CONTRIBUTING.md)。
