extends GameSuite
# The pause menu in a round: Start (Menu) on any pad or Esc opens a poster panel over a dim, grainy wash, it
# pops in, the music ducks and Resume has focus. Start again or Resume carries on. Pausing during the
# countdown holds it.

var pause_menu: Control

func speed() -> float:
	return 4.0

func paused_round() -> void:
	await start_round([0, 1])
	pause_menu = scene().get_node("PauseMenu/UI")
	await pad(JOY_BUTTON_START, 0)

# Tweens that ignore time scale run in real seconds whatever speed() is
func real_seconds(duration: float) -> void:
	await get_tree().create_timer(duration, true, false, true).timeout

func test_start_pauses_the_round() -> void:
	await paused_round()
	assert_bool(pause_menu.visible).is_true()
	assert_bool(get_tree().paused).is_true()

func test_start_again_resumes() -> void:
	await paused_round()
	await pad(JOY_BUTTON_START, 1)
	assert_bool(pause_menu.visible).is_false()
	assert_bool(get_tree().paused).is_false()

func test_resume_has_focus_and_resumes() -> void:
	await paused_round()
	var resume: Button = pause_menu.resume_button
	assert_object(get_viewport().gui_get_focus_owner()).is_same(resume)
	resume.pressed.emit()
	assert_bool(get_tree().paused).is_false()

func test_the_panel_sits_in_the_middle_of_the_screen() -> void:
	await paused_round()
	await real_seconds(0.5)
	var screen := get_viewport().get_visible_rect().size
	var panel: Control = pause_menu.panel
	assert_vector(panel.get_global_rect().get_center()).is_equal_approx(screen * 0.5, Vector2(2, 2))
	assert_float(panel.size.x).is_greater(200.0)

func test_the_panel_pops_in() -> void:
	await start_round([0, 1])
	pause_menu = scene().get_node("PauseMenu/UI")
	pause_menu.toggle_pause()
	assert_float(pause_menu.panel.scale.x).is_less(1.0)
	assert_float(pause_menu.panel.modulate.a).is_less(0.1)
	await real_seconds(0.5)
	assert_vector(pause_menu.panel.scale).is_equal_approx(Vector2.ONE, Vector2(0.001, 0.001))

func test_the_round_shows_through_a_grainy_wash() -> void:
	await paused_round()
	assert_bool(pause_menu.get_node("Grain").visible).is_true()
	var dim: ColorRect = pause_menu.get_node("Dim")
	assert_float(dim.color.a).is_between(0.3, 0.9)

func test_the_hint_shows_the_start_glyph() -> void:
	await paused_round()
	assert_str(pause_menu.hint.text).contains("{menu}")

func test_pausing_during_the_countdown_holds_it() -> void:
	GameState.start_session([0, 1] as Array[int])
	await open("res://main.tscn")
	await frames(2)
	pause_menu = scene().get_node("PauseMenu/UI")
	await pad(JOY_BUTTON_START, 0)
	await real_seconds(1.5)
	assert_bool(scene().game_started).is_false()
	assert_int(scene().get_node("Countdown").count).is_equal(3)
	await pad(JOY_BUTTON_START, 0)
	assert_bool(await ships_launched()).is_true()
