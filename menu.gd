extends Control

var num_players: int = 2

func _ready():
	$VBoxContainer/StartButton.grab_focus()
	update_player_label()
	create_starfield()
	animate_planets()

func create_starfield():
	# Create twinkling stars in the background
	for i in range(100):
		var star = ColorRect.new()
		var size = randf_range(1, 3)
		star.custom_minimum_size = Vector2(size, size)
		star.size = Vector2(size, size)
		star.position = Vector2(randf() * 1920, randf() * 1080)
		star.color = Color(1, 1, 1, randf_range(0.3, 1.0))
		$Stars.add_child(star)
		
		# Animate twinkling
		var tween = create_tween()
		tween.set_loops()
		tween.tween_property(star, "modulate:a", randf_range(0.2, 0.6), randf_range(1, 3))
		tween.tween_property(star, "modulate:a", 1.0, randf_range(1, 3))

func animate_planets():
	# Slow rotation for planets
	for planet in [$Planet1, $Planet2, $Planet3, $Planet4]:
		var tween = create_tween()
		tween.set_loops()
		var duration = randf_range(20, 40)
		var rotation_amount = randf_range(-360, 360)
		tween.tween_property(planet, "rotation_degrees", rotation_amount, duration)
		tween.tween_property(planet, "rotation_degrees", rotation_amount * 2, duration)

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
	num_players = min(6, num_players + 1)
	update_player_label()
