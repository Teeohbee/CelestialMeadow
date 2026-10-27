extends GameSuite
# Sound: short one-shot UI sounds on the Sounds bus, from a pool so they overlap. A burst bigger than the pool
# reuses the oldest player instead of failing, and sounds still play while the game is paused.

const UI_SOUNDS: Array[String] = ["focus", "confirm", "back", "seat", "ready", "tick"]

func busy() -> Array[AudioStreamPlayer]:
	return Sound.players.filter(func(p): return p.playing)

func loudest(stream: AudioStreamWAV) -> int:
	var peak := 0
	for i in range(0, stream.data.size(), 2):
		peak = maxi(peak, absi(stream.data.decode_s16(i)))
	return peak

func test_sound_plays_while_paused() -> void:
	assert_int(Sound.process_mode).is_equal(Node.PROCESS_MODE_ALWAYS)

func test_there_is_a_pool_of_players() -> void:
	assert_int(Sound.players.size()).is_greater_equal(4)

func test_the_pool_is_on_the_sounds_bus() -> void:
	for player in Sound.players:
		assert_str(player.bus).is_equal("Sounds")

func test_every_ui_sound_exists() -> void:
	for sound_name in UI_SOUNDS:
		assert_object(Sound.sounds.get(sound_name)) \
			.override_failure_message("%s is missing" % sound_name).is_instanceof(AudioStreamWAV)

func test_every_ui_sound_is_short() -> void:
	for sound_name in UI_SOUNDS:
		assert_float(Sound.sounds[sound_name].get_length()) \
			.override_failure_message("%s is too long" % sound_name).is_less(1.0)

func test_every_ui_sound_is_audible_and_doesnt_clip() -> void:
	for sound_name in UI_SOUNDS:
		assert_int(loudest(Sound.sounds[sound_name])) \
			.override_failure_message("%s peaks at %d" % [sound_name, loudest(Sound.sounds[sound_name])]) \
			.is_between(3001, 32766)

func test_two_sounds_overlap() -> void:
	Sound.play("tick")
	Sound.play("confirm")
	await frames(1)
	assert_int(busy().size()).is_equal(2)

func test_a_burst_fills_the_pool_without_errors() -> void:
	for i in Sound.players.size() + 3:
		Sound.play("focus")
	await frames(1)
	assert_int(busy().size()).is_equal(Sound.players.size())

func test_it_plays_while_the_game_is_paused() -> void:
	get_tree().paused = true
	Sound.play("back")
	await frames(1)
	# Godot pauses the stream of a player that can't process, though it still reports playing
	assert_int(busy().size()).is_equal(1)
	assert_bool(busy()[0].can_process()).is_true()
