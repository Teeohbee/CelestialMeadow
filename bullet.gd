extends Area2D

@export var speed: int = 1000

var velocity: Vector2 = Vector2.ZERO
var player_number: int

func start(_transform, _player_number):
	transform = _transform
	velocity = transform.x * speed
	player_number = _player_number
	queue_redraw()

## An ink streak with a cream head. The scene is scaled 0.5, so lengths are doubled
func _draw():
	Poster.bar(self, Vector2.ZERO, Vector2(-68, 0), 14, GameConfig.PLAYER_COLORS[player_number])
	draw_circle(Vector2.ZERO, 9, GameConfig.CREAM)

func _physics_process(delta):
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if body.is_in_group("asteroids"):
		body.destroy()
		queue_free()
	if body.is_in_group("space_stations"):
		queue_free()
	if body.is_in_group("players"):
		if player_number == body.player_number:
			return
		body.destroy()
		queue_free()
