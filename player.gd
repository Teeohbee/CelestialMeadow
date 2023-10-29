extends RigidBody2D

@export var engine_power = 500
@export var spin_power = 4000
@export var bullet_scene : PackedScene
@export var starting_position = 0.1

var thrust = Vector2.ZERO
var rotation_direction = 0

func _ready():
	var screen_size = get_viewport_rect().size
	position = screen_size * starting_position
	if starting_position > 0.5:
		rotation_degrees = 180

func _process(delta):
	get_input()

func get_input():
	thrust = Vector2.ZERO
	if Input.is_action_pressed("thrust"):
		thrust = transform.x * engine_power
		$Thruster.show()
	else:
		$Thruster.hide()
	rotation_direction = Input.get_axis("rotate_left", "rotate_right")
	
	if Input.is_action_just_pressed("shoot"):
		shoot()

func _physics_process(delta):
	constant_force = thrust
	constant_torque = rotation_direction * spin_power
	
func shoot():
	var bullet = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.start($Muzzle.global_transform)
