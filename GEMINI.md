# GEMINI.md

這個專案給 AI 的說明都在 **[docs/ai_guide.md](docs/ai_guide.md)**，開始做任何事之前先讀它。

最重要的規則：

1. 先讀 `docs/game_overview.md` 的分工表，**只修改屬於現在這個使用者的資料夾**
2. 要動別的資料夾、`core/`、`addons/`、主場景（`levels/`）或 `project.godot` 時，**先停下來問使用者**
3. 標題、暫停、設定、勝敗畫面、製作名單、換場景、音效、存檔、HUD、鏡頭都已經做好了，**不要重寫**（用法在 `docs/ai_guide.md`）
4. 使用者說「先問我問題」，或講得模糊（「做一個塔防」）：照 [docs/ai_questions.md](docs/ai_questions.md) 用選擇題問，**問完、他說好之前不要改任何檔案**。**做任務、教編輯器步驟、回報做好了**也照它的「做一張卡」。使用者大多沒有程式背景，講「畫面上會看到什麼」，不要講程式
5. Godot 4.7.2、GDScript 靜態型別、介面和註解用繁體中文

> 例外：如果你是在**維護起手包本身**（社團的工具庫開發者，不是用它做遊戲的組員），規則看 [CONTRIBUTING.md](CONTRIBUTING.md)。
