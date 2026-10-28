extends GameSuite
# Every button on every screen draws with the project theme, and no scene carries its own copy of it.

const SCREENS: Array[String] = ["res://title.tscn", "res://match_setup.tscn", "res://menu.tscn", "res://pause_menu.tscn", "res://results.tscn"]

func buttons(node: Node) -> Array[Button]:
	var found: Array[Button] = []
	if node is Button:
		found.append(node)
	for child in node.get_children():
		found.append_array(buttons(child))
	return found

func test_the_project_theme_is_menu_theme() -> void:
	assert_str(ThemeDB.get_project_theme().resource_path).is_equal("res://ui/menu_theme.tres")

func test_every_button_draws_with_the_project_styleboxes() -> void:
	var project := ThemeDB.get_project_theme()
	var checked := 0
	for path in SCREENS:
		var screen: Node = auto_free(load(path).instantiate())
		get_tree().root.add_child(screen)
		await frames(1)
		for button in buttons(screen):
			checked += 1
			for state in ["normal", "hover", "pressed", "focus"]:
				assert_object(button.get_theme_stylebox(state)) \
					.override_failure_message("%s %s %s isn't the project stylebox" % [path, button.name, state]) \
					.is_same(project.get_stylebox(state, "Button"))
	assert_int(checked).is_greater(0)

func test_no_screen_loads_its_own_copy_of_the_theme() -> void:
	for path in SCREENS:
		assert_str(FileAccess.get_file_as_string(path)).not_contains("menu_theme.tres")
