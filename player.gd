extends RigidBody2D

@export var engine_power = 500
@export var spin_power = 4000
@export var bullet_scene : PackedScene
@export var starting_position = 0.1
@export var player_number = 0

var thrust = Vector2.ZERO
var rotation_direction = 0
var screen_size

func _ready():
	screen_size = get_viewport_rect().size
	position = screen_size * starting_position
	if starting_position > 0.5:
		rotation_degrees = 180

func _process(delta):
	get_input()

func _integrate_forces(physics_state):
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screen_size.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screen_size.y)
	physics_state.transform = xform

func get_input():
	if Input.is_action_just_pressed('reset'):
		get_tree().reload_current_scene()
	thrust = Vector2.ZERO
	if Input.is_action_pressed(str("thrust", player_number)):
		thrust = transform.x * engine_power
		$Ship/Thruster.show()
	else:
		$Ship/Thruster.hide()
	rotation_direction = Input.get_axis(str("rotate_left", player_number), str("rotate_right", player_number))
	
	if Input.is_action_just_pressed(str("shoot", player_number)):
		shoot()

func _physics_process(delta):
	constant_force = thrust
	constant_torque = rotation_direction * spin_power
	
func shoot():
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	$LaserSound.play()
	bullet.start($Muzzle.global_transform, player_number)

func destroy():
	$Ship.hide()
	$Explosion.show()
	$Explosion.play("explode")
	$ExplosionSound.play()
	await $Explosion.animation_finished
	queue_free()

