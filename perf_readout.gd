extends CanvasLayer

## A corner readout for chasing frame rate on the TV: fps, the slowest frame
## in the last second, and where the time goes (script, physics, render CPU
## and GPU), plus the size the game draws at. F3 toggles it; launching with
## --perf starts with it on, for a Steam launch option when there's no keyboard.

const REFRESH_TIME: float = 0.5

var label: Label
## Slowest gap between frames since the label last refreshed, in microseconds
var worst_frame: int = 0
var last_frame: int = 0
var since_refresh: float = 0.0

func _ready():
	layer = 128
	process_mode = Node.PROCESS_MODE_ALWAYS
	label = Label.new()
	label.position = Vector2(24, 24)
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", GameConfig.CREAM)
	label.add_theme_color_override("font_outline_color", GameConfig.GROUND)
	label.add_theme_constant_override("outline_size", 6)
	add_child(label)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)
	visible = "--perf" in OS.get_cmdline_args() or "--perf" in OS.get_cmdline_user_args()

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		visible = not visible
		get_viewport().set_input_as_handled()

func _process(delta):
	var now = Time.get_ticks_usec()
	if last_frame > 0:
		worst_frame = maxi(worst_frame, now - last_frame)
	last_frame = now
	since_refresh += delta
	if visible and since_refresh >= REFRESH_TIME:
		label.text = readout()
		since_refresh = 0.0
		worst_frame = 0

func readout() -> String:
	var rid = get_viewport().get_viewport_rid()
	return "%d fps   worst %.1f ms\nscript %.1f   physics %.1f\nrender cpu %.1f   gpu %.1f\n%s drawn, %s logical" % [
		Engine.get_frames_per_second(), worst_frame / 1000.0,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(rid),
		RenderingServer.viewport_get_measured_render_time_gpu(rid),
		size_text(get_window().size), size_text(get_viewport().get_visible_rect().size),
	]

func size_text(size: Vector2) -> String:
	return "%dx%d" % [size.x, size.y]
