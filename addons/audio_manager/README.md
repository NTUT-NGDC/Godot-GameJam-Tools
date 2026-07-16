
#使用說明
`在專案設定-全域，加入AudioManager.tscn`
如果要查看使用效果，請開啟Tests資料夾的Audio_TEST.tscn。
Tests資料夾內的文件可以隨意刪除，不影響本工具使用。


#如何新增背景音樂(BGM)？
1.在場景搜尋SoundBank子節點，將其加入需要BGM的場景，並開啟SoundBank的Inspector(屬性檢視器)。
2.在Bgm Entries選擇所需音訊的數量。
3.點擊(Empty空)，新增SoundEntry，並再點擊一次SoundEntry。
4.SoundEntry下會出現兩個欄位：
[Sound Name: 自行輸入好記的音樂代號]
[Stream: 拖入音訊檔]
5.在SoundBank子節點下，找到Auto Play Bgm，輸入`自行輸入BGM名稱`，可在該場景自動播放BGM。
下方Auto_Play Fade Time可調整BGM淡出/淡入的時間。

#如何在按鈕上新增音效(SFX)？
1.在場景搜尋SoundBank子節點，將其加入需要音效的場景，並開啟SoundBank的Inspector(屬性檢視器)。
2.在Sfx Entries選擇所需音訊的數量。
3.點擊(Empty空)，新增SoundEntry，並再點擊一次SoundEntry。
4.SoundEntry下會出現兩個欄位：
[Sound Name: 自行輸入好記的音效代號]
[Stream: 拖入音訊檔]
5.在同場景的Button加入子節點`SFXOnButtonPress`
6.在Inspector[Sfx Name]欄位，輸入你在 SoundBank設定的音效代號，例如：SFX1。

#我需要更複雜的音效播放，如何手動操作？
1.同前兩個步驟，一樣需要建立完整的SoundBank。
2.在場景新增`SFXTrigger`子節點，視需求更改它的節點名稱。
3.在該節點的Sfx Name輸入剛在SoundBank設置好的音效名稱。
4.`SFXTrigger節點位置`.play()
例如，$VictorySFX.play()，就是播放在根節點的VictorySFX的音效。

以上方法適用於多人協作
若有人負責處理音樂，他只需要設置好SoundBank，新增`SFXTrigger`子節點，不用進入程式碼撰寫。

#如果寫程式語言對你來說比較省事
注意，此方法跟前幾項相同，需要事先設定好SoundBank。

[背景音樂BGM]
切換場景時，不同的BGM會自動淡入淡出。
AudioManager.play_bgm(`自行輸入的BGM名稱`)

[音效SFX]
如需加入SFX，請在想要播放的地方創立腳本:	
AudioManager.play_sfx(`自行輸入的SFX名稱`)

#我發現音效只會在那個場景起作用，怎麼設定通用的 UI 音效？
如果有大量音效想要分別控管，可以建造一個專門的場景，例如 GlobalSoundBank.tscn，放一個 SoundBank，登記這些通用音效。

Project
↓
Project Settings
↓
Globals把這個場景設為 Autoload

更快速的方法是，在AudioManager.tscn本身，掛載SoundBank，裡面已經提供一個SoundBank_Global可以自由使用。
（SoundBankGD是用來掛載腳本用的，不建議用來放置音效。）

#注意事項
Sfx / Bgm 是不同欄位，注意不要填錯位置了。
Sound Name請取相異的代號，不要通通都取BGM01，可能會播不出來。

#其他功能

[VolumeSliders]
裡面有三條拉桿：總音量、音樂、音效，分別控制 Master bus、BGM、SFX 的音量。
設置方式請看VolumeSliders.tscn

如果需要用程式碼分別調整音量，請用
	AudioManager.set_master_volume(value)
	AudioManager.set_bgm_volume(value)
	AudioManager.set_sfx_volume(value)
	
[Mute]
一鍵靜音Check Box
設置方式請看Mute.tscn
