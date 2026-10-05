extends CanvasLayer

## Screen-space effects. Camera shake calls pulse() via the "post_fx" group.

var aberration: float = 0.0

func _ready():
	add_to_group("post_fx")

func _process(delta):
	if aberration > 0.0:
		aberration = lerp(aberration, 0.0, GameConfig.ABERRATION_DECAY * delta)
		if aberration < 0.05:
			aberration = 0.0
		$Screen.material.set_shader_parameter("aberration", aberration)

func pulse(strength: float):
	aberration = max(aberration, strength)
