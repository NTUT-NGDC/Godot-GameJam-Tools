# NGDC Game Jam 通用工具庫

用來累積社團各屆共用的 Godot 工具（存檔、UI、場景切換等），
歡迎自由參與開發，一起把社團的技術資產養大 💪

## 🔧 開發環境

- 引擎版本：**Godot 4.7 (stable)**
- 下載連結：https://godotengine.org/download/archive/4.7-stable/
- ⚠️ 請大家統一使用同一個版本，避免場景檔案版本不相容

## 🚀 快速開始

1. Clone 這個專案下來
2. 用 Godot 4.7 開啟資料夾內的 project.godot
3. 開啟 `demo/demo_scene.tscn` 可以看到目前所有工具的示範效果
4. 想開發新工具？看下面「怎麼貢獻」章節

## 📁 專案結構

```
addons/
├── audio_manager/     # 音效管理
├── demo/                  # 整合示範場景
├── save_system/       # 存檔系統
├── scene_manager/     # 場景切換管理
├── ui_kit/            # UI 元件庫
```

每個工具資料夾底下都有自己的 README，請說明怎麼用。

## 🤝 怎麼貢獻

1. 建立自己的分支：`git checkout -b feature/工具名稱`
2. 開發完成後 push，並開 Pull Request 到 main
3. 小改動可自行 merge；新增功能建議找人 review 一下

不熟 Git？看這裡：[Git 教學影片連結](https://youtu.be/9HyXQdwecOM)

### PR 標題格式

```
[工具名稱] 做了什麼事
```

範例：
- `[存檔系統] 新增基本存讀檔功能`
- `[UI Kit] 新增按鈕與對話框元件`
- `[場景管理] 修正切換時重複觸發的問題`

### PR 描述請包含

- **做了什麼**：簡單描述完成的功能
- **怎麼測試**：說明如何確認功能正常運作
- **需要注意的地方**：沒有就填「無」

（開 PR 時 GitHub 會自動帶出範本，照著填就好）

### 合併方式

本 repo 統一使用 **Squash and merge**，PR 合併後 main 上只會留下一條乾淨的紀錄，不用擔心開發過程 commit 訊息寫得亂。

> 因為 squash merge 會把 PR 標題變成 main 上的 commit 訊息，記得標題要照上面的格式寫清楚。

## 📌 需求規格

想知道每個工具該做到什麼程度？看這份文件：[工具需求規格連結](https://www.notion.so/3931803c84a480cc826de559676d9597?source=copy_link)
