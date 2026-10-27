extends GameSuite
# The lobby opens on the mode last played, saved when a round launches, not when someone flicks through modes.

var menu: Node

# A lobby whose saved mode is Time Attack, with the dummy on so one pilot can launch
func lobby_after_time_attack() -> void:
	GameSettings.set_setting("last_mode", 1)
	menu = await open("res://menu.tscn")
	GameState.dummy_pilot = true
	await frames(2)

# Seats pilot 0 and flicks back to Last Ship Standing
func change_mode() -> void:
	await press("shoot0")
	await press("rotate_right0")

func launch() -> void:
	await press("shoot0")
	await seconds(GameConfig.TITLE_LAUNCH_DELAY + 0.2)
	await settle()

func test_the_lobby_opens_on_the_last_mode_played() -> void:
	await lobby_after_time_attack()
	assert_int(GameState.mode_index).is_equal(1)
	assert_str(menu.mode_label.text).contains("Time Attack")

func test_flicking_through_modes_doesnt_save() -> void:
	await lobby_after_time_attack()
	await change_mode()
	assert_int(GameState.mode_index).is_equal(0)
	assert_int(GameSettings.get_setting("last_mode")).is_equal(1)

func test_launching_saves_the_mode_to_disk() -> void:
	await lobby_after_time_attack()
	await change_mode()
	await launch()
	assert_str(scene().name).is_equal("Main")
	assert_int(GameSettings.get_setting("last_mode")).is_equal(0)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(scratch_path))
	assert_int(int(saved.settings.last_mode)).is_equal(0)

func test_the_lobby_keeps_it_after_a_round() -> void:
	await lobby_after_time_attack()
	await change_mode()
	await launch()
	SceneManager.go_to("res://menu.tscn")
	await settle()
	assert_int(GameState.mode_index).is_equal(0)
	assert_str(scene().mode_label.text).contains("Last Ship Standing")
