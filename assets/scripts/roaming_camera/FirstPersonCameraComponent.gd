extends BaseComponent

@export var camera_np:NodePath
var camera:Camera3D:
	get:
		return get_node(camera_np)

@export_range(0.1, 1.0) var mouse_sensitive := 1.0
var mouse_factor := -Vector2(0.003, 0.003)




#----- Methods -----
func on_unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if GameSystem.capture_mouse:
			get_owner().global_rotate(Vector3.UP, event.relative.x * mouse_factor.x * mouse_sensitive)
			camera.global_rotate(camera.global_transform.basis.x, event.relative.y * mouse_factor.y * mouse_sensitive)
#----- Signals -----
