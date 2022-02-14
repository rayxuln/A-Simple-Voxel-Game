extends BaseComponent

@export var mesh_ins_np:NodePath

#----- Dependencies -----
func on_get_components() -> Array[NodePath]:
	return [
		^'ChunkDataComponent',
	]
#----- Overrides -----
func on_update(delta:float) -> void:
	pass

func on_enabled() -> void:
	pass

func on_disabled() -> void:
	pass
#----- Mehtods -----
func get_mesh_ins() -> MeshInstance3D:
	return get_node(mesh_ins_np)

func update_mesh() -> void:
	var chunk_data_component = components.ChunkDataComponent
	
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	arrays[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	
	for block_data in chunk_data_component.block_data.values():
		var bp:BlockPosition = block_data.pos
		var pos:Vector3 = bp.get_pos()
		var face_flags := calc_face_falgs_by_pos(pos)
		block_data.get_mesh_data(arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_TEX_UV], face_flags)
	
	calc_normals(arrays[Mesh.ARRAY_VERTEX], arrays[Mesh.ARRAY_NORMAL])
	
	var mesh_instance := get_mesh_ins()
	var mesh:ArrayMesh = mesh_instance.mesh
	mesh.clear_surfaces()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

func calc_face_falgs_by_pos(pos:Vector3) -> int:
	var res:int = BlockData.FaceFlag.None
	var chunk_manager:BaseComponent = GameSystem.get_world().get_node(^'ChunkManagerComponent')
	
	var temp := pos + Vector3.UP
	var block:BlockData = chunk_manager.get_block_data(temp)
	if not (block and block.solid):
		res |= BlockData.FaceFlag.Top
	
	temp = pos + Vector3.DOWN
	block = chunk_manager.get_block_data(temp)
	if not (block and block.solid):
		res |= BlockData.FaceFlag.Bottom

	temp = pos + Vector3.LEFT
	block = chunk_manager.get_block_data(temp)
	if not (block and block.solid):
		res |= BlockData.FaceFlag.Left

	temp = pos + Vector3.RIGHT
	block = chunk_manager.get_block_data(temp)
	if not (block and block.solid):
		res |= BlockData.FaceFlag.Right
#
	temp = pos + Vector3.FORWARD
	block = chunk_manager.get_block_data(temp)
	if not (block and block.solid):
		res |= BlockData.FaceFlag.Forward
	
	temp = pos + Vector3.BACK
	block = chunk_manager.get_block_data(temp)
	if not (block and block.solid):
		res |= BlockData.FaceFlag.Back
	
	return res

func calc_normals(vertices:PackedVector3Array ,normals:PackedVector3Array) -> void:
	normals.resize(vertices.size())
	
	var i = 0
	while i < vertices.size():
		var a:Vector3 = vertices[i]
		var b:Vector3 = vertices[i+1]
		var c:Vector3 = vertices[i+2]
		
		var nor:Vector3 = (c-a).cross(b-a)
		normals.set(i, nor)
		normals.set(i+1, nor)
		normals.set(i+2, nor)
		
		i += 3

func set_mesh_visible(v:bool) -> void:
	get_mesh_ins().visible = v

#----- Signals -----
func _on_chunk_data_component_chunk_data_updated() -> void:
	update_mesh()
