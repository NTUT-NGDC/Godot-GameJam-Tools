
#使用說明
`在專案設定-全域，加入AudioManager.gd`
如果要查看使用效果，請開啟Audio_TEST.tscn。

#如何新增背景音樂(BGM)與音效(SFX)？
1.在場景搜尋SoundBank子節點，將其加入需要音效的場景，並開啟SoundBank的Inspector(屬性檢視器)。
2.在Bgm Entries/Sfx Entries分別選擇所需音訊的數量。
3.點擊(Empty空)，新增SoundEntry，並再點擊一次SoundEntry。
4.SoundEntry下會出現兩個欄位：
[Sound Name: 自行輸入好記的音樂代號]
[Stream: 拖入音訊檔]
5.在SoundBank子節點下，找到Auto Play Bgm，輸入`自行輸入BGM名稱`，可在該場景自動播放BGM。
下方Auto_Play Fade Time可調整BGM淡出/淡入的時間。

#注意事項
Sfx / Bgm 是不同欄位，注意不要填錯位置了。
音樂取名請取相異的代號，不要通通都取BGM01。

[背景音樂BGM]
切換場景時，不同的BGM會自動淡入淡出。
AudioManager.play_bgm(`自行輸入的BGM名稱`)

[音效SFX]
如需加入SFX，請在想要播放的地方創立腳本:	
AudioManager.play_sfx(`自行輸入的SFX名稱`)
	
[BGMVolumeSlider]
雖然叫做BGM音量拉桿，但裡面可以控制全部BGM/SFX的音量，也可選擇分開控制。
設置方式請看BGMVolumeSlider.tscn

如果需要分別調整BGM/SFX的音量，請用
	AudioManager.set_bgm_volume(value)
	AudioManager.set_sfx_volume(value)
	
[Mute]
一鍵靜音Check Box
設置方式請看Mute.tscn
