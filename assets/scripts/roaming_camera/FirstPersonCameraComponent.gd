extends BaseComponent

@export var camera_np:NodePath
var camera:Camera3D:
	get:
		return get_node(camera_np)

@export_range(0.1, 1.0) var mouse_sensitive := 1.0
var mouse_factor := -Vector2(0.003, 0.003)

@export var mouse_min_y_rotation := -90.0
@export var mouse_max_y_rotation := 90.0


#----- Methods -----
func on_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if GameSystem.capture_mouse:
			var rx = camera.rotation.x + event.relative.y * mouse_factor.y * mouse_sensitive
			camera.rotation.x = clamp(rx, deg2rad(mouse_min_y_rotation), deg2rad(mouse_max_y_rotation))
			get_owner().global_rotate(Vector3.UP, event.relative.x * mouse_factor.x * mouse_sensitive)
#----- Signals -----
