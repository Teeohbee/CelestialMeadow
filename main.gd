extends Node2D

@export var asteroid_scene : PackedScene
var screensize

func _ready():
	screensize = get_viewport().get_visible_rect().size
	for i in 3:
		spawn_asteroid()

func spawn_asteroid():
	$AsteroidPath/AsteroidSpawn.progress = randi()
	var position = $AsteroidPath/AsteroidSpawn.position
	var velocity = Vector2.RIGHT.rotated(randf_range(0, TAU)) * randf_range(50, 125)
	var asteroid = asteroid_scene.instantiate()
	asteroid.start(position, velocity)
	call_deferred("add_child", asteroid)
