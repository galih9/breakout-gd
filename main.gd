extends Node2D
@onready var pause_ui = $PauseUI

func _input(event):
	if event.is_action_pressed("pause") and not get_tree().paused:
		pause_ui.show_pause()
