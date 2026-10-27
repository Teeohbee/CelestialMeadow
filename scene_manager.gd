extends CanvasLayer

## Every screen change goes through here. Bands of the palette's inks sweep
## across to cover the screen, the scene swaps underneath, and the bands
## sweep on to uncover it. Both scenes are frozen and nothing can be pressed
## while it moves, so a double press changes scene once.

const COVER_TIME: float = 0.35
const UNCOVER_TIME: float = 0.4

const BAND_SKEW: float = 260.0
const BAND_STAGGER: float = 0.18

var is_changing_scene: bool = false
## 0 = clear, 1 = covered, 2 = clear again; the curtain leaves the way it came
var progress: float = 0.0:
	set(value):
		progress = value
		curtain.queue_redraw()

var curtain: Control
## Red, amber and teal lead; the ground follows and covers the screen
var band_colours: Array[Color] = []

func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in [0, 2, 5]:
		band_colours.append(GameConfig.ENV_INKS[i])
	band_colours.append(GameConfig.GROUND)
	curtain = Control.new()
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
	curtain.draw.connect(draw_curtain)
	add_child(curtain)

## Returns false if a change is already happening, so double presses are harmless
func go_to(scene_path: String) -> bool:
	if is_changing_scene:
		return false
	is_changing_scene = true
	change_scene_behind_curtain(scene_path)
	return true

func change_scene_behind_curtain(scene_path: String):
	# The pause menu processes always, so freezing the scene isn't enough
	get_viewport().set_disable_input(true)
	freeze(get_tree().current_scene)
	await tween_progress_to(1.0, COVER_TIME)
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	await get_tree().scene_changed
	var new_scene = get_tree().current_scene
	freeze(new_scene)
	await tween_progress_to(2.0, UNCOVER_TIME)
	progress = 0.0
	unfreeze(new_scene)
	get_viewport().set_disable_input(false)
	is_changing_scene = false

func tween_progress_to(target: float, seconds: float):
	var tween = create_tween().set_ignore_time_scale(true)
	tween.tween_property(self, "progress", target, seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

## The bands sweep in from the left, the ground last; on the way out the
## ground leaves first and the inks follow it
func draw_curtain():
	if progress <= 0.0 or progress >= 2.0:
		return
	var screen = curtain.size
	var count = band_colours.size()
	var span = 1.0 - BAND_STAGGER * (count - 1)
	var travel = screen.x + BAND_SKEW * 2.0
	for i in count:
		var left = -BAND_SKEW
		var right = screen.x + BAND_SKEW
		if progress <= 1.0:
			var own = clampf((progress - BAND_STAGGER * i) / span, 0.0, 1.0)
			right = -BAND_SKEW + travel * own
		else:
			var own = clampf((progress - 1.0 - BAND_STAGGER * (count - 1 - i)) / span, 0.0, 1.0)
			left = -BAND_SKEW + travel * own
		if right - left <= 0.0:
			continue
		curtain.draw_colored_polygon(PackedVector2Array([
			Vector2(left, 0), Vector2(right + BAND_SKEW, 0),
			Vector2(right, screen.y), Vector2(left - BAND_SKEW, screen.y),
		]), band_colours[i])

func freeze(scene: Node):
	if scene != null:
		scene.process_mode = Node.PROCESS_MODE_DISABLED

func unfreeze(scene: Node):
	if is_instance_valid(scene):
		scene.process_mode = Node.PROCESS_MODE_INHERIT
