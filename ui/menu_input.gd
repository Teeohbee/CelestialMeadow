class_name MenuInput

## Menu presses that count a stick push once. A stick sends a stream of
## motion events while it moves, and every one past the deadzone reads as
## pressed, so only the event that pushed it past counts.

static func pressed(event: InputEvent, action: String, allow_echo: bool = false) -> bool:
	if event is InputEventJoypadMotion:
		return Input.is_action_just_pressed_by_event(action, event)
	return event.is_action_pressed(action, allow_echo)
