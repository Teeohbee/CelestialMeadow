extends Area2D

@export var speed = 1000

var velocity = Vector2.ZERO
var player_number : int

func start(_transform, _player_number):
	transform = _transform
	velocity = transform.x * speed
	player_number = _player_number

func _process(delta):
	position += velocity * delta

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _on_body_entered(body):
	if player_number == body.player_number:
		return
	if body.is_in_group("players"):
		body.destroy()
		queue_free()
