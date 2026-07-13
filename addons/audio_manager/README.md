
#使用說明
`在專案設定-全域，加入AudioManager.gd`
如果要查看使用效果，請開啟Audio_TEST.tscn。

[背景音樂BGM]
切換場景時，不同的BGM會自動淡入淡出。如需加入BGM，請在該場景根節點創立腳本:

func _ready() -> void:
	AudioManager.play_bgm(preload(`"自行更改成BGM資產的位置"`)
	
[音效SFX]
如需加入SFX，請在想要播放的地方創立腳本:	
	AudioManager.play_sfx(preload(`"自行更改成SFX資產的位置"`)
	
[BGMVolumeSlider]
雖然叫做BGM音量拉桿，但裡面可以控制全部BGM/SFX的音量，也可選擇分開控制。
設置方式請看BGMVolumeSlider.tscn

如果需要分別調整BGM/SFX的音量，請用
	AudioManager.set_bgm_volume(value)
	AudioManager.set_sfx_volume(value)
	
[Mute]
一鍵靜音Check Box
設置方式請看Mute.tscn
