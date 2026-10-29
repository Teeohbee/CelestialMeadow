extends CanvasLayer

## A corner readout for chasing frame rate on the TV: fps, the slowest frame
## in the last second, the whole frame's time (Godot's process monitor, which
## includes waiting for the screen), physics, and render CPU and GPU, plus the
## size the game draws at. Frame time well above render time means the game
## is waiting on the display, not working. The Frame readout option turns it
## on from the pad; F3 toggles it too, and launching with --perf starts it on.

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
	visible = GameSettings.get_setting("perf_readout") or "--perf" in OS.get_cmdline_args() or "--perf" in OS.get_cmdline_user_args()

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
	return "%d fps   worst %.1f ms\nframe %.1f   physics %.1f\nrender cpu %.1f   gpu %.1f\n%s drawn, %s logical\nwindow %s   screen %s at %.2fx   %s" % [
		Engine.get_frames_per_second(), worst_frame / 1000.0,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		RenderingServer.viewport_get_measured_render_time_cpu(rid),
		RenderingServer.viewport_get_measured_render_time_gpu(rid),
		size_text(drawn_size()), size_text(get_viewport().get_visible_rect().size),
		# Where a drawn size bigger than the screen comes from: the window, the
		# screen's reported size and scale, and which display server Godot chose
		size_text(get_window().size), size_text(DisplayServer.screen_get_size()),
		DisplayServer.screen_get_scale(), DisplayServer.get_name(),
	]

## The size actually drawn: the window's, or the layout's at 1080p. Not the
## root's texture size, which in canvas_items mode is the window size times
## the stretch scale, so a 4K window read as 7680x4320.
func drawn_size() -> Vector2:
	var window = get_window()
	if window.content_scale_mode == Window.CONTENT_SCALE_MODE_VIEWPORT:
		return window.get_visible_rect().size
	return Vector2(window.size)

func size_text(size: Vector2) -> String:
	return "%dx%d" % [size.x, size.y]
