extends Camera2D

@export var shake_decay = 5.0
@export var shake_intensity = 16.0

var shake_strength = 0.0

func _ready():
	make_current()

func _process(delta):
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)

func shake(intensity = shake_intensity):
	shake_strength = intensity
