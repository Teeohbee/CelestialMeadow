extends GameSuite
# The mouse cursor stays out of the way on a TV: hidden from the start, back when the mouse moves, hidden
# again once it's been still a moment. That holds while paused and whatever the game speed.

func move_mouse() -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(400, 300)
	motion.relative = Vector2(5, 0)
	Input.parse_input_event(motion)
	await frames(1)

func real_seconds(duration: float) -> void:
	await get_tree().create_timer(duration, true, false, true).timeout

func before_test() -> void:
	super()
	Cursor.hide_now()

func test_the_cursor_starts_hidden() -> void:
	var fresh: Node = auto_free(Cursor.get_script().new())
	get_tree().root.add_child(fresh)
	assert_bool(fresh.hidden).is_true()

func test_moving_the_mouse_shows_it() -> void:
	await move_mouse()
	assert_bool(Cursor.hidden).is_false()

func test_it_hides_again_after_a_still_moment() -> void:
	await move_mouse()
	await real_seconds(Cursor.IDLE_TIME + 0.3)
	assert_bool(Cursor.hidden).is_true()

func test_moving_keeps_it_showing() -> void:
	await move_mouse()
	await real_seconds(Cursor.IDLE_TIME * 0.7)
	await move_mouse()
	await real_seconds(Cursor.IDLE_TIME * 0.7)
	assert_bool(Cursor.hidden).is_false()

func test_it_still_hides_while_paused_and_sped_up() -> void:
	get_tree().paused = true
	Engine.time_scale = 0.25
	await move_mouse()
	await real_seconds(Cursor.IDLE_TIME + 0.3)
	assert_bool(Cursor.hidden).is_true()
