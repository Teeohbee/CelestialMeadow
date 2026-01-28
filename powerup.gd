extends Area2D

enum PowerupType { SHIELD, RAPID_FIRE, SPEED_BOOST }

@export var type: PowerupType = PowerupType.SHIELD
var rotation_speed = 2.0
var despawn_time = 15.0
var blink_warning_time = 5.0

func _ready():
	set_powerup_visual()
	body_entered.connect(_on_body_entered)
	
	# Start despawn timer
	var despawn_timer = Timer.new()
	despawn_timer.wait_time = despawn_time
	despawn_timer.one_shot = true
	despawn_timer.timeout.connect(_on_despawn_timeout)
	add_child(despawn_timer)
	despawn_timer.start()
	
	# Start blink warning timer
	var blink_timer = Timer.new()
	blink_timer.wait_time = despawn_time - blink_warning_time
	blink_timer.one_shot = true
	blink_timer.timeout.connect(_on_blink_warning)
	add_child(blink_timer)
	blink_timer.start()

func _process(delta):
	rotation += rotation_speed * delta

func set_powerup_visual():
	# Hide all visuals first
	$Shield.hide()
	$RapidFire.hide()
	$SpeedBoost.hide()
	
	# Show the correct one based on type
	match type:
		PowerupType.SHIELD:
			$Shield.show()
		PowerupType.RAPID_FIRE:
			$RapidFire.show()
		PowerupType.SPEED_BOOST:
			$SpeedBoost.show()

func _on_body_entered(body):
	if body.is_in_group("players"):
		apply_powerup(body)
		queue_free()

func apply_powerup(player):
	match type:
		PowerupType.SHIELD:
			player.activate_shield()
		PowerupType.RAPID_FIRE:
			player.activate_rapid_fire()
		PowerupType.SPEED_BOOST:
			player.activate_speed_boost()

func _on_despawn_timeout():
	queue_free()

func _on_blink_warning():
	var icon_node
	match type:
		PowerupType.SHIELD:
			icon_node = $Shield
		PowerupType.RAPID_FIRE:
			icon_node = $RapidFire
		PowerupType.SPEED_BOOST:
			icon_node = $SpeedBoost
	
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(icon_node, "modulate:a", 0.3, 0.3)
	tween.tween_property(icon_node, "modulate:a", 1.0, 0.3)
