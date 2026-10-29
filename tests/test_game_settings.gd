extends GdUnitTestSuite
# GameSettings: a missing or broken save never stops the game, only known settings of the right type
# load, numbers are clamped, changes save and survive a reload, and volumes drive the buses.

# One file per process, so suites running side by side in other checkouts don't share it
var scratch_path := "user://test_settings_%d.json" % OS.get_process_id()
var real_path: String

func _settings() -> Node:
	return get_tree().root.get_node("GameSettings")

func _write(contents: Variant) -> void:
	var text: String = contents if contents is String else JSON.stringify(contents)
	var file := FileAccess.open(scratch_path, FileAccess.WRITE)
	file.store_string(text)
	file.close()

func _load(contents: Variant) -> void:
	_write(contents)
	_settings().load_from_disk()

func _bus_db(bus_name: String) -> float:
	return AudioServer.get_bus_volume_db(AudioServer.get_bus_index(bus_name))

func _bus_muted(bus_name: String) -> bool:
	return AudioServer.is_bus_mute(AudioServer.get_bus_index(bus_name))

func before_test() -> void:
	real_path = _settings().save_file_path
	_settings().save_file_path = scratch_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	_settings().load_from_disk()

# Back to the player's settings, only ever read, never written
func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))
	_settings().save_file_path = real_path
	_settings().load_from_disk()

func test_a_missing_file_gives_the_defaults() -> void:
	assert_int(_settings().get_setting("music_volume")).is_equal(8)
	assert_int(_settings().get_setting("sound_volume")).is_equal(8)
	assert_bool(_settings().get_setting("fullscreen")).is_true()
	assert_int(_settings().get_setting("last_mode")).is_equal(0)
	assert_bool(_settings().get_setting("teams")).is_false()
	assert_int(_settings().get_setting("lives")).is_equal(3)
	assert_int(_settings().get_setting("time_minutes")).is_equal(2)

# Saved before the match settings existed: they load as their defaults, the rest as saved
func test_an_older_save_without_the_match_settings_gives_their_defaults() -> void:
	_load({"version": 1, "settings": {"music_volume": 3, "sound_volume": 8, "fullscreen": true, "last_mode": 1}})
	assert_int(_settings().get_setting("music_volume")).is_equal(3)
	assert_int(_settings().get_setting("last_mode")).is_equal(1)
	assert_bool(_settings().get_setting("teams")).is_false()
	assert_int(_settings().get_setting("lives")).is_equal(3)
	assert_int(_settings().get_setting("time_minutes")).is_equal(2)

func test_match_settings_load() -> void:
	_load({"version": 1, "settings": {"teams": true, "lives": 5, "time_minutes": 1}})
	assert_bool(_settings().get_setting("teams")).is_true()
	assert_int(_settings().get_setting("lives")).is_equal(5)
	assert_int(_settings().get_setting("time_minutes")).is_equal(1)

func test_lives_and_time_are_clamped_to_one_to_five() -> void:
	_load({"version": 1, "settings": {"lives": 9, "time_minutes": 0}})
	assert_int(_settings().get_setting("lives")).is_equal(5)
	assert_int(_settings().get_setting("time_minutes")).is_equal(1)
	_load({"version": 1, "settings": {"lives": -2, "time_minutes": 12}})
	assert_int(_settings().get_setting("lives")).is_equal(1)
	assert_int(_settings().get_setting("time_minutes")).is_equal(5)

func test_match_settings_of_the_wrong_type_keep_the_default() -> void:
	_load({"version": 1, "settings": {"teams": 1, "lives": "lots", "time_minutes": false}})
	assert_bool(_settings().get_setting("teams")).is_false()
	assert_int(_settings().get_setting("lives")).is_equal(3)
	assert_int(_settings().get_setting("time_minutes")).is_equal(2)

func test_loading_never_writes_a_file() -> void:
	assert_bool(FileAccess.file_exists(scratch_path)).is_false()

func test_a_corrupt_file_gives_the_defaults() -> void:
	_load("{ this is not json")
	assert_int(_settings().get_setting("music_volume")).is_equal(8)

func test_a_json_array_gives_the_defaults() -> void:
	_load("[1, 2, 3]")
	assert_int(_settings().get_setting("sound_volume")).is_equal(8)

func test_settings_that_arent_a_dictionary_give_the_defaults() -> void:
	_load({"version": 1, "settings": "nope"})
	assert_int(_settings().get_setting("music_volume")).is_equal(8)

