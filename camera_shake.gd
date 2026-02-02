extends Camera2D

@export var shake_decay: float = 5.0
@export var shake_intensity: float = 16.0

var shake_strength: float = 0.0
var original_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	make_current()
	original_offset = offset

func _process(delta: float) -> void:
	if shake_strength > 0:
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
		offset = original_offset + Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
	else:
		offset = original_offset

func shake(intensity: float = shake_intensity) -> void:
	shake_strength = intensity
