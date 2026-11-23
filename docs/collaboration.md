# 協作規則

組隊做遊戲最常見的問題是**衝突**：兩個人改了同一個檔案，合併時打架。照下面做，大部分衝突都不會發生。

## 1. 照功能分工，每個人只動自己的資料夾

開工前在 `docs/game_overview.md` 填好**分工表**：每個人負責什麼功能、哪個資料夾、分支叫什麼，還有**誰負責主場景**。

- 你的功能放在 `features/<功能名稱>/`，這個資料夾只有你會改
- 先在自己的 `test.tscn` 測好，要放進遊戲時，跟主場景負責人說，由他在 `levels/` 放一個實例
- `core/`、`addons/` 不要改（更新時會整包換掉）
- `shared/` 是共用的，改之前先在組裡講

## 2. `project.godot` 一個人改

按鍵、Autoload、開始場景都在 `project.godot` 裡，**最容易衝突**。常用按鍵起手包已經設好了；真的要新增，先在組裡講，由一個人改。

開始場景、遊戲名稱、製作名單不在 `project.godot`，在 `game_config.tres`（也是一個人改就好）。

## 3. 分支和合併

1. 開工前先拉最新版：`git pull`
2. 每個功能開一個分支：`git checkout -b feature/enemy`
3. **每 20～30 分鐘合併一次**：commit → 切回 main → `git pull` → `git merge feature/enemy` → `git push`
4. 拖越久越容易衝突

不熟 Git 的人：用 GitHub Desktop 也可以，流程一樣。

## 4. 真的衝突了

- `.gd` 腳本、`.md`：照 Git 的提示手動合併
- **`.tscn`、`.tres` 不要手動合併**：選一邊保留（`git checkout --ours` 或 `--theirs`），再把另一邊的小改動在 Godot 裡重做一次
- 不確定的話，先問組員，不要硬按

## 5. 給 AI 的規則

`CLAUDE.md`、`AGENTS.md`、`GEMINI.md` 都寫了：**AI 只能改分工表上屬於你的資料夾，要動別的資料夾、`core/`、`addons/`、主場景或 `project.godot` 會先停下來問你**。AI 最容易一次改一堆檔案，看到它要改別人的東西時，先擋下來。

## 6. 要 commit 的、不要 commit 的

- 要：`.gd`、`.tscn`、`.tres`、**`.uid`**、圖片、音效、`.import`
- 不要：`.godot/`、`build/`、`*.zip`（`.gitignore` 已經設好）
