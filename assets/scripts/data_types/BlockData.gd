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
static func get_direction_vector_by_face_flag(_f:int) -> Vector3:
	var face_flag_direction_map := {
		FaceFlag.Top: Vector3.UP,
		FaceFlag.Bottom: Vector3.DOWN,
		FaceFlag.Left: Vector3.LEFT,
		FaceFlag.Right: Vector3.RIGHT,
		FaceFlag.Back: Vector3.BACK,
		FaceFlag.Forward: Vector3.FORWARD,
	}
	if face_flag_direction_map.has(_f):
		return face_flag_direction_map[_f]
	return Vector3.ZERO

static func get_face_flag_text(_f:int) -> String:
	var face_flag_text_map := {
		FaceFlag.Top: 'top',
		FaceFlag.Bottom: 'bottom',
		FaceFlag.Left: 'west',
		FaceFlag.Right: 'east',
		FaceFlag.Back: 'sounth',
		FaceFlag.Forward: 'north',
		FaceFlag.All: 'all',
		FaceFlag.None: 'none',
	}
	if face_flag_text_map.has(_f):
		return face_flag_text_map[_f]
	var _res := []
	var mask := 0x1
	for i in 7:
		if _f & mask:
			_res.append(face_flag_text_map[mask])
		mask <<= 1
	if _res.size() == 0:
		return 'error'
	return '%s' % [_res]

func get_mesh_data(vertices:PackedVector3Array, uvs, use_chunk_pos_as_origin:=true) -> void:
	if use_chunk_pos_as_origin:
		gen_vertices(vertices, pos.get_pos_in_chunk())
	else:
		gen_vertices(vertices, Vector3.ZERO)
	if uvs != null:
		gen_uv(uvs)

func scale_vertices(vertices:PackedVector3Array, scale:float) -> void:
	var center_pos := Vector3(0.5, 0.5, 0.5)
	for i in vertices.size():
		vertices[i] = (vertices[i] - center_pos) * scale + center_pos

func get_wireframe_mesh_data(vertices:PackedVector3Array) -> void:
	var mesh_vertices := PackedVector3Array()
	get_mesh_data(mesh_vertices, null, false)
	var res := PackedVector3Array()
	var i := 0
	while i < mesh_vertices.size():
		
		var a := mesh_vertices[i]
		var b := mesh_vertices[i+1]
		var c := mesh_vertices[i+2]
		var d := mesh_vertices[i+5]
		
		res.append(a)
		res.append(b)
		
		res.append(b)
		res.append(c)
		
		res.append(a)
		res.append(d)
		
		res.append(d)
		res.append(c)
		
		i += 6
	
	scale_vertices(res, 1.001)
	vertices.append_array(res)

func gen_vertices(vertices:PackedVector3Array, offset:Vector3) -> void:
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
	

func gen_uv(uvs:PackedVector2Array) -> void:
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

func get_collision_shapes(body:CollisionObject3D, cs:Array):
	var res := BlockCollisionShape.new()
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
	res.init(body, pos)
	res.shape = shape
	res.name = '%s' % Vector3i(pos.get_pos())
	cs.append(res)
