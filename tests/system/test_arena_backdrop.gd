extends GameSuite
# The arena backdrop's still parts (ground, horizon, stars, dashed orbits, bezel) are drawn once; only the
# speed bars redraw each frame, and they keep drifting. Redrawing everything each frame held the Steam
# Machine at 45 fps.

func backdrop() -> Node2D:
	var node := Node2D.new()
	node.set_script(load("res://art/arena_backdrop.gd"))
	add_child(auto_free(node))
	await frames(2)
	return node

func draws_over(item: CanvasItem, count: int) -> int:
	var drawn := [0]
	var counter := func(): drawn[0] += 1
	item.draw.connect(counter)
	await frames(count)
	item.draw.disconnect(counter)
	return drawn[0]

func test_the_still_parts_are_drawn_once() -> void:
	var node := await backdrop()
	assert_int(await draws_over(node, 10)).is_equal(0)
	assert_int(await draws_over(node.bezel_layer, 10)).is_equal(0)

func test_the_speed_bars_redraw_every_frame() -> void:
	var node := await backdrop()
	assert_int(await draws_over(node.bars_layer, 10)).is_greater_equal(9)

func test_the_speed_bars_drift() -> void:
	var node := await backdrop()
	var bar: Dictionary = node.bars[0]
	assert_float(node.bar_head_x(bar, 10.5) - node.bar_head_x(bar, 10.0)).is_greater(1.0)

func test_the_bezel_sits_above_the_bars() -> void:
	var node := await backdrop()
	assert_int(node.bezel_layer.get_index()).is_greater(node.bars_layer.get_index())

# OLED: the ground and its horizon rings are pure black, so the panel's pixels switch off
func test_oled_redraws_the_still_parts_once_with_no_horizon() -> void:
	var node := await backdrop()
	assert_int(node.horizon_rings()).is_equal(6)
	GameSettings.set_setting("oled", true)
	assert_int(await draws_over(node, 10)).is_equal(1)
	assert_int(node.horizon_rings()).is_equal(0)

func test_oled_hides_the_grain() -> void:
	var grain := ColorRect.new()
	grain.set_script(load("res://art/grain.gd"))
	add_child(auto_free(grain))
	assert_bool(grain.visible).is_true()
	GameSettings.set_setting("oled", true)
	assert_bool(grain.visible).is_false()
	GameSettings.set_setting("oled", false)
	assert_bool(grain.visible).is_true()
