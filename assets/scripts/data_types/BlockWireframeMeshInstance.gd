extends MeshInstance3D
class_name BlockWireframeMeshInstance


func _ready() -> void:
	mesh = ArrayMesh.new()
#	layers = 2
#----- Methods -----
func create_mesh_from_block_data(bd:BlockData) -> void:
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	bd.get_wireframe_mesh_data(arrays[Mesh.ARRAY_VERTEX])
	
	var array_mesh:ArrayMesh = mesh
	array_mesh.clear_surfaces()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	
	

#----- Signals -----
