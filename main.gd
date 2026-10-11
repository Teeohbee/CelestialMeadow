extends Node2D

@export var asteroid_scene: PackedScene
@export var player_scene: PackedScene
@export var powerup_scene: PackedScene

const SpawnMarker = preload("res://spawn_marker.gd")
const ResultsScene = preload("res://results.tscn")

var screen_size: Vector2
var mode: GameMode
var game_over: bool = false
var game_started: bool = false
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
	mode = GameState.mode.new()
	mode.round_over.connect(show_results)
	add_child(mode)
	spawn_players()
	initialize_hud()
	
	# Spawn asteroids before countdown starts
	for i in GameConfig.ASTEROID_INITIAL_COUNT:
		spawn_asteroid()
	
	# Start countdown before beginning the game
	$Countdown.countdown_finished.connect(_on_countdown_finished)
	$Countdown.start_countdown()

func _on_countdown_finished():
	game_started = true
	# Start asteroid timer (asteroids already spawned)
	$AsteroidTimer.start()
	mode.start()

func spawn_players():
	for i in GameState.players:
		var player = player_scene.instantiate()
		player.starting_position = player_configs[i].position
		player.player_number = player_configs[i].number
		player.tree_exiting.connect(_on_player_eliminated.bind(player.player_number))
		player.killed.connect(_on_player_killed)
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

func _on_player_killed(victim: int, killer: int):
	if not game_over:
		mode.on_player_killed(victim, killer)

func _on_player_eliminated(player_number: int):
	if not game_over:
		mode.on_player_eliminated(player_number)

## winners is every player credited with the round; empty for a draw
func show_results(winners: Array[int]):
	game_over = true
	for winner in winners:
		GameState.record_win(winner)
	var results = ResultsScene.instantiate()
	add_child(results)
	results.show_result(winners)

func _on_player_respawn_requested(player):
	var marker = SpawnMarker.new()
	marker.color = GameConfig.PLAYER_COLORS[player.player_number]
	marker.position = player.screen_size * player.starting_position
	add_child(marker)
	
	await get_tree().create_timer(GameConfig.PLAYER_RESPAWN_DELAY).timeout
	if is_instance_valid(player):
		player.respawn()
		marker.burst()
	else:
		marker.queue_free()

func initialize_hud():
	var hud = $HUD
	for i in GameState.players:
		hud.update_lives(i, GameState.lives_per_player)

func _on_player_lives_changed(player_number: int, lives: int):
	$HUD.update_lives(player_number, lives)

func _on_powerup_dropped(powerup_position: Vector2, powerup_type: int):
	var powerup = powerup_scene.instantiate()
	powerup.position = powerup_position
	powerup.type = powerup_type
	call_deferred("add_child", powerup)
