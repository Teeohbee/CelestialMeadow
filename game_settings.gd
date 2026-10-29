extends Node

## Settings saved to user://settings.json. A missing or broken file never
## stops the game: it starts from the defaults and says so in the log. Only
## settings we know about are read, only of the right type, and numbers are
## clamped. Volumes are applied to the Music and Sounds buses as they change.
## The game launches fullscreen; turning that off gives a maximised window.
## render_1080p draws at the 1920x1080 layout size and scales it up, rather
## than drawing at the screen's own size: a quarter of the pixels on a 4K TV.

signal setting_changed(setting_name: String, new_value: Variant)

const SAVE_FORMAT_VERSION: int = 1

## Each setting: its default, and for numbers the smallest and largest value.
## last_mode is an index into GameState.MODES. teams, lives and time_minutes
## are the match rules, kept between sessions like the mode.
var setting_limits: Dictionary = {
	"music_volume": {"default": 8, "smallest": 0, "largest": 10},
	"sound_volume": {"default": 8, "smallest": 0, "largest": 10},
	"fullscreen": {"default": true},
	"render_1080p": {"default": false},
	"last_mode": {"default": 0, "smallest": 0, "largest": GameState.MODES.size() - 1},
	"teams": {"default": false},
	"lives": {"default": GameConfig.PLAYER_LIVES_DEFAULT, "smallest": 1, "largest": 5},
	"time_minutes": {"default": 2, "smallest": 1, "largest": 5},
}

## Which bus each volume setting drives
const VOLUME_BUSES: Dictionary = {"music_volume": "Music", "sound_volume": "Sounds"}

var save_file_path: String = "user://settings.json"
var settings: Dictionary = {}

func _ready():
	load_from_disk()

func get_setting(setting_name: String) -> Variant:
	return settings[setting_name]

func set_setting(setting_name: String, new_value: Variant):
	settings[setting_name] = limited(setting_name, new_value)
	save_to_disk()
	apply(setting_name)
	setting_changed.emit(setting_name, settings[setting_name])

func load_from_disk():
	settings = {}
	for setting_name in setting_limits:
		settings[setting_name] = setting_limits[setting_name].default
	if FileAccess.file_exists(save_file_path):
		var parser = JSON.new()
		var parsed_cleanly = parser.parse(FileAccess.get_file_as_string(save_file_path)) == OK
		if not parsed_cleanly or not parser.data is Dictionary:
			push_warning("Settings file %s couldn't be read, starting from defaults" % save_file_path)
		else:
			copy_known_values(parser.data.get("settings", {}))
	for setting_name in VOLUME_BUSES:
		apply(setting_name)
	apply("render_1080p")
	# The game launches fullscreen already; only a saved "off" changes that,
	# so --windowed and the editor's game window are left alone
	if not settings.fullscreen:
		apply("fullscreen")

## Only names we know about, and only values of the same kind as the default
func copy_known_values(saved: Variant):
	if not saved is Dictionary:
		return
	for setting_name in settings:
		if not saved.has(setting_name):
			continue
		var value = saved[setting_name]
		var wants_number = settings[setting_name] is int
		if wants_number and (value is int or value is float):
			settings[setting_name] = limited(setting_name, int(value))
		elif not wants_number and value is bool:
			settings[setting_name] = value

func limited(setting_name: String, value: Variant) -> Variant:
	var limits = setting_limits[setting_name]
	if limits.has("largest"):
		return clampi(value, limits.smallest, limits.largest)
	return value

func save_to_disk():
	var file = FileAccess.open(save_file_path, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write settings file %s: %s" % [save_file_path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(JSON.stringify({"version": SAVE_FORMAT_VERSION, "settings": settings}, "\t"))

func apply(setting_name: String):
	if VOLUME_BUSES.has(setting_name):
		var bus_index = AudioServer.get_bus_index(VOLUME_BUSES[setting_name])
		var volume = settings[setting_name]
		AudioServer.set_bus_mute(bus_index, volume == 0)
		AudioServer.set_bus_volume_db(bus_index, linear_to_db(volume / 10.0))
	elif setting_name == "fullscreen":
		var mode = DisplayServer.WINDOW_MODE_FULLSCREEN if settings.fullscreen else DisplayServer.WINDOW_MODE_MAXIMIZED
		if DisplayServer.window_get_mode() != mode:
			DisplayServer.window_set_mode(mode)
	elif setting_name == "render_1080p":
		var draw_at = Window.CONTENT_SCALE_MODE_VIEWPORT if settings.render_1080p else Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		get_tree().root.content_scale_mode = draw_at