func test_good_values_load() -> void:
	_load({"version": 1, "settings": {"music_volume": 3, "fullscreen": false}})
	assert_int(_settings().get_setting("music_volume")).is_equal(3)
	assert_bool(_settings().get_setting("fullscreen")).is_false()

func test_unknown_settings_are_ignored() -> void:
	_load({"version": 1, "settings": {"colour_blind": true}})
	assert_bool(_settings().settings.has("colour_blind")).is_false()

func test_numbers_out_of_range_are_clamped() -> void:
	_load({"version": 1, "settings": {"sound_volume": 42, "music_volume": -4, "last_mode": 99}})
	assert_int(_settings().get_setting("sound_volume")).is_equal(10)
	assert_int(_settings().get_setting("music_volume")).is_equal(0)
	assert_int(_settings().get_setting("last_mode")).is_equal(GameState.MODES.size() - 1)

func test_values_of_the_wrong_type_keep_the_default() -> void:
	_load({"version": 1, "settings": {"music_volume": "loud", "fullscreen": 1}})
	assert_int(_settings().get_setting("music_volume")).is_equal(8)
	assert_bool(_settings().get_setting("fullscreen")).is_true()

func test_setting_a_value_clamps_it() -> void:
	_settings().set_setting("music_volume", 15)
	assert_int(_settings().get_setting("music_volume")).is_equal(10)

func test_setting_a_value_saves_it_with_the_format_version() -> void:
	_settings().set_setting("music_volume", 4)
	# JSON numbers come back as floats
	var saved = JSON.parse_string(FileAccess.get_file_as_string(scratch_path))
	assert_int(int(saved.version)).is_equal(1)
	assert_int(int(saved.settings.music_volume)).is_equal(4)

func test_saved_settings_survive_a_reload() -> void:
	_settings().set_setting("music_volume", 4)
	_settings().set_setting("fullscreen", false)
	_settings().settings = {}
	_settings().load_from_disk()
	assert_int(_settings().get_setting("music_volume")).is_equal(4)
	assert_bool(_settings().get_setting("fullscreen")).is_false()

func test_music_volume_drives_the_music_bus() -> void:
	_settings().set_setting("music_volume", 10)
	assert_float(_bus_db("Music")).is_equal_approx(0.0, 0.001)
	assert_bool(_bus_muted("Music")).is_false()
	_settings().set_setting("music_volume", 5)
	assert_float(_bus_db("Music")).is_equal_approx(linear_to_db(0.5), 0.001)

func test_sound_volume_zero_mutes_and_above_zero_unmutes() -> void:
	_settings().set_setting("sound_volume", 0)
	assert_bool(_bus_muted("Sounds")).is_true()
	_settings().set_setting("sound_volume", 2)
	assert_bool(_bus_muted("Sounds")).is_false()
	assert_float(_bus_db("Sounds")).is_equal_approx(linear_to_db(0.2), 0.001)

func test_loading_applies_the_volumes() -> void:
	_load({"version": 1, "settings": {"music_volume": 1}})
	assert_float(_bus_db("Music")).is_equal_approx(linear_to_db(0.1), 0.001)

func test_a_save_that_cant_be_written_still_changes_the_setting() -> void:
	_settings().save_file_path = "user://no/such/dir/settings.json"
	_settings().set_setting("music_volume", 6)
	assert_int(_settings().get_setting("music_volume")).is_equal(6)

func test_the_game_launches_fullscreen() -> void:
	assert_int(ProjectSettings.get_setting("display/window/size/mode")).is_equal(DisplayServer.WINDOW_MODE_FULLSCREEN)

func test_the_game_draws_at_native_resolution_by_default() -> void:
	assert_bool(_settings().get_setting("render_1080p")).is_false()
	assert_int(get_tree().root.content_scale_mode).is_equal(Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)

func test_a_saved_1080p_draws_at_the_layout_size() -> void:
	_load({"version": 1, "settings": {"render_1080p": true}})
	assert_int(get_tree().root.content_scale_mode).is_equal(Window.CONTENT_SCALE_MODE_VIEWPORT)

func test_loading_native_after_1080p_goes_back_to_native() -> void:
	_load({"version": 1, "settings": {"render_1080p": true}})
	_load({"version": 1, "settings": {"render_1080p": false}})
	assert_int(get_tree().root.content_scale_mode).is_equal(Window.CONTENT_SCALE_MODE_CANVAS_ITEMS)
