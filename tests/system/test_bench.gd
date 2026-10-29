extends GameSuite
# The benchmark runs every stage, shows a line for each, leaves the resolution as the setting has it, and
# goes back to the title once it's done.

func bench() -> Node:
	var scene := await open("res://bench.tscn")
	scene.time_scale = 0.05
	return scene

func finished(scene: Node) -> bool:
	return await wait_until(func(): return scene.done, 15.0)

func test_it_runs_every_stage_and_shows_a_line_for_each() -> void:
	var scene := await bench()
	assert_bool(await finished(scene)).is_true()
	for stage in scene.stages:
		assert_str(scene.label.text).contains(stage.name)
	assert_str(scene.label.text).contains("fps")

func test_it_leaves_the_resolution_as_set() -> void:
	var scene := await bench()
	await finished(scene)
	assert_int(get_tree().root.content_scale_mode).is_equal(Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)

func test_b_goes_back_to_the_title_when_done() -> void:
	var scene := await bench()
	await finished(scene)
	await press("ui_cancel")
	await settle()
	assert_str(scene().name).is_equal("Title")

func test_the_benchmark_row_opens_it() -> void:
	await open("res://menu.tscn")
	await frames(2)
	var options: Control = scene().get_node("Options")
	await pad(JOY_BUTTON_BACK, 3)
	await press("ui_up")
	await press("ui_up")
	assert_str(options.rows[options.selected].name).is_equal("Benchmark")
	await press("ui_accept")
	await wait_until(func(): return scene() != null and scene().name == "Bench")
	assert_str(scene().name).is_equal("Bench")
