extends GameSuite
# The trigger in the lobby: teams are picked with the D-pad now, so a pull of RT, a stream of motion events,
# changes nothing.

func trigger(value: float) -> void:
	var motion := InputEventJoypadMotion.new()
	motion.device = 1
	motion.axis = JOY_AXIS_TRIGGER_RIGHT
	motion.axis_value = value
	Input.parse_input_event(motion)

func pull() -> void:
	for value in [0.55, 0.7, 0.9, 1.0]:
		trigger(value)
		await frames(1)
	trigger(0.0)
	await frames(1)

func test_a_pull_changes_no_team() -> void:
	GameSettings.set_setting("teams", true)
	await open("res://menu.tscn")
	await frames(2)
	await press("shoot1")
	await press("shoot1")
	await pull()
	assert_int(GameState.teams[1]).is_equal(0)
	assert_int(scene().cards[1].state).is_equal(2)
