extends Node2D

## The still space scene behind the title screen and lobby: placed planets,
## the station, and a few asteroids drifting slowly past

func _ready():
	spawn_asteroids()

func spawn_asteroids():
	var asteroid_scene = preload("res://asteroid.tscn")
	var size = get_viewport_rect().size
	for i in GameConfig.TITLE_ASTEROID_COUNT:
		var asteroid = asteroid_scene.instantiate()
		var velocity = Vector2.RIGHT.rotated(randf() * TAU) * GameConfig.TITLE_ASTEROID_SPEED * randf_range(0.6, 1.4)
		asteroid.start(Vector2(randf() * size.x, randf() * size.y), velocity)
		add_child(asteroid)
