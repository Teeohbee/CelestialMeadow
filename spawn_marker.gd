extends Node2D

## Pulsing ring shown at a player's start position while they wait to respawn

var color: Color = Color.WHITE
var pulse_tween: Tween

func _ready():
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(self, "scale", Vector2(1.2, 1.2), GameConfig.SPAWN_MARKER_PULSE_DURATION)
	pulse_tween.tween_property(self, "scale", Vector2(0.8, 0.8), GameConfig.SPAWN_MARKER_PULSE_DURATION)

func _draw():
	draw_arc(Vector2.ZERO, GameConfig.SPAWN_MARKER_RADIUS, 0, TAU, 48, color * GameConfig.NEON_GLOW, GameConfig.SPAWN_MARKER_WIDTH, true)

func burst():
	pulse_tween.kill()
	var tween = create_tween().set_parallel()
	tween.tween_property(self, "scale", Vector2.ONE * GameConfig.SPAWN_MARKER_BURST_SCALE, GameConfig.SPAWN_MARKER_BURST_DURATION)
	tween.tween_property(self, "modulate:a", 0.0, GameConfig.SPAWN_MARKER_BURST_DURATION)
	tween.chain().tween_callback(queue_free)
