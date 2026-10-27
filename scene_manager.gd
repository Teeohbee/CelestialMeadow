extends CanvasLayer

## Every screen change goes through here. Bands of the palette's inks sweep
## across with the ground colour close behind, the scene swaps underneath,
## and the ground alone slides on to uncover it. Both scenes are frozen and nothing can be pressed
## while it moves, so a double press changes scene once.

const COVER_TIME: float = 0.7
const UNCOVER_TIME: float = 0.6

const BAND_SKEW: float = 260.0
const BAND_STAGGER: float = 0.18

var is_changing_scene: bool = false
## How fast the curtain sweeps. Always 1 in the game; tests turn it up
var speed_scale: float = 1.0
## 0 = clear, 1 = covered, 2 = clear again
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
	var tween = create_tween().set_ignore_time_scale(true).set_speed_scale(speed_scale)
	tween.tween_property(self, "progress", target, seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

## The bands sweep in from the left, the ground last, and the inks stay
## under it. Only the ground uncovers, so the new screen never sees them.
func draw_curtain():
	for band in bands_at(progress, curtain.size):
		curtain.draw_colored_polygon(PackedVector2Array([
			Vector2(band.left, 0), Vector2(band.right + BAND_SKEW, 0),
			Vector2(band.right, curtain.size.y), Vector2(band.left - BAND_SKEW, curtain.size.y),
		]), band.colour)

## Each band to draw at this progress, bottom first: its colour and the top
## of its left and right edges (the bottom sits BAND_SKEW further left)
func bands_at(at: float, screen: Vector2) -> Array:
	var bands = []
	if at <= 0.0 or at >= 2.0:
		return bands
	var travel = screen.x + BAND_SKEW * 2.0
	if at > 1.0:
		bands.append({"colour": band_colours[-1], "left": -BAND_SKEW + travel * (at - 1.0), "right": screen.x + BAND_SKEW})
		return bands
	var count = band_colours.size()
	var span = 1.0 - BAND_STAGGER * (count - 1)
	for i in count:
		var own = clampf((at - BAND_STAGGER * i) / span, 0.0, 1.0)
		var right = -BAND_SKEW + travel * own
		if right > -BAND_SKEW:
			bands.append({"colour": band_colours[i], "left": -BAND_SKEW, "right": right})
	return bands

func freeze(scene: Node):
	if scene != null:
		scene.process_mode = Node.PROCESS_MODE_DISABLED

## Untyped: a freed scene would fail a Node type check before the validity check
func unfreeze(scene):
	if is_instance_valid(scene):
		scene.process_mode = Node.PROCESS_MODE_INHERIT
