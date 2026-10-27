extends Node

## The one place music plays from. Two players on the Music bus take turns so
## a new track crossfades over the old; asking for the track that's already
## playing does nothing, so a rematch carries on mid-song. Fades ignore pause
## and time scale, and duck() lowers the whole bus under the pause menu.

const CROSSFADE_SECONDS: float = 1.2
const DUCK_SECONDS: float = 0.3
const SILENT_DB: float = -40.0
const DUCKED_DB: float = -12.0

## Each track: its stream and the level it sits at in the mix.
var tracks: Dictionary = {
	"round": {"stream": preload("res://audio/voxel_revolution.ogg"), "volume_db": -10.0},
}

var current_track: String = ""
var players: Array[AudioStreamPlayer] = []
var active_player_index: int = 0
var fades: Dictionary = {}
var duck_effect: AudioEffectAmplify
var duck_tween: Tween

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

func play_track(track_name: String):
	if track_name == current_track:
		return
	stop()
	current_track = track_name
	active_player_index = 1 - active_player_index
	var player = players[active_player_index]
	player.stream = tracks[track_name].stream
	player.volume_db = SILENT_DB
	player.play()
	fade(player, tracks[track_name].volume_db, false)

func stop():
	current_track = ""
	var player = players[active_player_index]
	if player.playing:
		fade(player, SILENT_DB, true)

func duck(ducked: bool):
	if duck_tween:
		duck_tween.kill()
	duck_tween = create_tween().set_ignore_time_scale()
	duck_tween.tween_property(duck_effect, "volume_db", DUCKED_DB if ducked else 0.0, DUCK_SECONDS)

func fade(player: AudioStreamPlayer, to_db: float, stop_after: bool):
	if fades.has(player):
		fades[player].kill()
	var tween = create_tween().set_ignore_time_scale()
	tween.tween_property(player, "volume_db", to_db, CROSSFADE_SECONDS)
	if stop_after:
		tween.tween_callback(player.stop)
	fades[player] = tween
