extends Node

var capture_mouse := true:
	set(v):
		capture_mouse = v
		if capture_mouse:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get:
		return capture_mouse

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if not capture_mouse:
				capture_mouse = true

func _ready() -> void:
	capture_mouse = true

func _process(delta: float) -> void:
	if Input.is_action_just_pressed('ui_cancel'):
		if capture_mouse:
			capture_mouse = false
#----- Methods -----
func get_game() -> Node:
	return get_node(^'/root/Game')
	
func get_world() -> Node3D:
	return get_game().get_node(^'World')

func get_gui_root() -> Control:
	return get_game().get_node(^'Control')

func get_gui(p:NodePath) -> Control:
	return get_gui_root().get_node(p)
