extends Node2D

## The still space scene behind the title screen and lobby: placed planets,
## the station, and a few asteroids drifting slowly past

## The height the placed planets were laid out for
const DESIGN_HEIGHT: float = 1080.0

func _ready():
	spread_to(get_viewport_rect().size)
	spawn_asteroids()

## Spreads the placed planets and station down a taller (16:10) screen
func spread_to(size: Vector2):
	for child in get_children():
		if child is Node2D:
			child.position.y *= size.y / DESIGN_HEIGHT

func spawn_asteroids():
	var asteroid_scene = preload("res://asteroid.tscn")
	var size = get_viewport_rect().size
	for i in GameConfig.TITLE_ASTEROID_COUNT:
		var asteroid = asteroid_scene.instantiate()
		var velocity = Vector2.RIGHT.rotated(randf() * TAU) * GameConfig.TITLE_ASTEROID_SPEED * randf_range(0.6, 1.4)
		asteroid.start(Vector2(randf() * size.x, randf() * size.y), velocity)
		add_child(asteroid)
