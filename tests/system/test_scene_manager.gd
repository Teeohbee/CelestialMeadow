extends GameSuite
# SceneManager: one screen change at a time behind the curtain. Both scenes are frozen and input is swallowed
# while it moves, it works from a paused tree and leaves it unpaused, it ignores time scale, and a scene freed
# behind its back doesn't wedge it. The curtain is red, amber and teal as one block of equal stripes, red
# leading, sweeping straight across; the scene swaps only while the block covers the whole screen.

# Waits until the curtain has swapped the scene underneath, before it uncovers
func swapped_from(leaving: Node) -> void:
	await wait_until(func(): return scene() != leaving and scene() != null)

func test_scene_manager_processes_while_paused() -> void:
	assert_int(SceneManager.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)

func test_go_to_starts_a_change() -> void:
	await open("res://menu.tscn")
	assert_bool(SceneManager.go_to("res://main.tscn")).is_true()
	assert_bool(SceneManager.is_changing_scene).is_true()

func test_a_second_go_to_is_refused_while_one_is_in_flight() -> void:
	await open("res://menu.tscn")
	SceneManager.go_to("res://main.tscn")
	assert_bool(SceneManager.go_to("res://title.tscn")).is_false()

func test_the_old_scene_is_frozen_while_covering() -> void:
	var old := await open("res://menu.tscn")
	SceneManager.go_to("res://main.tscn")
	await frames(1)
	assert_int(old.process_mode).is_equal(Node.PROCESS_MODE_DISABLED)

func test_input_is_swallowed_while_covering() -> void:
	var old := await open("res://menu.tscn")
	SceneManager.go_to("res://main.tscn")
	await frames(1)
	await press("shoot3")
	assert_int(old.cards[3].state).is_equal(0)

func test_it_swaps_to_the_requested_scene() -> void:
	var old := await open("res://menu.tscn")
	SceneManager.go_to("res://main.tscn")
	await swapped_from(old)
	assert_str(scene().name).is_equal("Main")

func test_the_new_scene_is_frozen_while_uncovering() -> void:
	var old := await open("res://menu.tscn")
	SceneManager.go_to("res://main.tscn")
	await swapped_from(old)
	assert_int(scene().process_mode).is_equal(Node.PROCESS_MODE_DISABLED)

func test_the_new_scene_is_unfrozen_once_clear() -> void:
	await open("res://menu.tscn")
	SceneManager.go_to("res://main.tscn")
	await settle()
	assert_int(scene().process_mode).is_equal(Node.PROCESS_MODE_INHERIT)

func test_the_scene_changes_exactly_once() -> void:
	await open("res://menu.tscn")
	swaps = 0
	SceneManager.go_to("res://main.tscn")
	await settle()
	assert_int(swaps).is_equal(1)

func test_it_works_from_a_paused_tree_and_leaves_it_unpaused() -> void:
	await open("res://main.tscn")
	get_tree().paused = true
	assert_bool(SceneManager.go_to("res://menu.tscn")).is_true()
	await settle()
	assert_str(scene().name).is_equal("Menu")
	assert_bool(get_tree().paused).is_false()

func test_input_is_swallowed_while_uncovering() -> void:
	var old := await open("res://menu.tscn")
	SceneManager.go_to("res://menu.tscn")
	await swapped_from(old)
	await press("shoot4")
	await settle()
	assert_int(scene().cards[4].state).is_equal(0)

func test_input_reaches_the_scene_afterwards() -> void:
	await open("res://menu.tscn")
	SceneManager.go_to("res://menu.tscn")
	await settle()
	await press("shoot4")
	assert_int(scene().cards[4].state).is_equal(1)

func test_it_ignores_time_scale() -> void:
	await open("res://menu.tscn")
	Engine.time_scale = 0.1
	var started := Time.get_ticks_msec()
	SceneManager.go_to("res://title.tscn")
	await settle()
	assert_int(Time.get_ticks_msec() - started).is_less(2000)

func test_it_recovers_when_the_new_scene_is_freed_mid_change() -> void:
	var old := await open("res://menu.tscn")
	SceneManager.go_to("res://menu.tscn")
	await swapped_from(old)
	get_tree().change_scene_to_file("res://title.tscn")
	await settle()
	assert_bool(SceneManager.is_changing_scene).is_false()
	assert_bool(SceneManager.go_to("res://menu.tscn")).is_true()

func test_a_higher_speed_scale_sweeps_the_curtain_faster() -> void:
	await open("res://menu.tscn")
	SceneManager.speed_scale = 4.0
	var started := Time.get_ticks_msec()
	SceneManager.go_to("res://title.tscn")
	await settle()
	SceneManager.speed_scale = 1.0
	assert_int(Time.get_ticks_msec() - started).is_less(500)

const SCREEN := Vector2(1920, 1080)
const INKS := [GameConfig.ENV_INKS[0], GameConfig.ENV_INKS[2], GameConfig.ENV_INKS[5]]

func colours(bands: Array) -> Array:
	return bands.map(func(band): return band.colour)

func test_nothing_is_drawn_when_clear() -> void:
	assert_array(SceneManager.bands_at(0.0, SCREEN)).is_empty()
	assert_array(SceneManager.bands_at(2.0, SCREEN)).is_empty()

func test_the_curtain_is_the_three_inks_all_the_way() -> void:
	for at in [0.2, 0.6, 1.0, 1.4, 1.8]:
		assert_array(colours(SceneManager.bands_at(at, SCREEN))).is_equal(INKS)

func test_the_stripes_are_equal() -> void:
	var widths: Array = SceneManager.bands_at(0.7, SCREEN).map(func(band): return band.right - band.left)
	assert_float(widths[0]).is_equal_approx(widths[1], 0.01)
	assert_float(widths[1]).is_equal_approx(widths[2], 0.01)

func test_red_leads_and_teal_trails() -> void:
	var bands: Array = SceneManager.bands_at(0.7, SCREEN)
	assert_float(bands[0].left).is_greater(bands[1].left)
	assert_float(bands[1].left).is_greater(bands[2].left)

func test_the_screen_is_covered_halfway() -> void:
	assert_bool(SceneManager.fully_covered(1.0, SCREEN)).is_true()
	assert_bool(SceneManager.fully_covered(0.5, SCREEN)).is_false()
	assert_bool(SceneManager.fully_covered(1.5, SCREEN)).is_false()

func test_the_block_keeps_moving_through_the_middle() -> void:
	var before: float = SceneManager.bands_at(0.98, SCREEN)[2].left
	var after: float = SceneManager.bands_at(1.02, SCREEN)[2].left
	assert_float(after).is_greater(before)

func test_the_scene_only_swaps_under_full_cover() -> void:
	await open("res://menu.tscn")
	var covered_at_swap := []
	var check := func(): covered_at_swap.append(SceneManager.fully_covered(SceneManager.progress, SceneManager.curtain.size))
	get_tree().scene_changed.connect(check)
	SceneManager.go_to("res://main.tscn")
	await settle()
	get_tree().scene_changed.disconnect(check)
	assert_array(covered_at_swap).is_equal([true])
