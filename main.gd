extends Node2D

@export var asteroid_scene : PackedScene
@export var player_scene : PackedScene
var screensize
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
