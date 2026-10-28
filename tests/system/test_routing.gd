extends GameSuite
# Every way between screens goes through SceneManager, and pressing a button twice still changes scene once:
# title to match setup, lobby launch, the pause menu's Main Menu, Change match and Restart, and the results'
# Rematch, Change match and Main Menu.

func speed() -> float:
	return 4.0

# Runs a step, then says whether it went through SceneManager and how many times the scene changed by the
# time everything settled
func through_manager(step: Callable) -> Array:
	var before := swaps
	await step.call()
	var routed := SceneManager.is_changing_scene
	await settle()
	return [routed, swaps - before]

func paused_round() -> Control:
	await start_round([0, 1])
	await press("pause")
	return scene().get_node("PauseMenu/UI")

func round_results() -> Node:
	await start_round([0, 1])
	kill([1])
	return await results()

func test_the_title_goes_to_match_setup_through_scene_manager() -> void:
	await open("res://title.tscn")
	await seconds(GameConfig.TITLE_INTRO_TIME + 0.2)
	assert_array(await through_manager(func(): await press("shoot2"))).is_equal([true, 1])
	assert_str(scene().name).is_equal("MatchSetup")

func test_match_setup_goes_to_the_lobby_through_scene_manager() -> void:
	await open("res://match_setup.tscn")
	await frames(1)
	assert_array(await through_manager(func(): await press("ui_accept"))).is_equal([true, 1])
	assert_str(scene().name).is_equal("Menu")

func test_the_lobby_has_no_hand_rolled_fade() -> void:
	var menu := await open("res://menu.tscn")
	assert_bool(menu.has_method("fade_in")).is_false()

func test_the_lobby_launches_through_scene_manager() -> void:
	await open("res://menu.tscn")
	var before := swaps
	for seat in [0, 2]:
		await press("shoot%d" % seat)
		await press("shoot%d" % seat)
	assert_bool(await wait_until(func(): return SceneManager.is_changing_scene)).is_true()
	await settle()
	assert_int(swaps - before).is_equal(1)
	assert_str(scene().name).is_equal("Main")

func test_pause_opens() -> void:
	var pause_menu := await paused_round()
	assert_bool(pause_menu.visible).is_true()
	assert_bool(get_tree().paused).is_true()

func test_pausing_main_menu_twice_changes_scene_once() -> void:
	var pause_menu := await paused_round()
	var routed := await through_manager(func():
		pause_menu._on_main_menu_button_pressed()
		pause_menu._on_main_menu_button_pressed())
	assert_array(routed).is_equal([true, 1])
	assert_str(scene().name).is_equal("Title")
	assert_bool(get_tree().paused).is_false()

func test_pausing_change_match_twice_changes_scene_once() -> void:
	var pause_menu := await paused_round()
	var routed := await through_manager(func():
		pause_menu._on_change_match_button_pressed()
		pause_menu._on_change_match_button_pressed())
	assert_array(routed).is_equal([true, 1])
	assert_str(scene().name).is_equal("MatchSetup")
	assert_bool(get_tree().paused).is_false()

func test_pausing_restart_twice_reloads_once() -> void:
	var pause_menu := await paused_round()
	var round := scene()
	var routed := await through_manager(func():
		pause_menu._on_restart_button_pressed()
		pause_menu._on_restart_button_pressed())
	assert_array(routed).is_equal([true, 1])
	assert_str(scene().name).is_equal("Main")
	assert_object(scene()).is_not_same(round)
	assert_bool(get_tree().paused).is_false()

func test_pause_is_ignored_mid_change() -> void:
	var round := await start_round([0, 1])
	SceneManager.go_to("res://main.tscn")
	await frames(1)
	await press("pause")
	assert_bool(round.get_node("PauseMenu/UI").visible).is_false()
	await settle()
	assert_bool(get_tree().paused).is_false()
	assert_bool(scene().get_node("PauseMenu/UI").visible).is_false()

func test_rematch_twice_changes_scene_once() -> void:
	var shown := await round_results()
	var routed := await through_manager(func():
		shown.rematch_button.pressed.emit()
		shown.rematch_button.pressed.emit())
	assert_array(routed).is_equal([true, 1])
	assert_str(scene().name).is_equal("Main")

func test_wins_survive_the_rematch() -> void:
	var shown := await round_results()
	shown.rematch_button.pressed.emit()
	await settle()
	assert_array(GameState.wins).is_equal([1, 0, 0, 0, 0, 0])

func test_main_menu_twice_changes_scene_once_and_unpauses() -> void:
	var shown := await round_results()
	var routed := await through_manager(func():
		shown.menu_button.pressed.emit()
		shown.menu_button.pressed.emit())
	assert_array(routed).is_equal([true, 1])
	assert_str(scene().name).is_equal("Title")
	assert_bool(get_tree().paused).is_false()

func test_change_match_twice_changes_scene_once() -> void:
	var shown := await round_results()
	var routed := await through_manager(func():
		shown.change_button.pressed.emit()
		shown.change_button.pressed.emit())
	assert_array(routed).is_equal([true, 1])
	assert_str(scene().name).is_equal("MatchSetup")
	assert_bool(get_tree().paused).is_false()
