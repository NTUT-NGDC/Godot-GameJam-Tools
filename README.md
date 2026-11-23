# NGDC Godot 起手包（Godot-GameJam-Tools）

北科遊戲研究社「每週協作專案」和 Game Jam 共用的 Godot 起手包。

標題畫面、暫停選單、設定、勝利／失敗畫面、製作名單、轉場、音效、存檔、HUD、鏡頭這些每次都要重做的東西都做好了。**不用叫 AI 重寫，額度和時間留給你們的玩法。**

每週還會有一包**技術積木**，拖進場景、改檢查器就能用，沒有 AI 也能組出遊戲。積木和範例在各自的 repo：

| 週次 | 主題 | Repo |
| --- | --- | --- |
| W3 | 尋路 | [Pathfinding-Template](https://github.com/NTUT-NGDC/Pathfinding-Template) |

想直接從範例改：用那週的 repo 當 Template 開你們組的 repo（裡面已經有這個起手包）。已經開好 repo 了：把它的 `addons/ngdc_<主題>/` 整個資料夾複製進你們的 `addons/`。

## 需要準備

| 項目 | 版本 | 說明 |
| --- | --- | --- |
| Godot | **4.7.2**（標準版，非 .NET） | [下載頁面](https://godotengine.org/download/archive/4.7.2-stable/)。請用這個版本，其他版本可能打不開專案 |
| Godot 匯出模板 | 4.7.2 | 匯出網頁版需要，在 Godot 裡「編輯器 → 管理匯出模板」下載 |
| GitHub 帳號 | | 組隊協作用 |

> 上課時教室網路慢，Godot 和匯出模板會放在社課的 USB 裡。

## 開始

1. **一組一個人**按上方綠色的 **Use this template → Create a new repository**，開你們組的 repo，再把組員加成 Collaborator
2. 每個人 clone 下來，用 Godot 匯入 `project.godot`
3. 按 `F5` 跑一次：標題 → 開始遊戲 → 按 Esc 暫停，確認都正常
4. 全組一起填 **[docs/game_overview.md](docs/game_overview.md)**：一句話（經典玩法＋變化）、分工表
5. 開工！

## 要改的地方

| 想改什麼 | 改哪裡 |
| --- | --- |
| 遊戲名稱、標語、按「開始遊戲」進去的場景、製作名單 | 雙擊 **`game_config.tres`**，在檢查器改 |

| 你負責的功能 | `features/<功能名稱>/`（只改你自己的資料夾） |
| 主場景 | `levels/`（指定一個人負責） |
| 標題畫面的背景圖、字的顏色 | `core/screens/title_screen.tscn` 的檢查器（只改外觀） |

贏了、輸了：程式裡呼叫 `GameFlow.win("訊息")`、`GameFlow.lose("訊息")`，或在檢查器把 signal 連過去。

## 資料夾

| 資料夾 | 內容 |
| --- | --- |
| `core/` | 起手包，**不要改**（更新時整包換） |
| `addons/` | 技術積木，**不要改**（從每週的積木 repo 複製進來，更新時整包換） |
| `features/` | 每個功能一個資料夾、一個人負責 |
| `levels/` | 主場景，一個人負責組裝 |
| `shared/` | 大家都會用的東西，改之前先在組裡講 |
| `docs/` | 遊戲概要、分工表、協作規則、給 AI 的說明 |

## ⚠️ 協作規則（一定要看）

詳細在 **[docs/collaboration.md](docs/collaboration.md)**，重點：

- **每個人只動自己的資料夾**；主場景、`project.godot`、`game_config.tres` 由一個人改
- **每 20～30 分鐘合併一次**，開工前先 `git pull`
- `.tscn`、`.tres` 衝突了不要手動合併：選一邊保留，再把另一邊的小改動重做
- `.uid` 檔要 commit

## 用 AI 的話

`CLAUDE.md`、`AGENTS.md`、`GEMINI.md` 會讓 Claude Code、Codex、Gemini CLI 自動讀到 **[docs/ai_guide.md](docs/ai_guide.md)**：已經有哪些功能、怎麼用、只能改哪些資料夾。

下指令時講清楚：用哪個現成的東西、要做什麼、**不要重寫什麼**。例如：

> 專案裡已經有 `addons/ngdc_pathfinding` 的生怪器和尋路地圖（說明在它的 README）。幫我在 `features/slow_tower/` 加一種緩速塔：範圍內的敵人速度減半，持續 2 秒。不要重寫生怪器。

## 上傳作品

1. 「專案 → 匯出」，選 **Web**，按「匯出專案」，存到 `build/index.html`
2. 把 `build` 資料夾裡的檔案全部壓成一個 zip
3. 上傳到 itch.io（Kind of project 選 HTML），再提交到社團的 Jam：

**🎮 [115-1 北科遊戲研究社交流會作品集](https://itch.io/jam/ntut-ngdc-meetup-115-1)**

## 起手包裡的工具

| 工具 | 說明 |
| --- | --- |
| [scene_manager](core/scene_manager/README.md) | 換場景（淡入淡出、Loading 畫面） |
| [audio_manager](core/audio_manager/README.md) | BGM／音效、音量記住 |
| [save_system](core/save_system/README.md) | 存讀檔 |

想幫忙開發起手包：看 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 授權

- 字型：俐方體 11 號（Cubic 11），SIL Open Font License 1.1，授權全文在 `core/fonts/Cubic_11_OFL.txt`
