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
	var world = GameSystem.get_world()
	world.get_node('ChunkMeshGeneratorComponent').connect('responded', self._on_chunk_generator_responded)

func on_disabled() -> void:
	pass
#----- Mehtods -----
func get_mesh_ins() -> MeshInstance3D:
	return get_node(mesh_ins_np)

func update_mesh() -> void:
	var chunk_data_component = components.ChunkDataComponent
	
	# in: block_data
	# out: vertices, uvs, normals
	var world = GameSystem.get_world()
	world.get_node('ChunkMeshGeneratorComponent').request_worker({
		'encoded_chunk_pos': chunk_data_component.chunk_pos.get_encoded_chunk_pos(),
		'worker_func': self._worker_gen_mesh_data,
	})

func _worker_gen_mesh_data(data):
	data.vertices = PackedVector3Array()
	data.normals = PackedVector3Array()
	data.uvs = PackedVector2Array()
	
	components.ChunkDataComponent.block_data_mutex.lock()
	var values = components.ChunkDataComponent.block_data.values()
	components.ChunkDataComponent.block_data_mutex.unlock()
	for block_data in values:
		block_data.get_mesh_data(data.vertices, data.uvs)

	calc_normals(data.vertices, data.normals)

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

func _on_chunk_generator_responded(data) -> void:
	var encoded_chunk_pos = components.ChunkDataComponent.chunk_pos.get_encoded_chunk_pos()
	if data.encoded_chunk_pos == encoded_chunk_pos:
		var arrays := []
		arrays.resize(Mesh.ARRAY_MAX)
		arrays[Mesh.ARRAY_VERTEX] = data.vertices
		arrays[Mesh.ARRAY_NORMAL] = data.normals
		arrays[Mesh.ARRAY_TEX_UV] = data.uvs
		
		var mesh_instance := get_mesh_ins()
		var mesh:ArrayMesh = mesh_instance.mesh
		mesh.clear_surfaces()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
