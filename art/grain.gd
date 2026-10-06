extends ColorRect

## Full-frame film grain; GameConfig.GRAIN_STRENGTH of 0 turns it off

const GRAIN_SHADER = preload("res://art/grain.gdshader")

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if GameConfig.GRAIN_STRENGTH <= 0.0:
		hide()
		return
	var mat = ShaderMaterial.new()
	mat.shader = GRAIN_SHADER
	mat.set_shader_parameter("strength", GameConfig.GRAIN_STRENGTH)
	material = mat
