extends BaseComponent

@export var camera_np:NodePath
var camera:Camera3D:
	get:
		return get_node(camera_np)

@export var jump_speed := 10
@export var move_speed := 8
@export var sprint_factor := 1.75
@export var gravity_factor := 0.07
@export var fov_factor := 0.5
var move_speed_factor := 1
var orignal_fov := 75.0
var target_fov := orignal_fov

@export var fly_mode := true:
	set(v):
		fly_mode = v
		var o:CharacterBody3D = get_owner()
		if fly_mode:
			o.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
		else:
			o.motion_mode = CharacterBody3D.MOTION_MODE_GROUNDED

#----- Overrides -----
func on_get_components() -> Array[NodePath]:
	return [
		^'PickUpRayCastComponent',
	]
#----- Methods -----
func on_physics_update(delta:float) -> void:
	var input_vec := Vector3.ZERO
	input_vec.x = Input.get_axis('move_left', 'move_right')
	input_vec.y = Input.get_axis('move_deccend', 'move_accend')
	input_vec.z = -Input.get_axis('move_down', 'move_up')

	input_vec = input_vec.normalized()

	var move_vec := Vector3.ZERO
	
	var o:CharacterBody3D = get_owner()
	
	if fly_mode:
		move_vec += camera.global_transform.basis.x  * input_vec.x
		move_vec += Vector3.UP  * input_vec.y
		move_vec += camera.global_transform.basis.z  * input_vec.z
	else:
		move_vec += o.global_transform.basis.x  * input_vec.x
		move_vec += o.global_transform.basis.z  * input_vec.z
	
	move_vec *= move_speed * move_speed_factor
	camera.fov = lerp(camera.fov, target_fov, 0.3)
	if Input.is_action_pressed('sprint'):
		move_vec *= sprint_factor
		target_fov = orignal_fov * sprint_factor * fov_factor
	else:
		target_fov = orignal_fov
	
	if fly_mode:
		o.motion_velocity = move_vec
	else:
		if o.is_on_floor():
			if Input.is_action_just_pressed('jump'):
				o.motion_velocity.y = jump_speed
			else:
				o.motion_velocity.y = 0
		else:
			o.motion_velocity.y += -gravity_factor * ProjectSettings.get('physics/3d/default_gravity')
		o.motion_velocity.x = move_vec.x
		o.motion_velocity.z = move_vec.z
	

	if Input.is_action_just_pressed('destroy'):
		var world = GameSystem.get_world()
		var chunk_manager = world.get_node('ChunkManagerComponent')
		if components.PickUpRayCastComponent.current_look_at_block_data:
			chunk_manager.set_block_data(
				components.PickUpRayCastComponent
									.current_look_at_block_data
									.pos.get_pos()
				, null)

	if Input.is_action_just_pressed('build'):
		var world = GameSystem.get_world()
		var chunk_manager = world.get_node('ChunkManagerComponent')
		chunk_manager.set_block_data(get_owner().global_transform.origin+Vector3.DOWN, StoneBlock.new())
	
	if Input.is_action_just_pressed('fly'):
		fly_mode = not fly_mode
	
	GameSystem.get_gui('PerformanceDisplayer').set_pos_label('Pos: %s, Chunk: %s' % [Vector3i(get_owner().global_transform.origin), ChunkPosition.pos_to_chunk_pos(get_owner().global_transform.origin)])
	o.move_and_slide()

func on_enable():
	orignal_fov = camera.fov
#----- Signals -----
