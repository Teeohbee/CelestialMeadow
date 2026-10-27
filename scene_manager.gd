extends CanvasLayer

## Every screen change goes through here. A curtain covers the screen, the
## scene swaps underneath, and the curtain lifts. Both scenes are frozen and
## nothing can be pressed while it moves, so a double press changes scene once.

const COVER_TIME: float = 0.35
const UNCOVER_TIME: float = 0.4

var is_changing_scene: bool = false

var curtain: ColorRect

func _ready():
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	curtain = ColorRect.new()
	curtain.color = GameConfig.GROUND
	curtain.modulate.a = 0.0
	curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	curtain.set_anchors_preset(Control.PRESET_FULL_RECT)
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
	await tween_curtain_to(1.0, COVER_TIME)
	get_tree().paused = false
	get_tree().change_scene_to_file(scene_path)
	await get_tree().scene_changed
	var new_scene = get_tree().current_scene
	freeze(new_scene)
	await tween_curtain_to(0.0, UNCOVER_TIME)
	unfreeze(new_scene)
	get_viewport().set_disable_input(false)
	is_changing_scene = false

func tween_curtain_to(alpha: float, seconds: float):
	var tween = create_tween().set_ignore_time_scale(true)
	tween.tween_property(curtain, "modulate:a", alpha, seconds) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

func freeze(scene: Node):
	if scene != null:
		scene.process_mode = Node.PROCESS_MODE_DISABLED

func unfreeze(scene: Node):
	if is_instance_valid(scene):
		scene.process_mode = Node.PROCESS_MODE_INHERIT
