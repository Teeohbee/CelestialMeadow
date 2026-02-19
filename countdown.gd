extends CanvasLayer

signal countdown_finished

@onready var countdown_label = $CountdownLabel
@onready var audio_player = $AudioStreamPlayer

var count = 3
var is_counting = false

func _ready():
	countdown_label.visible = false

func start_countdown():
	is_counting = true
	countdown_label.visible = true
	count = 3
	show_number(count)

func show_number(number: int):
	if number > 0:
		countdown_label.text = str(number)
	else:
		countdown_label.text = "GO!"
	
	# Play audio for the number
	play_countdown_audio(number)
	
	# Set pivot to center of label for proper scaling
	countdown_label.pivot_offset = countdown_label.size / 2
	
	# Animate: start small and grow (coming towards you)
	countdown_label.scale = Vector2(0.1, 0.1)
	countdown_label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	# Scale up from small to large (zoom in effect) - medium speed
	tween.tween_property(countdown_label, "scale", Vector2(1.2, 1.2), 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(countdown_label, "modulate:a", 1.0, 0.4)
	
	# Slight overshoot for impact
	tween.chain().tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Hold for medium duration
	await get_tree().create_timer(0.6).timeout
	
	# Fade out medium speed
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(countdown_label, "scale", Vector2(1.5, 1.5), 0.4)
	fade_tween.tween_property(countdown_label, "modulate:a", 0.0, 0.4)
	
	await fade_tween.finished
	
	count -= 1
	if count >= 0:
		show_number(count)
	else:
		is_counting = false
		countdown_label.visible = false
		countdown_finished.emit()

func play_countdown_audio(number: int):
	var audio_path = ""
	match number:
		3:
			audio_path = "res://audio/countdown/three.wav"
		2:
			audio_path = "res://audio/countdown/two.wav"
		1:
			audio_path = "res://audio/countdown/one.wav"
		0:
			audio_path = "res://audio/countdown/go.wav"
	
	if ResourceLoader.exists(audio_path) and audio_player:
		audio_player.stream = load(audio_path)
		audio_player.play()
