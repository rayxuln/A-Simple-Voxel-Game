extends BaseComponent

@export var camera_np:NodePath
var camera:Camera3D:
	get:
		return get_node(camera_np)

@export var jump_speed := 10
@export var move_speed := 6
@export var max_fallen_speed := 20
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
		target_fov = orignal_fov * ((sprint_factor-1) * fov_factor+1)
	else:
		target_fov = orignal_fov
	
	if fly_mode:
		o.motion_velocity = move_vec
	else:
		var mv := o.motion_velocity
		if o.is_on_floor():
			if Input.is_action_just_pressed('jump'):
				mv.y = jump_speed
			else:
				mv.y = -0.1
		else:
			mv.y += -gravity_factor * ProjectSettings.get('physics/3d/default_gravity')
			if abs(mv.y) >= max_fallen_speed:
				mv.y = -max_fallen_speed
		mv.x = move_vec.x
		mv.z = move_vec.z
		
		if Input.is_action_pressed('sneak'):
			var c:KinematicCollision3D = o.move_and_collide(mv*3, true, 0.001, 6)
			var should_stop := true
			if c != null:
				for i in c.get_collision_count():
					if c.get_normal(i).y > 0:
						should_stop = false
						break
			if should_stop:
				mv.x = 0
				mv.z = 0
		o.motion_velocity = mv
	

	if Input.is_action_just_pressed('destroy'):
		var world = GameSystem.get_world()
		var chunk_manager = world.get_node('ChunkManagerComponent')
		var bd:BlockData = components.PickUpRayCastComponent.current_look_at_block_data
		if bd:
			chunk_manager.set_block_data(bd.pos.get_pos(), null)

	if Input.is_action_just_pressed('build'):
		var world = GameSystem.get_world()
		var chunk_manager = world.get_node('ChunkManagerComponent')
		var bd:BlockData = components.PickUpRayCastComponent.current_look_at_block_data
		var face = components.PickUpRayCastComponent.current_look_at_block_face
		if face:
			var target_pos:Vector3 = bd.pos.get_pos() + BlockData.get_direction_vector_by_face_flag(face)
			var origin_pos := o.transform.origin
			var can_place:bool = \
				not BlockPosition.is_pos_same(origin_pos, target_pos) and \
				not BlockPosition.is_pos_same(origin_pos+Vector3.UP, target_pos)
			if can_place:
				chunk_manager.set_block_data(target_pos, StoneBlock.new())
	
	if Input.is_action_just_pressed('fly'):
		fly_mode = not fly_mode
	
	o.move_and_slide()

func on_update(delta:float):
	if get_owner().global_transform.origin.y <= -16:
		get_owner().global_transform.origin.y = 100

func on_enable():
	orignal_fov = camera.fov

#----- Signals -----
