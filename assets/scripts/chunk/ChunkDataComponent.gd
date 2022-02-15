extends BaseComponent
class_name ChunkDataComponent

signal chunk_data_updated

var block_data := {}
var block_data_index_map := {
	'left': {},
	'right': {},
	'forward': {},
	'back': {},
}
var block_data_mutex := Mutex.new()

enum ChunkDataStatusType {
	Invalid,
	Loading,
	Generating,
	Valid,
}
var chunk_data_status:int = ChunkDataStatusType.Invalid:
	set(v):
		chunk_data_status_mutex.lock()
		chunk_data_status = v
		chunk_data_status_mutex.unlock()
	get:
		chunk_data_status_mutex.lock()
		var v = chunk_data_status
		chunk_data_status_mutex.unlock()
		return v
var chunk_data_status_mutex := Mutex.new()

var chunk_pos:ChunkPosition = ChunkPosition.new():
	set(v):
		chunk_pos = v
		var o:Node3D = get_owner()
		o.global_transform.origin = chunk_pos.get_pos()

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
func gen_temp_block_data() -> void:
	for x in 16:
		for y in 0:
			for z in 16:
				var bd = DirtBlock.new()
				set_block_data(chunk_pos.to_pos(Vector3(x, y, z)), bd)
	for x in 16:
		for z in 16:
			set_block_data(chunk_pos.to_pos(Vector3(x, 1, z)), GrassBlock.new())
	set_block_data(chunk_pos.to_pos(Vector3(3, 2, 3)), StoneBlock.new())
	set_block_data(chunk_pos.to_pos(Vector3(3, 2, 4)), StoneBlock.new())
	set_block_data(chunk_pos.to_pos(Vector3(3, 3, 5)), StoneBlock.new())
	set_block_data(chunk_pos.to_pos(Vector3(3, 3, 5)), StoneBlock.new())
	set_block_data(chunk_pos.to_pos(Vector3(7, 4, 8)), StoneBlock.new())
	
func emit_signal_chunk_data_updated():
	chunk_data_updated.emit()

func set_block_data(pos:Vector3, data:BlockData) -> void:
	var pos_in_chunk:Vector3 = chunk_pos.to_pos_in_chunk(pos)
	if not BlockPosition.is_pos_in_chunk_valid(pos_in_chunk):
		return
	if data:
		data.pos = BlockPosition.create(pos, chunk_pos)
		var encoded_pos = data.pos.get_encoded_pos()
		calc_and_update_face_falgs_by_pos(data, data.pos.get_pos())
		block_data_mutex.lock()
		block_data[encoded_pos] = data
		block_data_mutex.unlock()
		
		# update index map
		if is_equal_approx(floor(pos_in_chunk.x), 0):
			block_data_index_map.left[encoded_pos] = data
		if is_equal_approx(floor(pos_in_chunk.x), ChunkPosition.CHUNK_SIZE.x-1):
			block_data_index_map.right[encoded_pos] = data
		if is_equal_approx(floor(pos_in_chunk.z), 0):
			block_data_index_map.forward[encoded_pos] = data
		if is_equal_approx(floor(pos_in_chunk.z), ChunkPosition.CHUNK_SIZE.z-1):
			block_data_index_map.back[encoded_pos] = data
	else: # remove the block
		var encoded_pos = BlockPosition.encode_pos(pos_in_chunk)
		if block_data.has(encoded_pos):
			block_data.erase(encoded_pos)
			
			calc_and_update_face_falgs_by_pos(null, pos)
			
			# update index map
			if is_equal_approx(floor(pos_in_chunk.x), 0):
				block_data_index_map.left.erase(encoded_pos)
			if is_equal_approx(floor(pos_in_chunk.x), ChunkPosition.CHUNK_SIZE.x-1):
				block_data_index_map.right.erase(encoded_pos)
			if is_equal_approx(floor(pos_in_chunk.z), 0):
				block_data_index_map.forward.erase(encoded_pos)
			if is_equal_approx(floor(pos_in_chunk.z), ChunkPosition.CHUNK_SIZE.z-1):
				block_data_index_map.back.erase(encoded_pos)
		

func calc_and_update_face_falgs_by_pos(data:BlockData, pos:Vector3) -> void:
	if data:
		data.faces = BlockData.FaceFlag.None
#	var chunk_manager:BaseComponent = GameSystem.get_world().get_node(^'ChunkManagerComponent')
	
	var possible_poses := [
		pos + Vector3.UP,
		pos + Vector3.DOWN,
		pos + Vector3.LEFT,
		pos + Vector3.RIGHT,
		pos + Vector3.FORWARD,
		pos + Vector3.BACK,
	]
	var faces_array := [
		BlockData.FaceFlag.Top,
		BlockData.FaceFlag.Bottom,
		BlockData.FaceFlag.Left,
		BlockData.FaceFlag.Right,
		BlockData.FaceFlag.Forward,
		BlockData.FaceFlag.Back,
	]
	var inverse_faces_array := [
		BlockData.FaceFlag.Bottom,
		BlockData.FaceFlag.Top,
		BlockData.FaceFlag.Right,
		BlockData.FaceFlag.Left,
		BlockData.FaceFlag.Back,
		BlockData.FaceFlag.Forward,
	]
	var block_datas := []
	block_datas.resize(possible_poses.size())
	get_block_data_by_pos_array(possible_poses, block_datas)
#	chunk_manager.get_block_data_by_pos_array(possible_poses, block_datas)
	
	var i := 0
	while i < possible_poses.size():
		if block_datas[i]:
			if data and data.solid:
				block_datas[i].faces &= ~inverse_faces_array[i]
			else:
				block_datas[i].faces |= inverse_faces_array[i]
		if data and not (block_datas[i] and block_datas[i].solid):
			data.faces |= faces_array[i]
		i += 1

func get_block_data(pos:Vector3) -> BlockData:
	var pos_in_chunk := BlockPosition.pos_to_pos_in_chunk(pos, chunk_pos.get_chunk_pos())
	if not BlockPosition.is_pos_in_chunk_valid(pos_in_chunk):
		return null
	var res:BlockData = null
	var encoded_pos := BlockPosition.encode_pos(pos_in_chunk)
	block_data_mutex.lock()
	if block_data.has(encoded_pos):
		res = block_data[encoded_pos]
	else:
		res = null
	block_data_mutex.unlock()
	return res

func get_block_data_by_pos_array(poses:Array, res:Array) -> void:
	block_data_mutex.lock()
	for i in poses.size():
		var pos_in_chunk := BlockPosition.pos_to_pos_in_chunk(poses[i], chunk_pos.get_chunk_pos())
		if not BlockPosition.is_pos_in_chunk_valid(pos_in_chunk):
			continue
		var encoded_pos := BlockPosition.encode_pos(pos_in_chunk)
		if block_data.has(encoded_pos):
			res[i] = block_data[encoded_pos]
	block_data_mutex.unlock()
#----- Signals -----

