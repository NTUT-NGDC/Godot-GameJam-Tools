extends Control

func _ready() -> void:
	$MuteToggle.button_pressed = AudioManager.muted

func _on_mute_toggle_toggled(toggled_on: bool) -> void:
	AudioManager.set_muted(toggled_on)
