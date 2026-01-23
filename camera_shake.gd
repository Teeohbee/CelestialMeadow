extends Camera2D

@export var shake_decay = 5.0
@export var shake_intensity = 16.0

var shake_strength = 0.0
var original_offset = Vector2.ZERO

func _ready():
	make_current()
	original_offset = offset

func _process(delta):
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		offset = original_offset + Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		offset = original_offset

func shake(intensity = shake_intensity):
	shake_strength = intensity
