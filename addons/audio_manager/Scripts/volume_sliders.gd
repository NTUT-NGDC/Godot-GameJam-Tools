extends Control

func _ready() -> void:
	%MasterSlider.value = AudioManager.master_volume
	%BgmSlider.value = AudioManager.bgm_volume
	%SfxSlider.value = AudioManager.sfx_volume


func _on_master_slider_value_changed(value: float) -> void:
	AudioManager.set_master_volume(value)


func _on_bgm_slider_value_changed(value: float) -> void:
	AudioManager.set_bgm_volume(value)


func _on_sfx_slider_value_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
