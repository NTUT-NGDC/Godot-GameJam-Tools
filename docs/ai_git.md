# 存進度、同步、救回來（給 AI 讀）

使用者大多不會 Git，帶他照下面做。**只做這三件事，步驟以外的 Git 指令不要自己想。** 大家都直接在 `main` 上，不開分支（專案已經在別的分支上就留在那個分支，把下面的 `main` 換成它）。

跟使用者說話時不要講 commit、merge、HEAD 這些字，講「存好了」「跟大家同步好了」「小明改了門」。

## 不可以

`push --force`、`reset`、`clean`、`rebase`、`checkout .`、`restore .`、`add .`、`add -A`、`commit -a`、`stash drop`／`stash clear`、刪分支、改 `.git/`。看到奇怪的狀況（正在合併、detached HEAD、步驟裡沒寫的錯誤）：**停下來**，把 `git status` 的內容翻成一句話告訴使用者，叫他找社長或組裡有高階 AI 的人。東西還在電腦上，不動就不會不見。

## 先問誰來做

這個對話第一次要「存進度」或「同步」時問一次，之後都照他選的，不要再問：

> A 你自己用 GitHub Desktop（不花 AI 額度，建議）　B 我幫你　C 這次先不要

- **A**：照最下面「用 GitHub Desktop」教他。**先跑 `git status --short` 看他改了什麼**（只是看，可以跑），但不要幫他 add、commit、pull、push
- **B**：照下面的步驟做。他直接說「你幫我同步」就是 B
- 「救回來」都由你做

## 有沒有新的

每個對話第一次要改檔案前、開始做一張卡前，各看一次就好：

`git -c credential.interactive=false fetch -q`，然後 `git log -5 --format="%an：%s" HEAD..origin/main`

- 沒有東西、沒有 git、失敗（沒網路、要登入）：**直接做，不用跟他說**
- 有東西：「阿明剛更新了醫院的關卡。A 先拿最新的（建議）　B 等一下再說」。**不要自己拿**，他可能有東西還沒存
- 他選 A：他還沒改東西，就請他在 GitHub Desktop 按 **Fetch origin** → **Pull origin**；已經改了東西就「同步」

## 你幫他：第一次先檢查

1. `git --version`。沒有 → 用 GitHub Desktop（看最下面）；他堅持要你來，才裝 Git for Windows（社課 USB 裡有），裝好重開 VS Code
2. `git remote -v`。沒有 git、或沒有 remote（下載 zip 來的）→ 告訴他「這份不是從你們組的 repo 拿的，沒辦法跟別人同步」，停
3. `git config user.name` 是空的、或看起來不是他（公用電腦會留著上一個人的）→ 問他的 GitHub 帳號，只設這個專案：
   `git config user.name "帳號"`、`git config user.email "帳號@users.noreply.github.com"`（不要加 `--global`，電腦可能是公用的）
4. 第一次推上去會跳瀏覽器要他登入 GitHub，是正常的。**公用電腦**：最後提醒他登出（Windows「認證管理員 → Windows 認證」刪掉 `git:https://github.com`）

## 「存進度」

1. 請他先在 Godot 按 `Ctrl+S`；編輯器（F6 那個）有開的話也按存檔
2. `git status --short`，分成兩堆：
   - **他的**：分工表、他的任務卡上寫的檔案（和它們的 `.uid`、`.import`），還有他的任務卡
   - **不是他的**：先不要動，也不要加進去
3. `git add -- 檔案1 檔案2`（一個一個寫出來）→ `git commit -m "繁體中文，做了什麼"`
4. 有「不是他的」：用一句話講（「你還改到阿明的關卡」），問：A 不是故意的，收起來　B 是故意的，阿明知道
   - A：收起來，再推一份到備份（電腦還原也不會不見）：
     `git stash push -m "名字：檔案" -- 檔案` → `git push origin "stash@{0}:refs/heads/backup/英文名-月日時分"`
   - B：加進去存

沒有東西可以存就說「沒有新的東西」，不是錯誤。

## 「同步」

1. 先「存進度」
2. `git pull --no-rebase --no-edit`
   - 說會蓋掉還沒存的檔案（`would be overwritten`）→ 那些是「不是他的」，照上面第 4 點處理，再做一次
   - 有衝突 → 看下面「衝突」
3. `git push`。被拒絕（別人剛推上去）→ 回到 2，最多三次
4. 說結果：「同步好了。阿明改了醫院的關卡，小魚加了會響的地板。」（看 `git log --oneline -10`）。提醒：Godot 問要不要重新載入，選「**重新載入**」
5. 拉到別人新的 `.gd`，跑一次 `godot --headless --path . --import`（Godot 開著就不用，它自己會讀）

