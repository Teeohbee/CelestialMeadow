extends GameSuite
# Music: two players on the Music bus crossfade between tracks, asking for the track already playing does
# nothing, fades and ducking run while paused, and the screens ask for the right track: the composed menu
# theme on the title and lobby, Voxel Revolution in the round, carrying on through a rematch.

func before_test() -> void:
	super()
	silence()

func after_test() -> void:
	Music.tracks.erase("test")
	await super()
	silence()

# Stops everything at once. Music.stop() fades, which would still be sounding in the next test
func silence() -> void:
	for tween in Music.fades.values():
		tween.kill()
	Music.fades.clear()
	for player in Music.players:
		player.stop()
		player.volume_db = Music.SILENT_DB
	Music.current_track = ""
	Music.current_track_started = false

func playing() -> Array[AudioStreamPlayer]:
	return Music.players.filter(func(p): return p.playing)

func duck_db() -> float:
	return Music.duck_effect.volume_db

func crossfade() -> void:
	await seconds(Music.CROSSFADE_SECONDS + 0.2)

func ducking() -> void:
	await seconds(Music.DUCK_SECONDS + 0.2)

# The menu theme is composed on a background thread at boot
func menu_theme() -> AudioStreamWAV:
	await wait_until(func(): return Music.tracks.menu.stream != null, 20.0)
	return Music.tracks.menu.stream

# A looping tone to fade to and from
func add_test_track() -> void:
	var tone: AudioStreamOggVorbis = load("res://audio/laser.ogg").duplicate()
	tone.loop = true
	Music.tracks["test"] = {"stream": tone, "volume_db": 0.0}

func round_player() -> AudioStreamPlayer:
	Music.play_track("round")
	await frames(2)
	return playing()[0]

func test_music_processes_while_paused() -> void:
	assert_int(Music.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)

func test_there_are_two_players_for_crossfading() -> void:
	assert_int(Music.players.size()).is_equal(2)

func test_the_players_are_on_the_music_bus() -> void:
	for player in Music.players:
		assert_str(player.bus).is_equal("Music")

func test_the_menu_theme_starts_once_composed() -> void:
	var theme := await menu_theme()
	Music.tracks.menu.stream = null
	Music.play_track("menu")
	await frames(2)
	assert_str(Music.current_track).is_equal("menu")
	assert_array(playing()).is_empty()
	Music.tracks.menu.stream = theme
	await frames(2)
	assert_int(playing().size()).is_equal(1)

func test_the_menu_theme_loops() -> void:
	assert_int((await menu_theme()).loop_mode).is_equal(AudioStreamWAV.LOOP_FORWARD)

func test_the_menu_loop_is_whole_bars() -> void:
	var bars := (await menu_theme()).get_length() / (4 * 60.0 / Music.MENU_THEME.beats_per_minute)
	assert_float(bars).is_equal_approx(roundf(bars), 0.001)

func test_the_same_seed_gives_the_same_tune() -> void:
	var theme := await menu_theme()
	assert_bool(Music.compose(Music.MENU_THEME).data == theme.data).is_true()

func test_the_menu_theme_is_audible_and_doesnt_clip() -> void:
	var data := (await menu_theme()).data
	var loudest := 0.0
	for i in range(0, data.size(), 2):
		loudest = maxf(loudest, absf(data.decode_s16(i)) / 32767.0)
	assert_float(loudest).is_between(0.31, 0.98)

func test_stop_fades_the_menu_theme_out() -> void:
	await menu_theme()
	Music.play_track("menu")
	await frames(2)
	Music.stop()
	await crossfade()
	assert_array(playing()).is_empty()

func test_the_round_plays_voxel_revolution_looping() -> void:
	var player := await round_player()
	assert_str(Music.current_track).is_equal("round")
	assert_int(playing().size()).is_equal(1)
	assert_str(player.stream.resource_path).is_equal("res://audio/voxel_revolution.ogg")
	assert_bool(player.stream.loop).is_true()

func test_asking_for_the_same_track_keeps_it_going() -> void:
	var player := await round_player()
	await seconds(0.3)
	var position := player.get_playback_position()
	Music.play_track("round")
	await frames(1)
	assert_array(playing()).is_equal([player])
	assert_float(player.get_playback_position()).is_greater_equal(position)

