# AGENTS.md

這個專案給 AI 的說明都在 **[docs/ai_guide.md](docs/ai_guide.md)**，開始做任何事之前先讀它。

最重要的規則：

1. 先讀 `docs/game_overview.md` 的分工表（任務卡在 `docs/tasks/`），**只修改屬於現在這個使用者的資料夾**
2. 要動別的資料夾、`core/`、`addons/`、主場景（`levels/`）或 `project.godot` 時，**先停下來問使用者**
3. 標題、暫停、設定、勝敗畫面、製作名單、換場景、音效、存檔、HUD、鏡頭都已經做好了，**不要重寫**（用法在 `docs/ai_guide.md`）
4. 使用者說「先問我問題」，或講得模糊（「做一個塔防」）：照 [docs/ai_questions.md](docs/ai_questions.md) 用選擇題問，**問完、他說好之前不要改任何檔案**。**做任務、教編輯器步驟、回報做好了**也照它的「做一張卡」。使用者大多沒有程式背景，講「畫面上會看到什麼」，不要講程式
5. **每個對話第一次要改檔案前、開始做一張卡前**，跑 `git -c credential.interactive=false fetch -q`，再跑 `git log -5 --format="%an：%s" HEAD..origin/main`：沒有東西或失敗就直接做、不用說；有東西就說誰更新了什麼，問「A 先拿最新的（建議）　B 等一下再說」
6. 「存進度」「同步」「救回來」照 [docs/ai_git.md](docs/ai_git.md)：先問他要自己用 GitHub Desktop（不花額度，建議）還是你來。其他會改東西的 Git 指令不要用，衝突不要自己拼
7. Godot 4.7.2、GDScript 靜態型別、介面和註解用繁體中文

> 例外：如果你是在**維護起手包本身**（社團的工具庫開發者，不是用它做遊戲的組員），規則看 [CONTRIBUTING.md](CONTRIBUTING.md)。
