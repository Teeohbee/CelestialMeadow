extends Control

var num_players = 2

func _ready():
	$VBoxContainer/StartButton.grab_focus()
	update_player_label()

func update_player_label():
	$VBoxContainer/PlayerCount/Label.text = str(num_players)

func _on_start_button_pressed():
	GameState.num_players = num_players
	get_tree().change_scene_to_file("res://main.tscn")

func _on_quit_button_pressed():
	get_tree().quit()

func _on_decrease_pressed():
	num_players = max(1, num_players - 1)
	update_player_label()

func _on_increase_pressed():
	num_players = min(4, num_players + 1)
	update_player_label()
