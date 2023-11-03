extends RigidBody2D

var screen_size

func _ready():
	screen_size = get_viewport_rect().size
	
func start(_position, _velocity):
	position = _position
	linear_velocity = _velocity
	angular_velocity = randf_range(-PI, PI)

func _integrate_forces(physics_state):
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screen_size.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screen_size.y)
	physics_state.transform = xform
	
func destroy():
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	$Explosion.show()
	$Explosion.play("explode")
	$ExplosionSound.play()
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	await $Explosion.animation_finished
	queue_free()