## 衝突

**他說撞到了、跳出 Resolve conflicts、按過 Abort merge**：換你做，不用再問誰來做，也不要教他 Undo commit、看 History，不要自己想別的辦法。`git status` 說還在合併（unmerged）→ `git merge --abort`。然後 `git pull --no-rebase --no-edit` 讓它再撞一次，照下面 1～6 做完。**沒有撞**（pull 成功）→ 直接「同步」第 3 步。

**不用判斷誰寫得好：分工表寫是誰的，就留誰的。** `.tscn`、`.tres`、`.gd` 都一樣，不要自己把兩邊的內容拼起來（例外：看這段最後）。

1. `git diff --name-only --diff-filter=U` 列出衝突的檔案，看分工表和任務卡是誰的
2. 先備份他的版本（備份名稱只用英文、數字、`-`，中文名字改成拼音或 GitHub 帳號）：`git branch backup/英文名-月日時分 HEAD` → `git push origin backup/英文名-月日時分`
3. **只要有一個檔案看不出是誰的**（`project.godot`、`game_config.tres`、`docs/game_overview.md`、分工表沒寫的、兩個人的），或有一邊把檔案刪掉了：`git merge --abort`，停下來，照這樣說：

   > 還沒同步：你和別人都改了【什麼】，我不敢自己選。你的東西都還在，也備份好了（backup/…）。請找社長，或組裡有高階 AI 的人，跟他說這句話。

4. 每個檔案都知道是誰的：
   - 是他的：`git checkout --ours -- 檔案`
   - 是別人的：`git checkout --theirs -- 檔案`
   - 都弄好：`git add -- 那些檔案` → `git commit --no-edit`
5. 跑一次受影響的場景，確定沒有紅字 → 繼續「同步」第 3 步
6. 說結果：「你跟阿明都改了醫院的關卡，那一關是阿明的，所以留他的。你的那一版在備份裡（backup/…），想加的東西跟阿明說。」

**高階 AI 或社長來解的時候**：先確定兩邊都備份了（`backup/…` 和 `origin/main`），問兩個人各改了什麼、想留什麼，再動手；`.gd` 可以合併兩邊，合併完跑受影響的場景、沒有紅字才推；`.tscn`、`.tres` 選一邊，另一邊的改動重做。使用者說「我會寫程式」、叫你解，也照這樣。

## 「救回來」

1. 先「存進度」（現在壞掉的也存，才回得去），**不要推上去**，別人會拿到壞的
2. `git log --format="%h %ar %an %s" -10 -- 他的檔案`，翻成選擇題（講那時候做了什麼，不要講程式內容）：A 10 分鐘前「會響的地板」　B 半小時前「敵人放好」……
3. 他選了：`git restore --source=那個 -- 他的檔案`（只有他的）→ 請他打開來看 → 對了就「同步」

## 用 GitHub Desktop（他自己來）

先跑 `git status --short`，不要憑印象列（沒有 git 才看這個對話改過的檔案），分成他的、不是他的。然後**照這五步和最後那句講**，檔案和那句話換成真的：

> 1. 在 Godot 按 `Ctrl+S`（F6 的編輯器有開也按存檔）
> 2. GitHub Desktop 左邊**只勾這些**：`features/noisy_floor/` 全部、`docs/tasks/02_noisy_floor.md`
> 3. 左下貼這句：`加會響的地板` → 按 **Commit to main**
> 4. 上面按 **Fetch origin** →（變成 **Pull origin** 就按）→ **Push origin**
> 5. Godot 問要不要重新載入，選「**重新載入**」
>
> 跳出 **Resolve conflicts before Merge**：按 **Abort merge**（不要按 X 關掉），回來跟我說。

- **Desktop 預設全部打勾**，一定要說清楚只勾哪些。有不是他的，說「這個是阿明的，不要勾」，問他是不是故意的
- 跳出「files would be overwritten」：按 **Stash changes and continue**（收起來，不會不見）
- 不見了 Abort merge 的視窗（按到 X）：上面的橫條（Resolve conflicts and commit to merge into main）按 **View conflicts** 就回來了，沒有橫條就找社長，不要 commit
- 只想「存進度」：做到第 3 步就好
- 按過 Abort merge：有 git 就換你做，照上面「衝突」；沒有就找組裡有高階 AI 的人或社長
