extends Node

## The one place music plays from. Two players on the Music bus take turns so
## a new track crossfades over the old; asking for the track that's already
## playing does nothing, so a rematch carries on mid-song. Fades ignore pause
## and time scale, and duck() lowers the whole bus under the pause menu.
##
## The title and lobby theme is composed by the game itself on a background
## thread at boot, seeded so it comes out the same every time. Asking for it
## before it's ready starts it as soon as it is.

const CROSSFADE_SECONDS: float = 1.2
const DUCK_SECONDS: float = 0.3
const SILENT_DB: float = -40.0
const DUCKED_DB: float = -12.0

## Slow and spacious: pads, a sub, and a glassy lead with an echo.
const MENU_THEME: Dictionary = {"beats_per_minute": 66, "seed": 7, "bar_count": 8, "melody_busyness": 0.35}
## A minor, F, C, G - each chord as MIDI notes for the pad, root first.
const CHORDS: Array = [[45, 52, 57, 60], [41, 48, 53, 57], [48, 55, 60, 64], [43, 50, 55, 59]]
## A minor pentatonic from A4, so no note can sound wrong over the chords.
const SCALE_ROOT: int = 69
const PENTATONIC_STEPS: Array[int] = [0, 3, 5, 7, 10]

## Each track: its stream and the level it sits at in the mix. The menu
## theme's stream arrives when it's composed.
var tracks: Dictionary = {
	"round": {"stream": preload("res://audio/voxel_revolution.ogg"), "volume_db": -10.0},
	"menu": {"stream": null, "volume_db": 0.0},
}

var current_track: String = ""
var current_track_started: bool = false
var players: Array[AudioStreamPlayer] = []
var active_player_index: int = 0
var fades: Dictionary = {}
var duck_effect: AudioEffectAmplify
var duck_tween: Tween
var compose_task: int = -1
## Written by the composing thread, read once the task is done.
var composed_menu_theme: AudioStreamWAV

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	tracks.round.stream.loop = true
	for i in 2:
		var player = AudioStreamPlayer.new()
		player.bus = &"Music"
		player.volume_db = SILENT_DB
		add_child(player)
		players.append(player)
	duck_effect = AudioEffectAmplify.new()
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Music"), duck_effect)
	compose_task = WorkerThreadPool.add_task(func(): composed_menu_theme = compose(MENU_THEME))

func _process(_delta):
	if compose_task != -1 and WorkerThreadPool.is_task_completed(compose_task):
		WorkerThreadPool.wait_for_task_completion(compose_task)
		compose_task = -1
		tracks.menu.stream = composed_menu_theme
	if current_track != "" and not current_track_started:
		start_current_track()

## Quitting mid-composition waits for it, so no thread outlives the game.
func _exit_tree():
	if compose_task != -1:
		WorkerThreadPool.wait_for_task_completion(compose_task)

func play_track(track_name: String):
	if track_name == current_track:
		return
	stop()
	current_track = track_name
	start_current_track()

func stop():
	current_track = ""
	current_track_started = false
	var player = players[active_player_index]
	if player.playing:
		fade(player, SILENT_DB, true)

func duck(ducked: bool):
	if duck_tween:
		duck_tween.kill()
	duck_tween = create_tween().set_ignore_time_scale()
	duck_tween.tween_property(duck_effect, "volume_db", DUCKED_DB if ducked else 0.0, DUCK_SECONDS)

func start_current_track():
	var track = tracks[current_track]
	if track.stream == null:
		return
	current_track_started = true
	active_player_index = 1 - active_player_index
	var player = players[active_player_index]
	player.stream = track.stream
	player.volume_db = SILENT_DB
	player.play()
	fade(player, track.volume_db, false)

func fade(player: AudioStreamPlayer, to_db: float, stop_after: bool):
	if fades.has(player):
		fades[player].kill()
	var tween = create_tween().set_ignore_time_scale()
	tween.tween_property(player, "volume_db", to_db, CROSSFADE_SECONDS)
	if stop_after:
		tween.tween_callback(player.stop)
	fades[player] = tween

## Pads and a sub on the chords; a glass melody that wanders the scale, its
## second half reusing the first half's rhythm so it has a shape; now and then
## a high twinkle. The melody and twinkles go through an echo.
static func compose(theme: Dictionary) -> AudioStreamWAV:
	var random = RandomNumberGenerator.new()
	random.seed = theme.seed
	var beat = 60.0 / theme.beats_per_minute
	var bar = 4 * beat
	var loop_seconds = theme.bar_count * bar
	var tail_seconds = 5.0
	var bed = Synth.empty_buffer(loop_seconds + tail_seconds)
	var lead = Synth.empty_buffer(loop_seconds + tail_seconds)

	var half = theme.bar_count / 2
	var rhythm: Array[bool] = []
	for slot in half * 8:
		rhythm.append(slot % 8 == 0 or random.randf() < theme.melody_busyness)

	var scale_position = 5
	for bar_index in theme.bar_count:
		var chord: Array = CHORDS[bar_index % CHORDS.size()]
		var bar_start = bar_index * bar
		for note in chord:
			Synth.add_note(bed, bar_start, Synth.note_frequency(note), bar + 1.5, "pad", 0.07)
		Synth.add_note(bed, bar_start, Synth.note_frequency(chord[0] - 12), bar + 0.3, "sub", 0.3)
		for slot_in_bar in 8:
			if not rhythm[(bar_index % half) * 8 + slot_in_bar]:
				continue
			scale_position = clampi(scale_position + random.randi_range(-2, 2), 2, 11)
			if slot_in_bar == 0:
				scale_position = nearest_chord_tone(scale_position, chord)
			var start = bar_start + slot_in_bar * beat / 2.0
			Synth.add_note(lead, start, Synth.note_frequency(scale_note(scale_position)), 3 * beat, "glass", 0.22)
		if random.randf() < 0.5:
			var twinkle = scale_note(random.randi_range(10, 14))
			Synth.add_note(lead, bar_start + random.randi_range(1, 7) * beat / 2.0, Synth.note_frequency(twinkle), 2 * beat, "glass", 0.06)

	Synth.add_echo(lead, 0.75 * beat, 0.4)
	for i in bed.size():
		bed[i] += lead[i]
	return Synth.to_stream(wrap_tail_into_loop(bed, int(loop_seconds * Synth.MIX_RATE)), true)

static func scale_note(scale_position: int) -> int:
	return SCALE_ROOT + 12 * floori(scale_position / 5.0) + PENTATONIC_STEPS[posmod(scale_position, 5)] - 12

## Moves a scale position to the nearest note that's in the chord, if one is close.
static func nearest_chord_tone(scale_position: int, chord: Array) -> int:
	for distance in [0, 1, -1, 2, -2]:
		var pitch_class = posmod(scale_note(scale_position + distance), 12)
		for note in chord:
			if posmod(note, 12) == pitch_class:
				return scale_position + distance
	return scale_position

## Whatever's still ringing past the end is folded back onto the start, so
## the loop joins without a click, then the whole thing is evened out.
static func wrap_tail_into_loop(buffer: PackedFloat32Array, loop_samples: int) -> PackedFloat32Array:
	var looped = buffer.slice(0, loop_samples)
	for i in buffer.size() - loop_samples:
		looped[i] += buffer[loop_samples + i]
	var loudest = 0.001
	for sample in looped:
		loudest = maxf(loudest, absf(sample))
	for i in looped.size():
		looped[i] *= 0.6 / loudest
	return looped
