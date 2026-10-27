extends GameSuite
# Picking a team with the trigger: an analog pull sends a stream of motion events, sometimes several in one
# frame, but each pull moves a seated player on exactly one team.

func trigger(value: float) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.device = 1
	motion.axis = JOY_AXIS_TRIGGER_RIGHT
	motion.axis_value = value
	Input.parse_input_event(motion)

# A full pull: several events past the deadzone in one frame, a few more over the next frames, then release
func pull() -> void:
	for value in [0.55, 0.7, 0.9]:
		trigger(value)
	await frames(1)
	for value in [1.0, 0.95, 1.0]:
		trigger(value)
		await frames(1)
	trigger(0.0)
	await frames(1)

func seated_lobby() -> void:
	await open("res://menu.tscn")
	await frames(2)
	await press("shoot1")

func test_one_pull_advances_one_team() -> void:
	await seated_lobby()
	await pull()
	assert_int(GameState.teams[1]).is_equal(0)

func test_the_next_pull_advances_again() -> void:
	await seated_lobby()
	await pull()
	trigger(0.8)
	await frames(1)
	trigger(0.0)
	await frames(1)
	assert_int(GameState.teams[1]).is_equal(1)
