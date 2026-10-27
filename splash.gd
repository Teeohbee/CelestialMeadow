extends Control

## The splash sting before the title card. The six pilots' inks sweep in
## from the left as poster speed bars, the credit stamps down over them, and
## after SPLASH_TIME it hands over to the title. Any button skips it.

const SWEEP_TIME: float = 0.8
const BAR_WIDTH: float = 26.0
const BAR_GAP: float = 44.0
## Where each bar's nose comes to rest, as a fraction of the screen width
const BAR_ENDS: Array[float] = [0.62, 0.74, 0.56, 0.8, 0.66, 0.7]
const BAR_STAGGER: float = 0.08
## The bars sit a little above the middle, the credit on clear ground below
const BARS_CENTRE: float = 0.42
const CREDIT_DROP: float = 200.0

const Grain = preload("res://art/grain.gd")

## 0 = no bars, 1 = every bar at rest
var sweep: float = 0.0:
	set(value):
		sweep = value
		queue_redraw()
var credit: Label
var leaving: bool = false

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	credit = Label.new()
	credit.text = "A TOBY CLARKE GAME"
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	credit.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	credit.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	credit.offset_top = CREDIT_DROP
	credit.offset_bottom = CREDIT_DROP
	credit.add_theme_font_override("font", Poster.font(700, 14))
	credit.add_theme_font_size_override("font_size", 72)
	credit.add_theme_color_override("font_color", GameConfig.CREAM)
	credit.add_theme_color_override("font_shadow_color", GameConfig.HUE)
	credit.add_theme_constant_override("shadow_offset_x", 6)
	credit.add_theme_constant_override("shadow_offset_y", 6)
	credit.modulate.a = 0.0
	add_child(credit)
	var grain = ColorRect.new()
	grain.name = "Grain"
	grain.set_script(Grain)
	grain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(grain)
	play()

func play():
	var bars = create_tween()
	bars.tween_property(self, "sweep", 1.0, SWEEP_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# The credit lands as the bars settle, from a touch big
	credit.pivot_offset = size * 0.5
	credit.scale = Vector2(1.15, 1.15)
	var stamp = create_tween().set_parallel()
	stamp.tween_property(credit, "modulate:a", 1.0, 0.2).set_delay(SWEEP_TIME * 0.7)
	stamp.tween_property(credit, "scale", Vector2.ONE, 0.3).set_delay(SWEEP_TIME * 0.7) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await get_tree().create_timer(GameConfig.SPLASH_TIME).timeout
	leave()

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), GameConfig.GROUND)
	var count = GameConfig.PLAYER_COLORS.size()
	var top = size.y * BARS_CENTRE - BAR_GAP * (count - 1) * 0.5
	for i in count:
		# Each bar starts a little after the one before and catches up
		var t = clampf((sweep - BAR_STAGGER * i) / (1.0 - BAR_STAGGER * (count - 1)), 0.0, 1.0)
		var nose = lerpf(-BAR_WIDTH, size.x * BAR_ENDS[i], t)
		var tail = nose - size.x * 0.45
		var y = top + BAR_GAP * i
		Poster.bar(self, Vector2(tail, y), Vector2(nose, y), BAR_WIDTH, Color(GameConfig.PLAYER_COLORS[i], 0.85))

func _input(event):
	if event is InputEventMouseMotion or event is InputEventJoypadMotion:
		return
	if not event.is_pressed() or event.is_echo():
		return
	get_viewport().set_input_as_handled()
	leave()

func leave():
	if leaving:
		return
	leaving = true
	SceneManager.go_to("res://title.tscn")
