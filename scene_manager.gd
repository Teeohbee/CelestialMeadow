extends CanvasLayer

## Every screen change goes through here. Red, amber and teal sweep across
## as one block of equal stripes, red leading. The scene swaps while the block
## covers the screen, and the block carries straight on to uncover it, so each
## ink crosses the screen once. Both scenes are frozen and nothing can be
## pressed while it moves, so a double press changes scene once.

## Speeding up into the swap and slowing out of it, so the block never stops
const COVER_TIME: float = 0.65
const UNCOVER_TIME: float = 0.65

const BAND_SKEW: float = 260.0

var is_changing_scene: bool = false
## How fast the curtain sweeps. Always 1 in the game; tests turn it up
var speed_scale: float = 1.0
## 0 = clear, 1 = covered, 2 = clear again
var progress: float = 0.0:
	set(value):
		progress = value
		curtain.queue_redraw()

var curtain: Control
## Red, amber and teal, leading stripe first
var band_colours: Array[Color] = []

func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in [0, 2, 5]:
		band_colours.append(GameConfig.ENV_INKS[i])
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
	var cover = sweep_to(1.0, COVER_TIME, Tween.EASE_IN)
	# Load the next scene as soon as the block covers the screen, while it's
	# still moving; a slow load holds it at the middle, which is still covered
	while not fully_covered(progress, curtain.size):
		await get_tree().process_frame
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	await get_tree().scene_changed
	var new_scene = get_tree().current_scene
	freeze(new_scene)
	if cover.is_running():
		await cover.finished
	await sweep_to(2.0, UNCOVER_TIME, Tween.EASE_OUT).finished
	progress = 0.0
	unfreeze(new_scene)
	get_viewport().set_disable_input(false)
	is_changing_scene = false

func sweep_to(target: float, seconds: float, easing: Tween.EaseType) -> Tween:
	var tween = create_tween().set_ignore_time_scale(true).set_speed_scale(speed_scale)
	tween.tween_property(self, "progress", target, seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(easing)
	return tween

func draw_curtain():
	for band in bands_at(progress, curtain.size):
		curtain.draw_colored_polygon(PackedVector2Array([
			Vector2(band.left, 0), Vector2(band.right + BAND_SKEW, 0),
			Vector2(band.right, curtain.size.y), Vector2(band.left - BAND_SKEW, curtain.size.y),
		]), band.colour)

## Each stripe to draw at this progress, leading stripe first: its colour and
## the top of its left and right edges (the bottom sits BAND_SKEW further left)
func bands_at(at: float, screen: Vector2) -> Array:
	var bands = []
	if at <= 0.0 or at >= 2.0:
		return bands
	var stripe = stripe_width(screen)
	var count = band_colours.size()
	var left = block_left(at, screen)
	for i in count:
		var stripe_left = left + stripe * (count - 1 - i)
		bands.append({"colour": band_colours[i], "left": stripe_left, "right": stripe_left + stripe})
	return bands

## Whether the block hides the whole screen, slanted edges and all
func fully_covered(at: float, screen: Vector2) -> bool:
	if at <= 0.0 or at >= 2.0:
		return false
	var left = block_left(at, screen)
	return left <= 0.0 and left + stripe_width(screen) * band_colours.size() >= screen.x

## The stripes together are a slant wider than the screen at each side, so
## the block covers it for a stretch either side of the middle
func stripe_width(screen: Vector2) -> float:
	return (screen.x + BAND_SKEW * 2.0) / band_colours.size()

## The top of the block's trailing edge: off the left at 0, centred on the
## screen at 1, off the right at 2
func block_left(at: float, screen: Vector2) -> float:
	var block = stripe_width(screen) * band_colours.size()
	var start = -block - BAND_SKEW
	var middle = (screen.x - block) * 0.5
	var finish = screen.x + BAND_SKEW
	if at <= 1.0:
		return lerpf(start, middle, at)
	return lerpf(middle, finish, at - 1.0)

func freeze(scene: Node):
	if scene != null:
		scene.process_mode = Node.PROCESS_MODE_DISABLED

## Untyped: a freed scene would fail a Node type check before the validity check
func unfreeze(scene):
	if is_instance_valid(scene):
		scene.process_mode = Node.PROCESS_MODE_INHERIT
