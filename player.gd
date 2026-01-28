extends RigidBody2D

signal respawn_requested(player)
signal lives_changed(player_number, lives)

@export var engine_power = 500
@export var spin_power = 4000
@export var bullet_scene : PackedScene
@export var starting_position = Vector2(0.1, 1)
@export var player_number = 0

var thrust = Vector2.ZERO
var rotation_direction = 0
var dead = false
var can_shoot = true
var screen_size
var lives = 3

func _ready():
	screen_size = get_viewport_rect().size
	position.x = screen_size.x * starting_position.x
	position.y = screen_size.y * starting_position.y
	lives = GameState.lives_per_player
	set_ship_colour()
	set_ship_starting_rotation()

func _process(_delta):
	get_input()

func _integrate_forces(physics_state):
	var xform = physics_state.transform
	xform.origin.x = wrapf(xform.origin.x, 0, screen_size.x)
	xform.origin.y = wrapf(xform.origin.y, 0, screen_size.y)
	physics_state.transform = xform

func get_input():
	if dead == true:
		return
	thrust = Vector2.ZERO
	if Input.is_action_pressed(str("thrust", player_number)):
		thrust = transform.x * engine_power
		$Ship/Thruster.show()
	else:
		$Ship/Thruster.hide()
	rotation_direction = Input.get_axis(str("rotate_left", player_number), str("rotate_right", player_number))
	
	if Input.is_action_pressed(str("shoot", player_number)):
		shoot()

func _physics_process(_delta):
	constant_force = thrust
	constant_torque = rotation_direction * spin_power
	
func shoot():
	if can_shoot:
		var bullet = bullet_scene.instantiate()
		get_tree().root.add_child(bullet)
		$LaserSound.play()
		bullet.start($Muzzle.global_transform, player_number)
		$ShootTimer.start()
		can_shoot = false

func set_ship_colour():
	var player_colours = [Color.RED, Color.GREEN, Color.BLUE, Color.YELLOW]
	$Ship.set_self_modulate(player_colours[player_number])

func set_ship_starting_rotation():
	if starting_position.x > 0.5:
		rotation_degrees = 180
	var player_rotation_adjustment = [30, 30, -30, -30]
	rotation_degrees += player_rotation_adjustment[player_number]

func destroy():
	$CollisionShape2D.set_deferred("disabled", true)
	dead = true
	$Ship.hide()
	$Explosion.show()
	$Explosion.play("explode")
	$ExplosionSound.play()
	var camera = get_tree().root.get_node_or_null("Main/Camera2D")
	if camera and camera.has_method("shake"):
		camera.shake(20.0)
	
	lives -= 1
	emit_signal("lives_changed", player_number, lives)
	
	await $Explosion.animation_finished
	
	if lives <= 0:
		queue_free()
	else:
		emit_signal("respawn_requested", self)

func _on_timer_timeout():
	can_shoot = true

func respawn():
	position.x = screen_size.x * starting_position.x
	position.y = screen_size.y * starting_position.y
	rotation_degrees = 0
	set_ship_starting_rotation()
	linear_velocity = Vector2.ZERO
	angular_velocity = 0
	dead = false
	$Ship.show()
	$Explosion.hide()
	$CollisionShape2D.set_deferred("disabled", false)
	
	# Brief invincibility with visual feedback
	set_collision_layer_value(1, false)
	var tween = create_tween()
	tween.set_loops(10)
	tween.tween_property($Ship, "modulate:a", 0.3, 0.2)
	tween.tween_property($Ship, "modulate:a", 1.0, 0.2)
	
	await get_tree().create_timer(2.0).timeout
	set_collision_layer_value(1, true)
	$Ship.modulate.a = 1.0
