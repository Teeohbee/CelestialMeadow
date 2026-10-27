@abstract
class_name GameSuite
extends GdUnitTestSuite
# Base for system suites that drive the real screens. Every test starts on a fresh GameState, default
# settings saved somewhere scratch, no screen change in flight, nothing paused and no music, so nothing one
# test does can leak into the next. Nothing here writes the player's own settings.json.

# One file per process, so suites running side by side in other checkouts don't share it
var scratch_path := "user://test_settings_%d.json" % OS.get_process_id()
var real_path: String

func before_test() -> void:
	reset_game_state()
	real_path = GameSettings.save_file_path
	GameSettings.save_file_path = scratch_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	GameSettings.load_from_disk()

func after_test() -> void:
	await settle()
	get_tree().unload_current_scene()
	get_tree().paused = false
	Engine.time_scale = 1.0
	Music.stop()
	if Music.duck_tween:
		Music.duck_tween.kill()
	Music.duck_effect.volume_db = 0.0
	for player in Sound.players:
		player.stop()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	GameSettings.save_file_path = real_path
	GameSettings.load_from_disk()
	reset_game_state()
	await get_tree().process_frame

# Every GameState variable back to what a fresh copy of the script starts with
func reset_game_state() -> void:
	var fresh: Node = GameState.get_script().new()
	for property in fresh.get_script().get_script_property_list():
		if property.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			GameState.set(property.name, fresh.get(property.name))
	fresh.free()

func scene() -> Node:
	return get_tree().current_scene

# Straight to a screen, the way booting into it would, and waits for it to be ready
func open(path: String) -> Node:
	get_tree().change_scene_to_file(path)
	await get_tree().scene_changed
	return scene()

# Waits for any SceneManager change to finish
func settle() -> void:
	while SceneManager.is_changing_scene:
		await get_tree().process_frame

func frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

# Game time, so it speeds up with Engine.time_scale. SceneManager's curtain ignores time scale; wait for it
# with settle().
func seconds(duration: float) -> void:
	var waited := 0.0
	while waited < duration:
		await get_tree().process_frame
		waited += get_process_delta_time()

func press(action: String) -> void:
	var down := InputEventAction.new()
	down.action = action
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up := InputEventAction.new()
	up.action = action
	Input.parse_input_event(up)
	await get_tree().process_frame

func key(code: Key) -> void:
	var down := InputEventKey.new()
	down.keycode = code
	down.physical_keycode = code
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up: InputEventKey = down.duplicate()
	up.pressed = false
	Input.parse_input_event(up)
	await get_tree().process_frame
