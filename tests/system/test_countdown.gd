extends GameSuite
# The round's 3-2-1 waits for the curtain to lift, so the 3 isn't spent behind it, and every number gets the
# same second on screen.

func countdown() -> Node:
	return scene().get_node("Countdown")

func arrive_by_curtain() -> void:
	GameState.start_session([0, 1] as Array[int])
	await open("res://menu.tscn")
	SceneManager.go_to("res://main.tscn")

func test_it_waits_behind_the_curtain() -> void:
	var old := scene()
	await arrive_by_curtain()
	await wait_until(func(): return scene() != old and scene() != null and scene().name == "Main")
	assert_bool(countdown().is_counting).is_false()

func test_it_starts_once_the_curtain_lifts() -> void:
	await arrive_by_curtain()
	await settle()
	await frames(1)
	assert_bool(countdown().is_counting).is_true()
	assert_int(countdown().count).is_equal(3)

func test_the_three_holds_as_long_as_the_two() -> void:
	await arrive_by_curtain()
	await settle()
	await seconds(0.8)
	assert_int(countdown().count).is_equal(3)
	await seconds(0.4)
	assert_int(countdown().count).is_equal(2)
	await seconds(0.8)
	assert_int(countdown().count).is_equal(2)
