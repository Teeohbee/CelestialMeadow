extends Node2D

## The Grand Tour arena: plum ground with stepped horizon rings, stars,
## Atomic Clock dashed orbits, drifting speed bars and a rounded bezel.

const SEED: int = 23

var size: Vector2
var stars: Array = []
var bars: Array = []
var bezel := StyleBoxFlat.new()

func _ready():
	z_index = -100
	size = get_viewport_rect().size
	var rng = RandomNumberGenerator.new()
	rng.seed = SEED
	for i in 70:
		stars.append([Vector2(rng.randf() * size.x, rng.randf() * size.y), 0.8 + rng.randf() * 1.6, 0.25 + rng.randf() * 0.4])
	var inks = GameConfig.ENV_INKS
	for i in GameConfig.SPEED_BAR_COUNT:
		bars.append({
			"y": (0.08 + rng.randf() * 0.84) * size.y,
			"len": 180.0 + rng.randf() * 420.0,
			"speed": 14.0 + rng.randf() * 20.0,
			"x0": rng.randf() * size.x,
			"width": 4.0 + rng.randf() * 8.0,
			"color": inks[i % inks.size()],
			"head": inks[(i + 3) % inks.size()],
		})
	bezel.draw_center = false
	bezel.set_border_width_all(2)
	bezel.set_corner_radius_all(56)
	bezel.border_color = Color(GameConfig.LIGHT, 0.35)
	bezel.anti_aliasing = true

func _process(_delta):
	queue_redraw()

func _draw():
	var t = Time.get_ticks_msec() / 1000.0
	draw_rect(Rect2(Vector2(-200, -200), size + Vector2(400, 400)), GameConfig.GROUND)
	# Horizon glow in flat stepped rings, the poster's stand-in for a gradient
	for i in range(5, -1, -1):
		draw_circle(Vector2(size.x * 0.5, size.y * 1.6), size.y * (1.0 + i * 0.17), GameConfig.GROUND.lerp(GameConfig.DEEP, (6 - i) / 6.0))
	for s in stars:
		draw_circle(s[0], s[1], Color(GameConfig.CREAM, s[2]))
	for f in [0.42, 0.66, 0.92]:
		Poster.dashed_circle(self, size * 0.5, size.y * f, 7, 9, Color(GameConfig.CREAM, 0.12), 1.5)
	# Speed bars all drift one way, a dot of another ink at the head
	for b in bars:
		var span = size.x + b.len * 2.0
		var x = fposmod(b.x0 + t * b.speed, span) - b.len
		Poster.bar(self, Vector2(x - b.len, b.y), Vector2(x, b.y), b.width, Color(b.color, GameConfig.SPEED_BAR_ALPHA))
		draw_circle(Vector2(x, b.y), b.width * 0.9, Color(b.head, minf(1.0, GameConfig.SPEED_BAR_ALPHA * 1.5)))
	bezel.draw(get_canvas_item(), Rect2(Vector2(14, 14), size - Vector2(28, 28)))
