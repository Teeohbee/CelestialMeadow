extends GameSuite
# The frame-rate readout stays out of the way until F3 asks for it, then shows fps, the slowest frame and
# where the time goes. It keeps updating while paused.

func before_test() -> void:
	super()
	PerfReadout.visible = false

func after_test() -> void:
	PerfReadout.visible = false
	await super()

func test_it_starts_hidden() -> void:
	var fresh: Node = auto_free(PerfReadout.get_script().new())
	get_tree().root.add_child(fresh)
	assert_bool(fresh.visible).is_false()

func test_f3_toggles_it() -> void:
	await key(KEY_F3)
	assert_bool(PerfReadout.visible).is_true()
	await key(KEY_F3)
	assert_bool(PerfReadout.visible).is_false()

func test_it_shows_where_the_time_goes() -> void:
	await key(KEY_F3)
	await seconds(PerfReadout.REFRESH_TIME + 0.2)
	for part in ["fps", "worst", "script", "physics", "render cpu", "gpu", "drawn"]:
		assert_str(PerfReadout.label.text).contains(part)

func test_it_draws_over_the_curtain() -> void:
	assert_int(PerfReadout.layer).is_greater(SceneManager.layer)

func test_it_updates_while_paused() -> void:
	await key(KEY_F3)
	await seconds(PerfReadout.REFRESH_TIME + 0.2)
	PerfReadout.label.text = ""
	get_tree().paused = true
	await get_tree().create_timer(PerfReadout.REFRESH_TIME + 0.2, true, false, true).timeout
	assert_str(PerfReadout.label.text).contains("fps")
