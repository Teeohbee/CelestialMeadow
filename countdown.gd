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
	
	# Animate: scale up and fade in
	countdown_label.scale = Vector2(0.5, 0.5)
	countdown_label.modulate.a = 0.0
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(countdown_label, "scale", Vector2(1.5, 1.5), 0.3)
	tween.tween_property(countdown_label, "modulate:a", 1.0, 0.2)
	
	# Pulse effect
	tween.chain().tween_property(countdown_label, "scale", Vector2(1.8, 1.8), 0.2)
	
	# Fade out
	tween.chain().set_parallel(true)
	tween.tween_property(countdown_label, "scale", Vector2(2.5, 2.5), 0.3)
	tween.tween_property(countdown_label, "modulate:a", 0.0, 0.3)
	
	await tween.finished
	
	count -= 1
	if count >= 0:
		show_number(count)
	else:
		is_counting = false
		countdown_label.visible = false
		countdown_finished.emit()
