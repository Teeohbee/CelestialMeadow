extends Node

## One-shot UI sounds on the Sounds bus, all built by Synth at boot. Notes
## come from the menu theme's A minor pentatonic, in the same glassy voice,
## so the lobby sounds like part of the music. A small pool of players lets
## sounds overlap; a burst bigger than the pool cuts off the oldest.

const POOL_SIZE: int = 8

## Each sound: its length and its notes as [start seconds, MIDI note, length, voice, volume].
const RECIPES: Dictionary = {
	"focus": [0.2, [[0.0, 88, 0.2, "glass", 0.3]]],
	"confirm": [0.6, [[0.0, 81, 0.5, "glass", 0.3], [0.07, 88, 0.5, "glass", 0.3]]],
	"back": [0.5, [[0.0, 84, 0.4, "glass", 0.3], [0.07, 76, 0.4, "glass", 0.3]]],
	"seat": [0.8, [[0.0, 69, 0.6, "glass", 0.2], [0.06, 76, 0.6, "glass", 0.2], [0.12, 81, 0.6, "glass", 0.2], [0.0, 45, 0.4, "sub", 0.3]]],
	"ready": [0.9, [[0.0, 76, 0.8, "glass", 0.18], [0.0, 81, 0.8, "glass", 0.18], [0.0, 88, 0.8, "glass", 0.15], [0.0, 93, 0.06, "blip", 0.15]]],
	"tick": [0.1, [[0.0, 93, 0.06, "blip", 0.35]]],
}

var sounds: Dictionary = {}
var players: Array[AudioStreamPlayer] = []
var next_player_index: int = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	for sound_name in RECIPES:
		sounds[sound_name] = build(RECIPES[sound_name])
	for i in POOL_SIZE:
		var player = AudioStreamPlayer.new()
		player.bus = &"Sounds"
		add_child(player)
		players.append(player)

func play(sound_name: String, pitch: float = 1.0):
	var player = players[next_player_index]
	next_player_index = (next_player_index + 1) % players.size()
	player.stream = sounds[sound_name]
	player.pitch_scale = pitch
	player.play()

static func build(recipe: Array) -> AudioStreamWAV:
	var buffer = Synth.empty_buffer(recipe[0])
	for note in recipe[1]:
		Synth.add_note(buffer, note[0], Synth.note_frequency(note[1]), note[2], note[3], note[4])
	return Synth.to_stream(buffer)
