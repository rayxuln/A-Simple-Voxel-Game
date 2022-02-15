extends RefCounted
class_name BlockData

enum FaceFlag {
	Top = 0x01, 		# +y
	Bottom = 0x02, 	# -y
	Left = 0x04, 		# -x
	Right = 0x08, 	# +x
	Back = 0x20, 		# +z
	Forward = 0x10, 	# -z
	All = 0x3f,
	None = 0x00,
}

var solid:bool = true

var pos:BlockPosition = null
var data:Dictionary = {
	'tex': {
		'top': 0,
		'bottom': 2,
		'left': 1,
		'right': 1,
		'forward': 1,
		'back': 1,
	},
}
var faces:int = FaceFlag.All

#----- Methods -----
func get_mesh_data(vertices:PackedVector3Array, uvs:PackedVector2Array) -> void:
	gen_a_cube_vertices(vertices, pos.get_pos_in_chunk())
	gen_cube_uv(uvs)

func gen_a_cube_vertices(vertices:PackedVector3Array, offset:Vector3) -> void:
	if faces == FaceFlag.None:
		return
	
	# right hand
	var original_vertices:Array[Vector3] = [
		Vector3(0, 1, 0),
		Vector3(1, 1, 0),
		Vector3(1, 1, 1),
		Vector3(0, 1, 1),
		
		Vector3(0, 0, 0),
		Vector3(1, 0, 0),
		Vector3(1, 0, 1),
		Vector3(0, 0, 1),
	]
	
#	var original_vertices_offset := Vector3(-0.5, -0.5, -0.5)
	var i = 0
	while i < original_vertices.size():
#		original_vertices[i] += original_vertices_offset
		original_vertices[i] += offset
		i += 1
	
	# clockwise
	var indices := []
	if faces & FaceFlag.Top:
		indices.append_array([
			# top
			0, 1, 2,
			0, 2, 3,
		])
	if faces & FaceFlag.Bottom:
		indices.append_array([
			# bottom
			7, 6, 5,
			7, 5, 4,
		])
	if faces & FaceFlag.Left:
		indices.append_array([
			# left
			0, 3, 7,
			0, 7, 4,
		])
	if faces & FaceFlag.Right:
		indices.append_array([
			# right
			2, 1, 5,
			2, 5, 6,
		])
	if faces & FaceFlag.Forward:
		indices.append_array([
			# forward
			1, 0, 4,
			1, 4, 5,
		])
	if faces & FaceFlag.Back:
		indices.append_array([
			# back
			3, 2, 6,
			3, 6, 7,
		])
	
	for i in indices:
		vertices.append(original_vertices[i])
	

func gen_cube_uv(uvs:PackedVector2Array) -> void:
	var tex_size:Vector2 = Vector2(64, 64)
	var unit_size:Vector2 = Vector2(16, 16)
	var unit_num:Vector2i = tex_size / unit_size
	var uv_unit_size:Vector2 = Vector2(1.0/unit_num.x, 1.0/unit_num.y)
	var piexl_offset:Array[Vector2] = [
		Vector2(0.02, 0.02),
		Vector2(-0.02, 0.02),
		Vector2(-0.02, -0.02),
		Vector2(0.02, -0.02),
	]
	
	var face_flag_temp := [
		FaceFlag.Top,
		FaceFlag.Bottom,
		FaceFlag.Left,
		FaceFlag.Right,
		FaceFlag.Forward,
		FaceFlag.Back,
	]
	var face_strings := [
		'top',
		'bottom',
		'left',
		'right',
		'forward',
		'back',
	]
	
	var i := 0
	while i < face_flag_temp.size():
		if faces & face_flag_temp[i]:
			var tex_id = data.tex[face_strings[i]]
			var offset:Vector2 = Vector2(uv_unit_size.x * (tex_id%unit_num.x), uv_unit_size.y * floor(tex_id/unit_num.y))
			uvs.push_back(offset + piexl_offset[0])
			uvs.push_back(offset + Vector2(uv_unit_size.x, 0) + piexl_offset[1])
			uvs.push_back(offset + Vector2(uv_unit_size.x, uv_unit_size.y) + piexl_offset[2])
			
			uvs.push_back(offset + piexl_offset[0])
			uvs.push_back(offset + Vector2(uv_unit_size.x, uv_unit_size.y) + piexl_offset[2])
			uvs.push_back(offset + Vector2(0, uv_unit_size.y) + piexl_offset[3])
		i += 1

func get_collision_shapes(cs:Array):
	var res := CollisionShape3D.new()
	var shape := ConvexPolygonShape3D.new()
	var points := PackedVector3Array()
	var offset := pos.get_pos_in_chunk() # - Vector3(0.5, 0.5, 0.5)
	points.append(offset + Vector3(0, 1, 0))
	points.append(offset + Vector3(1, 1, 0))
	points.append(offset + Vector3(1, 1, 1))
	points.append(offset + Vector3(0, 1, 1))
	points.append(offset + Vector3(0, 0, 0))
	points.append(offset + Vector3(1, 0, 0))
	points.append(offset + Vector3(1, 0, 1))
	points.append(offset + Vector3(0, 0, 1))
	shape.points = points
	res.shape = shape
	cs.append(res)
