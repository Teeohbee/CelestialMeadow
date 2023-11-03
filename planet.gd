extends Sprite2D

@export var sprites : Array[CompressedTexture2D] = []
var screen_size

func _ready():
	screen_size = get_viewport_rect().size
	set_planet_texture()
	set_planet_scale()
	position = Vector2(randf_range(0, 1)*screen_size.x, randf_range(0, 1)*screen_size.y)

func set_planet_texture():
	var texture_index = randi() % sprites.size()
	texture = sprites[texture_index]
	sprites.remove_at(texture_index)

func set_planet_scale():
	var size = randf_range(0.1, 0.6)
	scale = Vector2(size, size)
