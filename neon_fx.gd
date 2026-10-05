extends RefCounted

## Particle builders for the neon look. Colours are pushed through
## GameConfig.NEON_GLOW so the WorldEnvironment glow blooms them.

static var _streak_texture: Texture2D

## Thin vertical streak used for sparks so they read as lines, not squares
static func streak_texture() -> Texture2D:
	if _streak_texture == null:
		var gradient = Gradient.new()
		gradient.set_color(0, Color.WHITE)
		gradient.set_color(1, Color(1, 1, 1, 0))
		var texture = GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 3
		texture.height = 14
		texture.fill_from = Vector2(0.5, 0.0)
		texture.fill_to = Vector2(0.5, 1.0)
		_streak_texture = texture
	return _streak_texture

static func _fade_ramp(color: Color) -> Gradient:
	var ramp = Gradient.new()
	ramp.set_color(0, color * GameConfig.NEON_GLOW)
	ramp.set_color(1, Color(color.r, color.g, color.b, 0.0))
	return ramp

## One-shot burst of sparks added to the current scene so it outlives the emitter
static func spark_burst(tree: SceneTree, at: Vector2, color: Color, amount: int) -> void:
	var sparks = CPUParticles2D.new()
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.amount = amount
	sparks.lifetime = GameConfig.SPARK_LIFETIME
	sparks.texture = streak_texture()
	sparks.particle_flag_align_y = true
	sparks.direction = Vector2.RIGHT
	sparks.spread = 180.0
	sparks.gravity = Vector2.ZERO
	sparks.initial_velocity_min = GameConfig.SPARK_SPEED_MIN
	sparks.initial_velocity_max = GameConfig.SPARK_SPEED_MAX
	sparks.damping_min = GameConfig.SPARK_DAMPING
	sparks.damping_max = GameConfig.SPARK_DAMPING
	sparks.scale_amount_min = 0.8
	sparks.scale_amount_max = 1.6
	sparks.color_ramp = _fade_ramp(color)
	sparks.global_position = at
	sparks.finished.connect(sparks.queue_free)
	tree.current_scene.add_child(sparks)
	sparks.emitting = true

## Continuous exhaust trail; toggle `emitting` while thrusting
static func thrust_trail(color: Color) -> CPUParticles2D:
	var trail = CPUParticles2D.new()
	trail.emitting = false
	trail.amount = 48
	trail.lifetime = 0.45
	trail.local_coords = false
	trail.direction = Vector2.LEFT
	trail.spread = 12.0
	trail.gravity = Vector2.ZERO
	trail.initial_velocity_min = 80.0
	trail.initial_velocity_max = 160.0
	trail.scale_amount_min = 2.0
	trail.scale_amount_max = 4.0
	trail.color_ramp = _fade_ramp(color)
	return trail

## Fading streak behind a bullet. A line rather than particles because
## particles only emit once per frame, which leaves gaps at bullet speed.
static func bullet_trail(color: Color, length: float) -> Line2D:
	var trail = Line2D.new()
	trail.points = PackedVector2Array([Vector2.ZERO, Vector2(-length, 0)])
	trail.width = 3.0
	var gradient = Gradient.new()
	gradient.set_color(0, color * GameConfig.NEON_GLOW)
	gradient.set_color(1, Color(color.r, color.g, color.b, 0.0))
	trail.gradient = gradient
	trail.show_behind_parent = true
	return trail
