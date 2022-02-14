extends Camera3D

@export_range(0.1, 1.0) var mouse_sensitive := 1.0
var mouse_factor := -Vector2(0.003, 0.003)

@export var move_speed := 3
@export var sprint_factor := 1.75
var move_speed_factor := 0.01

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if GameSystem.capture_mouse:
			global_rotate(Vector3.UP, event.relative.x * mouse_factor.x * mouse_sensitive)
			global_rotate(global_transform.basis.x, event.relative.y * mouse_factor.y * mouse_sensitive)
#----- Methods -----
func _process(delta: float) -> void:
	var input_vec := Vector3.ZERO
	input_vec.x = Input.get_axis('move_left', 'move_right')
	input_vec.y = Input.get_axis('move_deccend', 'move_accend')
	input_vec.z = -Input.get_axis('move_down', 'move_up')
	
	input_vec = input_vec.normalized()
	
	var move_vec := Vector3.ZERO
	move_vec += global_transform.basis.x  * input_vec.x
	move_vec += Vector3.UP  * input_vec.y
	move_vec += global_transform.basis.z  * input_vec.z
	move_vec *= move_speed * move_speed_factor
	if Input.is_action_pressed('sprint'):
		move_vec *= sprint_factor
	
	global_transform.origin += move_vec
	
	GameSystem.get_gui('PerformanceDisplayer').set_pos_label('Pos: %s, Chunk: %s' % [Vector3i(global_transform.origin), ChunkPosition.pos_to_chunk_pos(global_transform.origin)])

#----- Signals -----
