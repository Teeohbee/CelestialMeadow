extends RigidBody2D

signal powerup_dropped(powerup_position, powerup_type)

var screen_size
var radius
@export var sprites : Array[CompressedTexture2D] = []
var drop_chance = 0.3  # 30% chance to drop power-up

func _ready():
	screen_size = get_viewport_rect().size
	$Sprite2D.texture = sprites[randi() % sprites.size()]
	var asteroid_scale = randf_range(0.8, 1.5)
	$Sprite2D.scale = Vector2(asteroid_scale, asteroid_scale)
	$CollisionShape2D.scale = Vector2(asteroid_scale, asteroid_scale)
	radius = int($Sprite2D.texture.get_size().x / 2 * asteroid_scale)
	
func start(_position, _velocity):
	position = _position
	linear_velocity = _velocity
	angular_velocity = randf_range(-PI, PI)

func _integrate_forces(physics_state):
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0 - radius, screen_size.x + radius)
	xform.origin.y = wrapf(xform.origin.y, 0 - radius, screen_size.y + radius)
	physics_state.transform = xform
	
func destroy():
	$CollisionShape2D.set_deferred("disabled", true)
	$Sprite2D.hide()
	$Explosion.show()
	$Explosion.play("explode")
	$ExplosionSound.play()
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	var camera = get_tree().root.get_node_or_null("Main/Camera2D")
	if camera and camera.has_method("shake"):
		camera.shake(12.0)
	
	# Drop power-up randomly
	if randf() < drop_chance:
		var powerup_type = randi() % 3  # Random type 0-2
		emit_signal("powerup_dropped", global_position, powerup_type)
	
	await $Explosion.animation_finished
	queue_free()
