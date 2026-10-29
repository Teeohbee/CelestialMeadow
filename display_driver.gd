class_name DisplayDriver
extends RefCounted

## Which display server Godot runs on under Linux: X11, or Wayland straight
## to Steam's gamescope. Godot picks it before the game starts, so the choice
## lives in override.cfg beside the executable (which Godot reads at launch)
## rather than settings.json, and switching restarts the game. If Wayland
## isn't available Godot falls back to X11, so the row always shows the one
## actually running.

const DRIVERS: Array[String] = ["x11", "wayland"]
const NAMES: Dictionary = {"x11": "X11", "wayland": "Wayland"}

static func current() -> String:
	return DisplayServer.get_name().to_lower()

## Only an exported Linux build: from source, the executable is Godot itself
static func can_switch() -> bool:
	return OS.has_feature("template") and OS.get_name() == "Linux"

static func label() -> String:
	return NAMES.get(current(), DisplayServer.get_name())

## The other driver from the one running
static func other() -> String:
	return DRIVERS[(DRIVERS.find(current()) + 1) % DRIVERS.size()]

static func override_path() -> String:
	return OS.get_executable_path().get_base_dir().path_join("override.cfg")

static func override_text(driver: String) -> String:
	return "[display]\n\ndisplay_server/driver.linuxbsd=\"%s\"\n" % driver

## Writes the choice for the next launch; false if it couldn't be written
static func choose(driver: String, path: String = override_path()) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_warning("Couldn't write %s: %s" % [path, error_string(FileAccess.get_open_error())])
		return false
	file.store_string(override_text(driver))
	return true

## Switches to the other driver and relaunches with the same arguments
static func switch(tree: SceneTree):
	if not can_switch() or not choose(other()):
		return
	OS.set_restart_on_exit(true, OS.get_cmdline_args())
	tree.quit()
