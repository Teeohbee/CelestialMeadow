extends GameSuite
# SceneManager: one screen change at a time behind the curtain. Both scenes are frozen and input is swallowed
# while it moves, it works from a paused tree and leaves it unpaused, it ignores time scale, and a scene freed
# behind its back doesn't wedge it.

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
