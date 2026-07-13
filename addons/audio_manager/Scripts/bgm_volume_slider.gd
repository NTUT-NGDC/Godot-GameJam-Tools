extends Control

func _on_bgm_volume_slider_value_changed(value: float) -> void:
	AudioManager.set_bgm_volume(value)
	AudioManager.set_sfx_volume(value)
