extends ColorRect

## Full-frame film grain; GameConfig.GRAIN_STRENGTH of 0 turns it off, and
## OLED black hides it, as grey specks would light the black

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
	visible = not GameSettings.get_setting("oled")
	GameSettings.setting_changed.connect(on_setting_changed)

func on_setting_changed(setting_name: String, value: Variant):
	if setting_name == "oled":
		visible = not value
