extends GameSuite
# The splash sting: the game boots to it, the pilots' inks sweep in under a credit, and after a couple of
# seconds it hands over to the title card through SceneManager. Any button skips it, once; moving a stick or
# the mouse doesn't.

func speed() -> float:
	return 4.0

func splash() -> Node:
	var shown := await open("res://splash.tscn")
	await frames(2)
	return shown

func test_the_game_boots_to_the_splash() -> void:
	assert_str(ProjectSettings.get_setting("application/run/main_scene")).is_equal("res://splash.tscn")

func test_it_credits_the_maker() -> void:
	var shown := await splash()
	assert_str(shown.credit.text).is_equal("A TOBY CLARKE GAME")

func test_the_inks_sweep_in() -> void:
	var shown := await splash()
	assert_float(shown.sweep).is_less(1.0)
	await seconds(GameConfig.SPLASH_TIME * 0.6)
	assert_float(shown.sweep).is_equal(1.0)

func test_it_hands_over_to_the_title_on_its_own() -> void:
	await splash()
	assert_bool(await wait_until(func(): return SceneManager.is_changing_scene, GameConfig.SPLASH_TIME + 1.0)).is_true()
	await settle()
	assert_str(scene().name).is_equal("Title")
	assert_int(swaps).is_equal(2)

func test_a_button_skips_it() -> void:
	await splash()
	await pad(JOY_BUTTON_A, 2)
	assert_bool(SceneManager.is_changing_scene).is_true()
	await settle()
	assert_str(scene().name).is_equal("Title")

func test_mashing_skips_once() -> void:
	await splash()
	await pad(JOY_BUTTON_A, 2)
	await pad(JOY_BUTTON_B, 3)
	await key(KEY_SPACE)
	await settle()
	await seconds(GameConfig.SPLASH_TIME)
	await settle()
	assert_int(swaps).is_equal(2)
	assert_str(scene().name).is_equal("Title")

func test_moving_the_mouse_or_a_stick_doesnt_skip() -> void:
	await splash()
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(10, 0)
	Input.parse_input_event(motion)
	var stick := InputEventJoypadMotion.new()
	stick.axis = JOY_AXIS_LEFT_X
	stick.axis_value = 1.0
	Input.parse_input_event(stick)
	await frames(2)
	assert_bool(SceneManager.is_changing_scene).is_false()

func test_the_skipping_press_doesnt_carry_into_the_title() -> void:
	await splash()
	await pad(JOY_BUTTON_A, 0)
	await settle()
	await frames(2)
	assert_int(GameState.join_on_arrival).is_equal(-1)
	assert_str(scene().name).is_equal("Title")
