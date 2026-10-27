extends GameSuite
# The dummy pilot combo: rotate left, right, left, right on an empty seat's pad toggles the dummy pilot, so one
# controller can test a round on a release build. Seated pilots, the wrong order or a slow combo do nothing,
# and once on it stays on for the session.

var menu: Node

func combo(seat: int, steps: Array[String] = ["left", "right", "left", "right"]) -> void:
	for step in steps:
		await press("rotate_%s%d" % [step, seat])

# The lobby as a release build sees it: no dummy pilot
func lobby() -> void:
	menu = await open("res://menu.tscn")
	GameState.dummy_pilot = false
	await frames(2)

func status() -> String:
	return menu.status.text

func test_the_dummy_pilot_defaults_to_the_build_type() -> void:
	assert_bool(GameState.dummy_pilot).is_equal(OS.is_debug_build())

func test_a_lone_ready_pilot_waits_on_a_release_build() -> void:
	await lobby()
	await press("shoot0")
	await press("shoot0")
	await frames(1)
	assert_str(status()).is_equal("Waiting for another pilot")

func test_a_seated_pilots_presses_dont_unlock_it() -> void:
	await lobby()
	await press("shoot0")
	await combo(0)
	assert_bool(GameState.dummy_pilot).is_false()

func test_the_wrong_order_does_nothing() -> void:
	await lobby()
	await combo(2, ["right", "left", "right", "left"])
	assert_bool(GameState.dummy_pilot).is_false()

func test_too_slow_does_nothing() -> void:
	await lobby()
	await combo(2, ["left", "right", "left"])
	# The combo window is real time; age the start rather than wait it out
	menu.combo_started_at[2] -= menu.DUMMY_COMBO_WINDOW_MS + 200
	await combo(2, ["right"])
	assert_bool(GameState.dummy_pilot).is_false()

func test_the_combo_on_an_empty_seat_turns_the_dummy_on() -> void:
	await lobby()
	await combo(2)
	await frames(1)
	assert_bool(GameState.dummy_pilot).is_true()
	assert_str(status()).is_equal("Dummy pilot on")

func test_the_combo_doesnt_seat_anyone() -> void:
	await lobby()
	await combo(2)
	assert_int(menu.cards[2].state).is_equal(0)

func test_the_combo_again_turns_it_off() -> void:
	await lobby()
	await combo(2)
	await combo(2)
	await frames(1)
	assert_bool(GameState.dummy_pilot).is_false()
	assert_str(status()).is_equal("Dummy pilot off")

func test_any_empty_seats_pad_can_do_it() -> void:
	await lobby()
	await combo(3)
	assert_bool(GameState.dummy_pilot).is_true()

func test_once_on_a_lone_ready_pilot_launches_against_a_dummy() -> void:
	await lobby()
	await combo(3)
	# The notice lasts two seconds of real time; clear it rather than wait it out
	menu.notice_until = 0
	await press("shoot0")
	await press("shoot0")
	await frames(1)
	assert_str(status()).starts_with("Launching in").ends_with("against a dummy")
	await seconds(GameConfig.TITLE_LAUNCH_DELAY + 0.2)
	await settle()
	assert_str(scene().name).is_equal("Main")
	assert_array(GameState.dummies).has_size(1)

func test_it_stays_on_back_in_the_lobby() -> void:
	await lobby()
	await combo(3)
	SceneManager.go_to("res://main.tscn")
	await settle()
	SceneManager.go_to("res://menu.tscn")
	await settle()
	assert_bool(GameState.dummy_pilot).is_true()
