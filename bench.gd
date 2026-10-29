extends Node2D

## A frame-rate benchmark from Options, for finding what holds the Steam
## Machine at 45 fps without a keyboard. It runs stripped-down stages, each
## settling then measuring for a few seconds, and ends on a table of fps, the
## slowest frame, render GPU time and the size drawn. The first stage to drop
## says where the cap comes from; if even the empty one does, it's nothing we
## draw. A or B goes back to the title once it's done.

const SETTLE_TIME: float = 1.0
const MEASURE_TIME: float = 4.0
const Grain = preload("res://art/grain.gd")
const ArenaBackdrop = preload("res://art/arena_backdrop.gd")

## Each stage: its name, what it shows, and whether it draws at 1080p
var stages: Array[Dictionary] = [
	{"name": "Empty", "build": func(): return Node2D.new()},
	{"name": "Empty at 1080p", "build": func(): return Node2D.new(), "1080p": true},
	{"name": "Arena backdrop", "build": func(): return backdrop()},
	{"name": "Backdrop and grain", "build": func(): return backdrop(true)},
	{"name": "Title backdrop", "build": func(): return load("res://backdrop.tscn").instantiate()},
]
## Tests shorten the stages
var time_scale: float = 1.0
var results: Array[String] = []
var done: bool = false
var label: Label

func _ready():
	var layer = CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	label = Label.new()
	label.position = Vector2(120, 100)
	label.add_theme_font_size_override("font_size", 34)
	label.add_theme_color_override("font_color", GameConfig.CREAM)
	label.add_theme_color_override("font_outline_color", GameConfig.GROUND)
	label.add_theme_constant_override("outline_size", 8)
	layer.add_child(label)
	run()

func backdrop(with_grain: bool = false) -> Node:
	var holder = Node2D.new()
	var arena = Node2D.new()
	arena.set_script(ArenaBackdrop)
	holder.add_child(arena)
	if with_grain:
		var grain = ColorRect.new()
		grain.set_script(Grain)
		grain.z_index = 100
		grain.size = get_viewport_rect().size
		holder.add_child(grain)
	return holder

func run():
	# The scene change unfreezes us once the curtain's gone; measure after that
	while SceneManager.is_changing_scene:
		await get_tree().process_frame
	for stage in stages:
		label.text = "Benchmark: %s" % stage.name
		var content: Node = stage.build.call()
		add_child(content)
		get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT if stage.get("1080p", false) else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		await seconds(SETTLE_TIME * time_scale)
		results.append("%-20s %s" % [stage.name, await measure(MEASURE_TIME * time_scale)])
		content.queue_free()
	GameSettings.apply("render_1080p")
	done = true
	label.text = "BENCHMARK\n\n%s\n\nA or B to go back" % "\n".join(results)

## Average fps, slowest frame, average render GPU time and size drawn
func measure(duration: float) -> String:
	var rid = get_viewport().get_viewport_rid()
	var frames = 0
	var gpu = 0.0
	var worst = 0
	var started = Time.get_ticks_usec()
	var last = started
	while Time.get_ticks_usec() - started < duration * 1000000.0:
		await get_tree().process_frame
		var now = Time.get_ticks_usec()
		worst = maxi(worst, now - last)
		last = now
		frames += 1
		gpu += RenderingServer.viewport_get_measured_render_time_gpu(rid)
	var elapsed = (Time.get_ticks_usec() - started) / 1000000.0
	var drawn = get_viewport().get_texture().get_size()
	return "%5.1f fps   worst %5.1f ms   gpu %4.1f ms   %dx%d" % [
		frames / elapsed, worst / 1000.0, gpu / maxi(frames, 1), drawn.x, drawn.y]

func seconds(duration: float):
	await get_tree().create_timer(duration, true, false, true).timeout

func _input(event):
	if done and (event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel")):
		get_viewport().set_input_as_handled()
		SceneManager.go_to("res://title.tscn")
