extends Area2D

enum PowerupType { SHIELD, RAPID_FIRE, SPEED_BOOST }

@export var type: PowerupType = PowerupType.SHIELD

var rotation_speed: float = 2.0
var despawn_time: float = GameConfig.POWERUP_DESPAWN_TIME
var blink_warning_time: float = 5.0
var orbit: float = 0.0

const TOKEN_RADIUS: float = 16.0

func _ready():
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
	orbit += rotation_speed * delta
	queue_redraw()

## One cream token for every power-up; the glyph inside says which:
## a ring for Shield, two bars for Rapid Fire, a chevron for Speed Boost
func _draw():
	var r = TOKEN_RADIUS
	var hue = GameConfig.HUE
	draw_circle(Vector2.ZERO, r * 1.35, GameConfig.CREAM)
	draw_arc(Vector2.ZERO, r * 1.08, 0, TAU, 48, hue, 2.0, true)
	draw_circle(Vector2.from_angle(orbit) * r * 1.08, 3.0, GameConfig.LIGHT)
	match type:
		PowerupType.SHIELD:
			draw_arc(Vector2.ZERO, r * 0.5, 0, TAU, 32, hue, 4.0, true)
		PowerupType.RAPID_FIRE:
			for y in [-0.3, 0.3]:
				Poster.bar(self, Vector2(-r * 0.45, r * y), Vector2(r * 0.45, r * y), 5.0, hue)
		PowerupType.SPEED_BOOST:
			for x in [-0.3, 0.15]:
				draw_polyline(PackedVector2Array([Vector2(r * x, -r * 0.45), Vector2(r * (x + 0.3), 0), Vector2(r * x, r * 0.45)]), hue, 4.0, true)

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
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(self, "modulate:a", 0.3, 0.3)
	tween.tween_property(self, "modulate:a", 1.0, 0.3)
