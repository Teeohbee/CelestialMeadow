extends CanvasLayer

signal countdown_finished

@onready var countdown_label = $CountdownLabel

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
	
	# Set pivot to center of label for proper scaling
	countdown_label.pivot_offset = countdown_label.size / 2
	
	# Animate: start small and grow (coming towards you)
	countdown_label.scale = Vector2(0.1, 0.1)
	countdown_label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	# Scale up from small to large (zoom in effect) - slower
	tween.tween_property(countdown_label, "scale", Vector2(1.2, 1.2), 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(countdown_label, "modulate:a", 1.0, 0.3)
	
	# Slight overshoot for impact
	tween.chain().tween_property(countdown_label, "scale", Vector2(1.0, 1.0), 0.15)
	
	# Hold for longer
	await get_tree().create_timer(0.5).timeout
	
	# Fade out slower
	var fade_tween = create_tween()
	fade_tween.set_parallel(true)
	fade_tween.tween_property(countdown_label, "scale", Vector2(1.5, 1.5), 0.3)
	fade_tween.tween_property(countdown_label, "modulate:a", 0.0, 0.3)
	
	await fade_tween.finished
	
	count -= 1
	if count >= 0:
		show_number(count)
	else:
		is_counting = false
		countdown_label.visible = false
		countdown_finished.emit()
