# 貢獻指南

這份文件給想要幫忙開發、擴充這個工具庫的人看。如果你只是想「拿工具來用」，請看 [README.md](README.md)。

## 開發環境

- 引擎版本：**Godot 4.7 (stable)**
- 下載連結：https://godotengine.org/download/archive/4.7-stable/
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

## 新增工具時

- 在 `addons/你的工具/` 底下開發，並附上一份 README，說明怎麼安裝、核心 API、注意事項（可參考其他工具的寫法，例如 [scene_manager](addons/scene_manager/README.md)）。
- 如果工具會用到 Autoload，記得在 `project.godot` 裡設定好，讓 `demo` 場景可以直接示範。

## 需求規格

想知道每個工具該做到什麼程度？看這份文件：[工具需求規格連結](https://www.notion.so/3931803c84a480cc826de559676d9597?source=copy_link)
