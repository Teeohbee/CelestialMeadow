extends Control

func _ready():
	hide()
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	visible = !visible
	get_tree().paused = visible
	if visible:
		$Panel/VBoxContainer/ResumeButton.grab_focus()

func _on_resume_button_pressed():
	toggle_pause()

func _on_restart_button_pressed():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_main_menu_button_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menu.tscn")
