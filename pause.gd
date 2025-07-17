extends CanvasLayer

@onready var panel = $Panel
@onready var resume_button = $Panel/VBoxContainer/ResumeButton

func _ready():
	# Ensure this UI still works during pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.process_mode = Node.PROCESS_MODE_ALWAYS
	hide_pause() # Hide at start

func show_pause():
	get_tree().paused = true
	visible = true

func hide_pause():
	get_tree().paused = false
	visible = false

func _on_resume_pressed():
	print("Resume clicked")
	hide_pause()
