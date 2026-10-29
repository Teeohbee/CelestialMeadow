extends GdUnitTestSuite
# DisplayDriver: the Display option's choice goes in override.cfg for Godot to read at the next launch, it
# offers the driver that isn't running, and from source it never touches the Godot executable's folder.

var scratch_path := "user://test_override_%d.cfg" % OS.get_process_id()

func after_test() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(scratch_path))

func test_choosing_wayland_writes_an_override_godot_reads() -> void:
	assert_bool(DisplayDriver.choose("wayland", scratch_path)).is_true()
	var cfg := ConfigFile.new()
	assert_int(cfg.load(scratch_path)).is_equal(OK)
	assert_str(cfg.get_value("display", "display_server/driver.linuxbsd")).is_equal("wayland")

func test_choosing_x11_replaces_it() -> void:
	DisplayDriver.choose("wayland", scratch_path)
	DisplayDriver.choose("x11", scratch_path)
	var cfg := ConfigFile.new()
	cfg.load(scratch_path)
	assert_str(cfg.get_value("display", "display_server/driver.linuxbsd")).is_equal("x11")

func test_an_unwritable_place_says_so() -> void:
	assert_bool(DisplayDriver.choose("wayland", "user://no/such/dir/override.cfg")).is_false()

func test_it_offers_the_driver_that_isnt_running() -> void:
	assert_str(DisplayDriver.other()).is_not_equal(DisplayDriver.current())
	assert_array(DisplayDriver.DRIVERS).contains([DisplayDriver.other()])

func test_from_source_it_cant_switch() -> void:
	assert_bool(DisplayDriver.can_switch()).is_false()
