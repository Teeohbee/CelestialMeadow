@abstract
class_name GameSuite
extends GdUnitTestSuite
# Base for system suites that drive the real screens. Every test starts on a fresh GameState, default
# settings saved somewhere scratch, no screen change in flight, nothing paused and no music, so nothing one
# test does can leak into the next. Nothing here writes the player's own settings.json.

# One file per process, so suites running side by side in other checkouts don't share it
var scratch_path := "user://test_settings_%d.json" % OS.get_process_id()
var real_path: String
# How many times the scene has changed this test
var swaps := 0
var real_ticks: int
var real_max_steps: int
var real_aspect: Window.ContentScaleAspect

# How much faster than real time a suite runs; override to speed one up. Physics ticks go up by the same
# factor, so every physics step is still 1/60s of game time: more steps, not bigger ones. SceneManager's
# curtain ignores time scale, so it's sped up to match.
func speed() -> float:
	return 1.0

func before_test() -> void:
	swaps = 0
	# Headless runs in a square window, which the expand aspect would turn into a 1920x1920 arena. Every
	# suite plays on the 16:9 design screen; test_taller_arena covers 16:10.
	real_aspect = get_tree().root.content_scale_aspect
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	real_ticks = Engine.physics_ticks_per_second
	real_max_steps = Engine.max_physics_steps_per_frame
	Engine.time_scale = speed()
	Engine.physics_ticks_per_second = roundi(real_ticks * speed())
	Engine.max_physics_steps_per_frame = roundi(real_max_steps * speed())
	SceneManager.speed_scale = speed()
	get_tree().scene_changed.connect(_count_swap)
	reset_game_state()
	real_path = GameSettings.save_file_path
	GameSettings.save_file_path = scratch_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	GameSettings.load_from_disk()

func after_test() -> void:
	await settle()
	get_tree().scene_changed.disconnect(_count_swap)
	get_tree().unload_current_scene()
	get_tree().paused = false
	Engine.time_scale = 1.0
	get_tree().root.content_scale_aspect = real_aspect
	Engine.physics_ticks_per_second = real_ticks
	Engine.max_physics_steps_per_frame = real_max_steps
	SceneManager.speed_scale = 1.0
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

func _count_swap() -> void:
	swaps += 1

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

# Game time, so it speeds up with speed(). Wait for SceneManager's curtain with settle().
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

# A real pad button, so every action bound to it fires together
func pad(button: JoyButton, device := 0) -> void:
	var down := InputEventJoypadButton.new()
	down.device = device
	down.button_index = button
	down.pressed = true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up: InputEventJoypadButton = down.duplicate()
	up.pressed = false
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

# Waits up to timeout seconds of game time for condition to hold, and says whether it did
func wait_until(condition: Callable, timeout := 10.0) -> bool:
	var waited := 0.0
	while not condition.call():
		if waited >= timeout:
			return false
		await get_tree().process_frame
		waited += get_process_delta_time()
	return true

func ships() -> Array[Node]:
	return get_tree().get_nodes_in_group("players")

# Waits out the countdown until the ships are flying. They spawn frozen as the round opens, so being there
# isn't enough.
func ships_launched() -> bool:
	return await wait_until(func(): return scene().get("game_started") == true and not ships().is_empty())

# Opens a round straight away with these seats, past its countdown
func start_round(seats: Array[int], dummies: Array[int] = []) -> Node:
	GameState.start_session(seats, dummies)
	var round := await open("res://main.tscn")
	await ships_launched()
	return round

func kill(numbers: Array[int]) -> void:
	for ship in ships():
		if ship.player_number in numbers:
			ship.lives = 1
			ship.destroy()

# Waits for the round's results to show and take input
func results() -> Node:
	await wait_until(func(): return scene().has_node("Results") and not scene().get_node("Results").locked)
	return scene().get_node_or_null("Results")
