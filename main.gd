extends Node2D

@export var asteroid_scene: PackedScene
@export var player_scene: PackedScene
@export var powerup_scene: PackedScene

var screen_size: Vector2
var game_over: bool = false
var player_configs = [
	{"position": Vector2(0.1, 0.1), "number": 0},   # Top-left
	{"position": Vector2(0.9, 0.9), "number": 1},   # Bottom-right
	{"position": Vector2(0.1, 0.9), "number": 2},   # Bottom-left
	{"position": Vector2(0.9, 0.1), "number": 3},   # Top-right
	{"position": Vector2(0.5, 0.1), "number": 4},   # Top-center
	{"position": Vector2(0.5, 0.9), "number": 5}    # Bottom-center
]

func _ready():
	screen_size = get_viewport().get_visible_rect().size
	spawn_players()
	initialize_hud()
	for i in GameConfig.ASTEROID_INITIAL_COUNT:
		spawn_asteroid()

func spawn_players():
	for i in GameState.num_players:
		var player = player_scene.instantiate()
		player.starting_position = player_configs[i].position
		player.player_number = player_configs[i].number
		player.tree_exiting.connect(_on_player_destroyed)
		player.respawn_requested.connect(_on_player_respawn_requested)
		player.lives_changed.connect(_on_player_lives_changed)
		add_child(player)

func spawn_asteroid():
	$AsteroidPath/AsteroidSpawn.progress = randi()
	var velocity = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(GameConfig.ASTEROID_MIN_SPEED, GameConfig.ASTEROID_MAX_SPEED)
	var asteroid = asteroid_scene.instantiate()
	asteroid.start($AsteroidPath/AsteroidSpawn.position, velocity)
	asteroid.powerup_dropped.connect(_on_powerup_dropped)
	call_deferred("add_child", asteroid)

func _on_asteroid_timer_timeout():
	var asteroids = get_tree().get_nodes_in_group("asteroids")
	if asteroids.size() < GameConfig.ASTEROID_MAX_COUNT:
		for i in GameConfig.ASTEROID_SPAWN_COUNT:
			spawn_asteroid()

func _on_player_destroyed():
	if game_over:
		return
	
	await get_tree().create_timer(GameConfig.END_GAME_CHECK_DELAY).timeout
	
	var remaining_players = get_tree().get_nodes_in_group("players")
	
	if remaining_players.size() == 1:
		game_over = true
		show_victory(remaining_players[0].player_number)
	elif remaining_players.size() == 0:
		game_over = true
		show_draw()

func show_victory(winner_number: int):
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(overlay)
	
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_top = -100
	panel.offset_right = 200
	panel.offset_bottom = 100
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	canvas_layer.add_child(panel)
	
	var label = Label.new()
	label.text = "Player %d Wins!" % (winner_number + 1)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)
	
	await get_tree().create_timer(GameConfig.VICTORY_SCREEN_DURATION).timeout
	get_tree().change_scene_to_file("res://menu.tscn")

func show_draw():
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.6)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas_layer.add_child(overlay)
	
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -200
	panel.offset_top = -100
	panel.offset_right = 200
	panel.offset_bottom = 100
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	canvas_layer.add_child(panel)
	
	var label = Label.new()
	label.text = "Draw!\nEveryone Lost!"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 48)
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)
	
	await get_tree().create_timer(GameConfig.VICTORY_SCREEN_DURATION).timeout
	get_tree().change_scene_to_file("res://menu.tscn")

func _on_player_respawn_requested(player):
	await get_tree().create_timer(GameConfig.PLAYER_RESPAWN_DELAY).timeout
	if is_instance_valid(player):
		player.respawn()

func initialize_hud():
	var hud = $HUD
	for i in GameState.num_players:
		hud.update_lives(i, GameState.lives_per_player)

func _on_player_lives_changed(player_number: int, lives: int):
	$HUD.update_lives(player_number, lives)

func _on_powerup_dropped(powerup_position: Vector2, powerup_type: int):
	var powerup = powerup_scene.instantiate()
	powerup.position = powerup_position
	powerup.type = powerup_type
	call_deferred("add_child", powerup)