func test_both_players_sound_mid_crossfade() -> void:
	add_test_track()
	await round_player()
	Music.play_track("test")
	await seconds(Music.CROSSFADE_SECONDS / 2)
	assert_int(playing().size()).is_equal(2)

func test_after_a_crossfade_only_the_new_track_plays_at_full_volume() -> void:
	add_test_track()
	var old := await round_player()
	Music.play_track("test")
	await crossfade()
	assert_int(playing().size()).is_equal(1)
	assert_object(playing()[0]).is_not_same(old)
	assert_float(playing()[0].volume_db).is_equal_approx(0.0, 0.01)

func test_rapid_changes_leave_the_last_track_at_its_mix_level() -> void:
	add_test_track()
	for track in ["round", "test", "round", "test", "round"]:
		Music.play_track(track)
		await frames(1)
	await crossfade()
	assert_int(playing().size()).is_equal(1)
	assert_str(playing()[0].stream.resource_path).is_equal("res://audio/voxel_revolution.ogg")
	assert_float(playing()[0].volume_db).is_equal_approx(-10.0, 0.01)

func test_ducking_lowers_the_bus_while_paused() -> void:
	get_tree().paused = true
	Music.duck(true)
	await ducking()
	assert_float(duck_db()).is_less(-6.0)

func test_unducking_restores_the_bus() -> void:
	Music.duck(true)
	await ducking()
	get_tree().paused = true
	Music.duck(false)
	await ducking()
	assert_float(duck_db()).is_equal_approx(0.0, 0.01)

func test_stop_fades_out_while_paused() -> void:
	await round_player()
	get_tree().paused = true
	Music.stop()
	await crossfade()
	assert_array(playing()).is_empty()
	assert_str(Music.current_track).is_empty()

func test_the_round_plays_round_music_from_the_autoload() -> void:
	var round := await open("res://main.tscn")
	await frames(2)
	assert_object(round.get_node_or_null("Music")).is_null()
	assert_str(Music.current_track).is_equal("round")

func test_a_rematch_doesnt_restart_the_track() -> void:
	await open("res://main.tscn")
	await seconds(0.5)
	var player: AudioStreamPlayer = playing()[0]
	var position := player.get_playback_position()
	SceneManager.go_to("res://main.tscn")
	await settle()
	assert_array(playing()).is_equal([player])
	assert_float(player.get_playback_position()).is_greater(position)

func test_the_pause_menu_ducks_and_resuming_unducks() -> void:
	await open("res://main.tscn")
	var pause_menu: Control = scene().get_node("PauseMenu/UI")
	pause_menu.toggle_pause()
	await ducking()
	assert_float(duck_db()).is_less(-6.0)
	pause_menu.toggle_pause()
	await ducking()
	assert_float(duck_db()).is_equal_approx(0.0, 0.01)

func test_leaving_from_the_pause_menu_unducks_into_the_menu_theme() -> void:
	await menu_theme()
	await open("res://main.tscn")
	scene().get_node("PauseMenu/UI").toggle_pause()
	await ducking()
	SceneManager.go_to("res://menu.tscn")
	await settle()
	await crossfade()
	assert_float(duck_db()).is_equal_approx(0.0, 0.01)
	assert_str(Music.current_track).is_equal("menu")
	assert_int(playing().size()).is_equal(1)

func test_the_title_plays_the_menu_theme() -> void:
	await menu_theme()
	await open("res://title.tscn")
	await frames(2)
	assert_str(Music.current_track).is_equal("menu")

func test_title_to_lobby_keeps_the_menu_theme_going() -> void:
	await menu_theme()
	await open("res://title.tscn")
	await frames(2)
	var player: AudioStreamPlayer = playing()[0]
	SceneManager.go_to("res://menu.tscn")
	await settle()
	assert_array(playing()).is_equal([player])

func test_launching_crossfades_into_the_round() -> void:
	await menu_theme()
	await open("res://menu.tscn")
	await frames(2)
	var menu_player: AudioStreamPlayer = playing()[0]
	SceneManager.go_to("res://main.tscn")
	await settle()
	assert_str(Music.current_track).is_equal("round")
	await crossfade()
	assert_int(playing().size()).is_equal(1)
	assert_object(playing()[0]).is_not_same(menu_player)
