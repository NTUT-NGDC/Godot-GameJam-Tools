#備忘錄 
3.對話框 未做 

#功能說明 
拖入Scenes的相應tscn，以及其附加的Scripts即可使用。

[UI.tscn]
內含暫停選單PauseMenu/死亡選單DeathMenu

暫停選單＝PauseMenu
功能：在遊戲中途可按下ESC暫停，再按下ESC回到遊戲。此項包含離開遊戲與繼續遊戲的按鈕。 

死亡選單＝DeathMenu
功能：腳色血量歸零後，會間隔0.1秒後跳出，此項包含重來遊戲（重新開始當前場景）與離開遊戲的按鈕。
需要搭配`UI_testbot`、`health_bar`、`Textures資料夾`使用，才能看見效果。

[UI_testbot]
UI測試用機器人，會不停在畫面中旋轉，且包含簡易的扣血設計。

[HealthBar]
血量條
需要搭配`UI_testbot`、`Textures資料夾`使用，才能看見效果。

[Textures資料夾]
現階段包含血量條的三張圖片，資料夾內有附PSD檔案，可自由修改。

[Button_QUIT]
離開遊戲按鈕
功能：按下去後遊戲就會結束。

[Button_Start]
開始遊戲按鈕
功能：適用於遊戲開場主選單，按下後即可進入遊戲。`需要額外手動設定，搭配已有場景轉換，可看button_start.gd`
