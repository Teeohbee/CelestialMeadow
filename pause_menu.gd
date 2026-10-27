extends Control

func _ready():
	hide()
	$Panel/VBoxContainer/TitleLabel.add_theme_font_override("font", Poster.font(700, 10))
	process_mode = Node.PROCESS_MODE_ALWAYS

func _input(event):
	if event.is_action_pressed("pause"):
		# Something else (the results screen) has paused the game
		if get_tree().paused and not visible:
			return
		toggle_pause()

func toggle_pause():
	visible = !visible
	get_tree().paused = visible
	Music.duck(visible)
	if visible:
		$Panel/VBoxContainer/ResumeButton.grab_focus()

# Leaving for the lobby or a restart from here mustn't leave the music ducked
func _exit_tree():
	if visible:
		Music.duck(false)

func _on_resume_button_pressed():
	toggle_pause()

func _on_restart_button_pressed():
	SceneManager.go_to(get_tree().current_scene.scene_file_path)

func _on_main_menu_button_pressed():
	SceneManager.go_to("res://menu.tscn")
