# 貢獻指南

這份文件給想要幫忙開發、擴充這個工具庫的人看。如果你只是想「拿工具來用」，請看 [README.md](README.md)。

## 開發環境

- 引擎版本：**Godot 4.7.2 (stable)**
- 下載連結：https://godotengine.org/download/archive/4.7.2-stable/
- ⚠️ 請大家統一使用同一個版本，避免場景檔案版本不相容

## 開發流程

1. 建立自己的分支：`git checkout -b feature/工具名稱`
2. 開發完成後 push，並開 Pull Request 到 main
3. 小改動可自行 merge；新增功能建議找人 review 一下

不熟 Git？看這裡：[Git 教學影片連結](https://youtu.be/9HyXQdwecOM)

## PR 標題格式

```
[工具名稱] 做了什麼事
```

範例：
- `[存檔系統] 新增基本存讀檔功能`
- `[UI Kit] 新增按鈕與對話框元件`
- `[場景管理] 修正切換時重複觸發的問題`

## PR 描述請包含

- **做了什麼**：簡單描述完成的功能
- **怎麼測試**：說明如何確認功能正常運作
- **需要注意的地方**：沒有就填「無」

（開 PR 時 GitHub 會自動帶出範本，照著填就好）

## 合併方式

本 repo 統一使用 **Squash and merge**，PR 合併後 main 上只會留下一條乾淨的紀錄，不用擔心開發過程 commit 訊息寫得亂。

> 因為 squash merge 會把 PR 標題變成 main 上的 commit 訊息，記得標題要照上面的格式寫清楚。

## 專案結構

這個 repo 是**起手包**（GitHub Template repository），各組按 Use this template 開自己的 repo。

- `core/`：起手包（每週共用，只做一次）：畫面流程、轉場、音效、存檔、HUD、鏡頭、關卡編輯器的底、遊戲設定檔
- `addons/`：留空。每週的**技術積木**在各自的 repo（例如 [Pathfinding-Template](https://github.com/NTUT-NGDC/Pathfinding-Template)），裡面是這個起手包＋`addons/ngdc_<主題>/`＋範例；各組把積木資料夾複製進自己的專案就能用
- `features/`、`levels/`、`shared/`：留給各組，保持空的
- `docs/`：給組員和 AI 讀的說明（`ai_guide.md` 要跟著功能更新）
- `_dev/`：開發用的工具（截圖等），不會匯出

## 新增功能時

- 起手包的東西放 `core/<功能>/`（只放每週都用得到的通用東西，某一週的主題放到那週的積木 repo）；資料夾、檔名一律 `snake_case`，場景直接放、腳本放 `scripts/`、資料放 `data/`
- GDScript 一律**靜態型別**，不要有編輯器警告；`@export` 加 `##` 中文說明
- 要跟玩法無關：用 `@export` 調參數、用 signal 通知事件，彼此不寫死
- 附自動測試（`core/tests/`），用 headless 跑：`godot --headless --fixed-fps 60 --path . res://core/tests/core_test.tscn`，失敗時 exit code 非 0
- 更新 `docs/ai_guide.md`：有什麼、怎麼用、不要重寫什麼
- 會用到 Autoload 的話，在 `project.godot` 設定好

## 需求規格

想知道每個工具該做到什麼程度？看這份文件：[工具需求規格連結](https://www.notion.so/3931803c84a480cc826de559676d9597?source=copy_link)
