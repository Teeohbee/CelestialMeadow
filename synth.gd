class_name Synth
extends RefCounted

## A tiny synthesiser. Builds sounds as lists of samples, then turns them into
## AudioStreamWAVs. Mono, and slow enough per sample that anything longer than
## a blip should be built off the main thread.

const MIX_RATE: int = 22050

static func empty_buffer(seconds: float) -> PackedFloat32Array:
	var buffer = PackedFloat32Array()
	buffer.resize(int(seconds * MIX_RATE))
	return buffer

static func to_stream(buffer: PackedFloat32Array, loops: bool = false) -> AudioStreamWAV:
	var bytes = PackedByteArray()
	bytes.resize(buffer.size() * 2)
	for i in buffer.size():
		bytes.encode_s16(i * 2, int(clampf(buffer[i], -1.0, 1.0) * 32767.0))
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.data = bytes
	if loops:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = buffer.size()
	return stream

static func note_frequency(midi_note: int) -> float:
	return 440.0 * pow(2.0, (midi_note - 69) / 12.0)

## Adds one note. Voices: "pad", "glass", "sub", "blip".
static func add_note(buffer: PackedFloat32Array, start_seconds: float, frequency: float,
		duration_seconds: float, voice: String, volume: float):
	var first = int(start_seconds * MIX_RATE)
	for offset in int(duration_seconds * MIX_RATE):
		if first + offset >= buffer.size():
			return
		var time = float(offset) / MIX_RATE
		buffer[first + offset] += voice_sample(voice, frequency, time, duration_seconds) * volume

static func voice_sample(voice: String, frequency: float, time: float, duration_seconds: float) -> float:
	var phase = TAU * frequency * time
	var attack = minf(time / 0.004, 1.0)
	var release = clampf((duration_seconds - time) / 0.05, 0.0, 1.0)
	match voice:
		"pad":
			# Slow swell, two voices drifting against each other
			var swell = minf(time / 1.5, 1.0) * clampf((duration_seconds - time) / 1.5, 0.0, 1.0)
			return swell * (sin(phase) + sin(phase * 1.003) + 0.4 * sin(phase * 2.001) + 0.15 * sin(phase * 3.0)) / 2.55
		"glass":
			# Out-of-tune overtones, like a celesta in a big room
			return attack * release * (sin(phase) * exp(-time * 2.2) + 0.45 * sin(phase * 2.756) * exp(-time * 4.0) \
				+ 0.2 * sin(phase * 5.404) * exp(-time * 7.0))
		"sub":
			var fade_in = minf(time / 0.08, 1.0)
			return fade_in * release * sin(phase) * exp(-time * 0.6)
		"blip":
			return attack * release * sin(phase)
	return 0.0

## A feedback echo, in place: each repeat comes back quieter.
static func add_echo(buffer: PackedFloat32Array, delay_seconds: float, feedback: float):
	var delay = int(delay_seconds * MIX_RATE)
	for i in range(delay, buffer.size()):
		buffer[i] += buffer[i - delay] * feedback
