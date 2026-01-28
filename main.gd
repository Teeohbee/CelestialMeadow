extends Node2D

@export var asteroid_scene : PackedScene
@export var player_scene : PackedScene
var screensize
var game_over = false
var player_configs = [
	{"position": Vector2(0.1, 0.1), "number": 0},
	{"position": Vector2(0.9, 0.9), "number": 1},
	{"position": Vector2(0.1, 0.9), "number": 2},
	{"position": Vector2(0.9, 0.1), "number": 3}
]

func _ready():
	screensize = get_viewport().get_visible_rect().size
	spawn_players()
	for i in 10:
		spawn_asteroid()

func spawn_players():
	for i in GameState.num_players:
		var player = player_scene.instantiate()
		player.starting_position = player_configs[i].position
		player.player_number = player_configs[i].number
		player.tree_exiting.connect(_on_player_destroyed)
		add_child(player)

func spawn_asteroid():
	$AsteroidPath/AsteroidSpawn.progress = randi()
	var velocity = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(100, 200)
	var asteroid = asteroid_scene.instantiate()
	asteroid.start($AsteroidPath/AsteroidSpawn.position, velocity)
	call_deferred("add_child", asteroid)

func _on_asteroid_timer_timeout():
	var asteroids = get_tree().get_nodes_in_group("asteroids")
	if asteroids.size() < 10:
		for i in 2:
			spawn_asteroid()

func _on_player_destroyed():
	if game_over:
		return
	
	await get_tree().create_timer(0.5).timeout
	
	var remaining_players = get_tree().get_nodes_in_group("players")
	
	if remaining_players.size() == 1:
		game_over = true
		show_victory(remaining_players[0].player_number)
	elif remaining_players.size() == 0:
		game_over = true
		show_draw()

func show_victory(winner_number: int):
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_top = -100
	panel.offset_right = 200
	panel.offset_bottom = 100
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	
	var label = Label.new()
	label.text = "Player %d Wins!" % (winner_number + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)
	
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://menu.tscn")

func show_draw():
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_top = -100
	panel.offset_right = 200
	panel.offset_bottom = 100
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(panel)
	
	var label = Label.new()
	label.text = "Draw!\nEveryone Lost!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)
	
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_file("res://menu.tscn")
