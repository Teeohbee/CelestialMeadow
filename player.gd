extends RigidBody2D

signal respawn_requested(player)
signal lives_changed(player_number, lives)

@export var bullet_scene: PackedScene
@export var starting_position: Vector2 = Vector2(0.1, 1)
@export var player_number: int = 0

var thrust: Vector2 = Vector2.ZERO
var rotation_direction: float = 0.0
var dead: bool = false
var can_shoot: bool = true
var screen_size: Vector2
var lives: int = GameConfig.PLAYER_LIVES_DEFAULT
var engine_power: float = GameConfig.PLAYER_ENGINE_POWER
var shield_active: bool = false
var rapid_fire_active: bool = false
var speed_boost_active: bool = false

func _ready():
	screen_size = get_viewport_rect().size
	position.x = screen_size.x * starting_position.x
	position.y = screen_size.y * starting_position.y
	lives = GameState.lives_per_player
	$ShootTimer.wait_time = GameConfig.PLAYER_SHOOT_DELAY
	set_ship_colour()
	set_ship_starting_rotation()
	
	# Freeze player during countdown
	var main_node = get_parent()
	if main_node and "game_started" in main_node and not main_node.game_started:
		freeze = true
		$Ship/Thruster.hide()  # Hide thruster during countdown
		# Connect to countdown finished to unfreeze
		var countdown = main_node.get_node_or_null("Countdown")
		if countdown:
			countdown.countdown_finished.connect(_on_countdown_finished)

func _on_countdown_finished():
	freeze = false

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
	# Check if game has started (countdown finished)
	var main_node = get_parent()
	if main_node and "game_started" in main_node and not main_node.game_started:
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
	constant_torque = rotation_direction * GameConfig.PLAYER_SPIN_POWER
	
func shoot():
	if can_shoot:
		var bullet = bullet_scene.instantiate()
		get_tree().root.add_child(bullet)
		$LaserSound.play()
		bullet.start($Muzzle.global_transform, player_number)
		$ShootTimer.start()
		can_shoot = false

func set_ship_colour():
	$Ship.set_self_modulate(GameConfig.PLAYER_COLORS[player_number])

func set_ship_starting_rotation():
	# Original logic that works for corners
	if starting_position.x > 0.5:
		rotation_degrees = 180
	# New logic for center positions
	elif starting_position.x == 0.5:
		if starting_position.y < 0.5:
			rotation_degrees = 90  # Top center faces down
		else:
			rotation_degrees = -90  # Bottom center faces up
	
	rotation_degrees += GameConfig.PLAYER_ROTATION_ADJUSTMENTS[player_number]

func destroy():
	$CollisionShape2D.set_deferred("disabled", true)
	dead = true
	$Ship.hide()
	$Explosion.show()
	$Explosion.play("explode")
	$ExplosionSound.play()
	var camera = get_tree().root.get_node_or_null("Main/Camera2D")
	if camera and camera.has_method("shake"):
		camera.shake(GameConfig.CAMERA_SHAKE_EXPLOSION)
	
	lives -= 1
	emit_signal("lives_changed", player_number, lives)
	
	await $Explosion.animation_finished
	$Explosion.hide()
	
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
	
	# Check if countdown is still running and freeze if needed
	var main_node = get_parent()
	if main_node and "game_started" in main_node and not main_node.game_started:
		freeze = true
		$Ship/Thruster.hide()
	else:
		freeze = false
	
	# Brief invincibility with visual feedback
	set_collision_layer_value(1, false)
	var tween = create_tween()
	tween.set_loops(GameConfig.PLAYER_INVINCIBILITY_BLINK_COUNT)
	tween.tween_property($Ship, "modulate:a", GameConfig.PLAYER_INVINCIBILITY_ALPHA_MIN, GameConfig.PLAYER_INVINCIBILITY_BLINK_DURATION)
	tween.tween_property($Ship, "modulate:a", 1.0, GameConfig.PLAYER_INVINCIBILITY_BLINK_DURATION)
	
	await get_tree().create_timer(GameConfig.PLAYER_INVINCIBILITY_DURATION).timeout
	set_collision_layer_value(1, true)
	$Ship.modulate.a = 1.0

func activate_shield():
	if shield_active:
		return
	shield_active = true
	set_collision_layer_value(1, false)
	
	# Create shield bubble
	var shield_bubble = Polygon2D.new()
	shield_bubble.name = "ShieldBubble"
	shield_bubble.color = GameConfig.SHIELD_COLOR
	# Create circle polygon
	var points = PackedVector2Array()
	for i in GameConfig.SHIELD_SEGMENTS:
		var angle = (i / float(GameConfig.SHIELD_SEGMENTS)) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * GameConfig.SHIELD_RADIUS)
	shield_bubble.polygon = points
	add_child(shield_bubble)
	
	await get_tree().create_timer(GameConfig.POWERUP_SHIELD_DURATION).timeout
	shield_active = false
	if not dead:
		set_collision_layer_value(1, true)
		if has_node("ShieldBubble"):
			$ShieldBubble.queue_free()

func activate_rapid_fire():
	if rapid_fire_active:
		return
	rapid_fire_active = true
	$ShootTimer.wait_time = GameConfig.PLAYER_SHOOT_DELAY * GameConfig.POWERUP_RAPID_FIRE_MULTIPLIER
	
	await get_tree().create_timer(GameConfig.POWERUP_RAPID_FIRE_DURATION).timeout
	rapid_fire_active = false
	$ShootTimer.wait_time = GameConfig.PLAYER_SHOOT_DELAY

func activate_speed_boost():
	if speed_boost_active:
		return
	speed_boost_active = true
	engine_power = GameConfig.PLAYER_ENGINE_POWER * GameConfig.POWERUP_SPEED_MULTIPLIER
	
	await get_tree().create_timer(GameConfig.POWERUP_SPEED_DURATION).timeout
	speed_boost_active = false
	engine_power = GameConfig.PLAYER_ENGINE_POWER
