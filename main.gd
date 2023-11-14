extends Node2D

@export var asteroid_scene : PackedScene
var screensize

func _ready():
	screensize = get_viewport().get_visible_rect().size
	for i in 10:
		spawn_asteroid()

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
