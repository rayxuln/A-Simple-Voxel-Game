extends BaseComponent

@export var ray_cast_np:NodePath
var ray_cast:RayCast3D:
	get:
		return get_node(ray_cast_np)

var current_look_at_block_data_ref:WeakRef
var current_look_at_block_data:BlockData:
	get:
		if current_look_at_block_data_ref:
			return current_look_at_block_data_ref.get_ref()
		return null
var current_look_at_block_face:int = 0

var block_wireframe_node:BlockWireframeMeshInstance = null

#----- Dependencies -----
func on_get_components() -> Array[NodePath]:
	return []
#----- Overrides -----
func on_update(delta:float) -> void:
	pass

func on_enabled() -> void:
	pass

func on_disabled() -> void:
	pass
#----- Mehtods -----
func calc_face_flag_by_normal(nor:Vector3) -> int:
	var res := 0
	if nor.y > 0:
		res |= BlockData.FaceFlag.Top
	elif nor.y < 0:
		res |= BlockData.FaceFlag.Bottom
	if nor.x > 0:
		res |= BlockData.FaceFlag.Right
	elif nor.x < 0:
		res |= BlockData.FaceFlag.Left
	if nor.z > 0:
		res |= BlockData.FaceFlag.Back
	elif nor.z < 0:
		res |= BlockData.FaceFlag.Forward
	return res

func update_block_wireframe(bd:BlockData) -> void:
	if bd:
		if block_wireframe_node == null:
			block_wireframe_node = BlockWireframeMeshInstance.new()
			GameSystem.get_world().add_child(block_wireframe_node)
		var pos := bd.pos.get_pos()
		block_wireframe_node.global_transform.origin = pos
		block_wireframe_node.create_mesh_from_block_data(bd)
	elif block_wireframe_node:
		block_wireframe_node.queue_free()
		block_wireframe_node = null
#----- Signals -----
func _on_update_timer_timeout() -> void:
	if ray_cast.is_colliding():
		var body:StaticBody3D = ray_cast.get_collider()
		if body == null:
			return
		var chunk:Node = body.owner
		if chunk == null or not chunk.is_in_group('chunk'):
			return
		var shape_id := ray_cast.get_collider_shape()
		var shape_owner_id := body.shape_find_owner(shape_id)
		var block_collision_shape:BlockCollisionShape = body.shape_owner_get_owner(shape_owner_id)
		if block_collision_shape == null:
			return
		var world := GameSystem.get_world()
		var chunk_manager = world.get_node('ChunkManagerComponent')
		var bd:BlockData = chunk_manager.get_block_data(block_collision_shape.block_pos.get_pos())
		if bd:
			current_look_at_block_data_ref = weakref(bd)
			update_block_wireframe(bd)
			current_look_at_block_face = calc_face_flag_by_normal(ray_cast.get_collision_normal())
		else:
			current_look_at_block_data_ref = null
			current_look_at_block_face = 0
			update_block_wireframe(null)
	else:
		current_look_at_block_data_ref = null
		current_look_at_block_face = 0
		update_block_wireframe(null)
