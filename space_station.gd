extends AnimatableBody2D

const ROTATION_SPEED: float = 1.0

func _process(delta: float) -> void:
	rotation += ROTATION_SPEED * delta
