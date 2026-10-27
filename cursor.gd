extends Node

## The game is played on pads in front of a TV, so the mouse cursor stays
## hidden. Moving the mouse brings it back; it hides again once the mouse
## has been still for IDLE_TIME. Real seconds, paused or not.

const IDLE_TIME: float = 2.0

var hidden: bool = false
var idle: Timer

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	idle = Timer.new()
	idle.one_shot = true
	idle.ignore_time_scale = true
	idle.timeout.connect(hide_now)
	add_child(idle)
	hide_now()

func _input(event):
	if event is InputEventMouseMotion:
		hidden = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		idle.start(IDLE_TIME)

func hide_now():
	idle.stop()
	hidden = true
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
