extends BaseComponent

@export var render_distance := 6
@export var update_distance := 15
@export var collision_load_distance := 3
@export var collision_unload_distance := 5
@export var noisy_map := true

var chunks := {}

@export var chunk_root_np:NodePath
var chunk_root:Node3D:
	get:
		return get_node(chunk_root_np)

@export var the_noise:OpenSimplexNoise

#----- Dependencies -----
func on_get_components() -> Array[NodePath]:
	return [
		^'ChunkMeshGeneratorComponent',
		^'ChunkDataGeneratorComponent',
	]
#----- Overrides -----
func on_update(delta:float) -> void:
	pass

func on_enabled() -> void:
	$ChunkUpdateTimer.start()
	

func on_disabled() -> void:
	$ChunkUpdateTimer.stop()
#----- Mehtods -----
func set_block_data(pos:Vector3, bd:BlockData) -> void:
	var chunk = get_chunk_by_pos(pos)
	assert(chunk != null)
	var c:ChunkDataComponent = chunk.get_node('ChunkDataComponent')
	if c.chunk_data_status != ChunkDataComponent.ChunkDataStatusType.Valid:
		return
	var cm = chunk.get_node('ChunkMeshComponent')
	c.set_block_data(pos, bd)
	cm.dirty = true
	
	# update adjust blocks of other chunks' faces
	var pos_offset_array := [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	var inverse_index_string_array := ['right', 'left', 'back', 'forward']
	var face_flag_array := [BlockData.FaceFlag.Left, BlockData.FaceFlag.Right, BlockData.FaceFlag.Forward, BlockData.FaceFlag.Back]
	var inverse_face_flag_array := [BlockData.FaceFlag.Right, BlockData.FaceFlag.Left, BlockData.FaceFlag.Back, BlockData.FaceFlag.Forward]
	
	for i in pos_offset_array.size():
		var other_pos = pos + pos_offset_array[i]
		var other_chunk = get_chunk_by_pos(other_pos)
		if other_chunk != chunk:
			var other_chunk_updated:bool = false
			var other_c:ChunkDataComponent = other_chunk.get_node('ChunkDataComponent')
			var other_encoded_pos:int = BlockPosition.encode_pos(other_c.chunk_pos.to_pos_in_chunk(other_pos))
			var other_side_block_data:Dictionary = other_c.block_data_index_map[inverse_index_string_array[i]]
			var other_bd:BlockData = null
			if other_side_block_data.has(other_encoded_pos):
				other_bd = other_side_block_data[other_encoded_pos]
			if other_bd:
				if bd and bd.solid:
					other_bd.faces &= ~inverse_face_flag_array[i]
				else:
					other_bd.faces |= inverse_face_flag_array[i]
				other_chunk_updated = true
			if bd:
				if other_bd and other_bd.solid:
					bd.faces &= ~face_flag_array[i]
				else:
					bd.faces |= face_flag_array[i]
			if other_chunk_updated:
				other_chunk.get_node('ChunkMeshComponent').dirty = true

func get_block_data(pos:Vector3) -> BlockData:
	var chunk = get_chunk_by_pos(pos)
	if chunk == null:
		return null
	return chunk.get_node('ChunkDataComponent').get_block_data(pos)

func get_chunk_by_pos(pos:Vector3) -> Node3D:
	var chunk_pos := BlockPosition.calc_chunk_pos(pos)
	var encoded_chunk_pos := ChunkPosition.encode_chunk_pos(chunk_pos)
	if chunks.has(encoded_chunk_pos):
		return chunks[encoded_chunk_pos]
	return null

func gen_chunk(chunk_pos:Vector2i) -> Node3D:
	var chunk := preload('res://assets/prefabs/Chunk.tscn').instantiate()
	chunk_root.add_child(chunk)
	var c = chunk.get_node('ChunkDataComponent')
	c.chunk_pos = ChunkPosition.create(chunk_pos)
	chunks[c.chunk_pos.get_encoded_chunk_pos()] = chunk
	return chunk

func get_block_data_by_pos_array(poses:Array, res:Array) -> void:
	var chunk_pos_map := {}
	for i in poses.size():
		var p = poses[i]
		var chunk_pos = ChunkPosition.pos_to_chunk_pos(p)
		var encoded_chunk_pos = ChunkPosition.encode_chunk_pos(chunk_pos)
		if chunks.has(encoded_chunk_pos):
			if not chunk_pos_map.has(encoded_chunk_pos):
				chunk_pos_map[encoded_chunk_pos] = [[], []]
			chunk_pos_map[encoded_chunk_pos][0].append(i)
			chunk_pos_map[encoded_chunk_pos][1].append(p)
	for encoded_chunk_pos in chunk_pos_map.keys():
		var _res := []
		_res.resize(chunk_pos_map[encoded_chunk_pos][1].size())
		chunks[encoded_chunk_pos].get_node('ChunkDataComponent').get_block_data_by_pos_array(
			chunk_pos_map[encoded_chunk_pos][1],
			_res
		)
		for i in _res.size():
			res[chunk_pos_map[encoded_chunk_pos][0][i]] = _res[i]

func update_faces_of_the_blocks_that_in_the_edges_of_the_chunk(chunk) -> void:
	var c:ChunkDataComponent = chunk.get_node('ChunkDataComponent')
	var chunk_pos_offset_array := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
	var pos_offset_array := [Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
	var index_string_array := ['left', 'right', 'forward', 'back']
	var inverse_index_string_array := ['right', 'left', 'back', 'forward']
	var face_flag_array := [BlockData.FaceFlag.Left, BlockData.FaceFlag.Right, BlockData.FaceFlag.Forward, BlockData.FaceFlag.Back]
	var inverse_face_flag_array := [BlockData.FaceFlag.Right, BlockData.FaceFlag.Left, BlockData.FaceFlag.Back, BlockData.FaceFlag.Forward]

	for i in chunk_pos_offset_array.size():
#		print('[%s] %s side block count: %s/%s' % [c.chunk_pos.get_chunk_pos(), index_string_array[i], c.block_data_index_map[index_string_array[i]].size(), c.block_data.size()])
		if c.block_data_index_map[index_string_array[i]].size() == 0:
			continue
		var other_chunk_pos := c.chunk_pos.get_chunk_pos() + chunk_pos_offset_array[i]
		var other_encoded_chunk_pos := ChunkPosition.encode_chunk_pos(other_chunk_pos)
		if chunks.has(other_encoded_chunk_pos):
			var other_chunk = chunks[other_encoded_chunk_pos]
			var other_c:ChunkDataComponent = other_chunk.get_node('ChunkDataComponent')
#			print('[%s]%s chunk[%s] data status: %s' % [c.chunk_pos.get_chunk_pos(), index_string_array[i], other_c.chunk_pos.get_chunk_pos(), other_c.chunk_data_status])
			if other_c.chunk_data_status == ChunkDataComponent.ChunkDataStatusType.Valid:
				var other_block_data:Dictionary = other_c.block_data_index_map[inverse_index_string_array[i]]
				var block_data:Dictionary = c.block_data_index_map[index_string_array[i]]
				var other_chunk_updated := false
				for bd in block_data.values():
					var pos:Vector3 = bd.pos.get_pos()
					var other_pos := pos + pos_offset_array[i]
					var other_encoded_pos := BlockPosition.encode_pos(BlockPosition.pos_to_pos_in_chunk(other_pos, other_chunk_pos))
					if other_block_data.has(other_encoded_pos):
						var other_bd:BlockData = other_block_data[other_encoded_pos]
						bd.faces &= ~face_flag_array[i]
						other_bd.faces &= ~inverse_face_flag_array[i]
						other_chunk_updated = true
				if other_chunk_updated:
#					print('update others!')
					other_c.call_deferred('emit_signal_chunk_data_updated')
#----- Signals -----
func _on_chunk_update_timer_timeout() -> void:
	var update_factors := get_tree().get_nodes_in_group('chunk_update_factor')
	# load new chunk
	var new_chunks := []
	for f in update_factors:
		var f_chunk_pos := ChunkPosition.pos_to_chunk_pos(f.global_transform.origin)
		for x in range(-render_distance, render_distance):
			for y in range(-render_distance, render_distance):
				var chunk_pos := f_chunk_pos + Vector2i(x, y)
				if not chunks.has(ChunkPosition.encode_chunk_pos(chunk_pos)):
					var chunk = gen_chunk(chunk_pos)
					new_chunks.append(chunk)
#					
					# in chunk
					# out block_data
					components.ChunkDataGeneratorComponent.request_worker({
						'worker_func': func (data):
							var c:ChunkDataComponent = data.chunk.get_node('ChunkDataComponent')
							c.chunk_data_status = ChunkDataComponent.ChunkDataStatusType.Generating
							if noisy_map:
								for cx in ChunkPosition.CHUNK_SIZE.x:
									for cy in ChunkPosition.CHUNK_SIZE.z:
										var bx:float = chunk_pos.x * ChunkPosition.CHUNK_SIZE.x + cx
										var bz:float = chunk_pos.y * ChunkPosition.CHUNK_SIZE.z + cy
										var my:float = (the_noise.get_noise_2d(bx, bz) + 1)/2.0 * 20
										for by in my:
											c.set_block_data(Vector3(bx, by, bz), DirtBlock.new())
										c.set_block_data(Vector3(bx, my, bz), GrassBlock.new())
							else:
								c.gen_temp_block_data()
							c.chunk_data_status = ChunkDataComponent.ChunkDataStatusType.Valid
							,
						'chunk': chunk,
					})
	
	# update visible
	# unload chunks that too far
	var unloading_chunk_keys := []
	for chunk in chunks.values():
		var c = chunk.get_node('ChunkDataComponent')
		var cm = chunk.get_node('ChunkMeshComponent')
		var chunk_pos:Vector2i = c.chunk_pos.get_chunk_pos()
		var should_visible := false
		var should_unload := true
		for f in update_factors:
			var f_chunk_pos := ChunkPosition.pos_to_chunk_pos(f.global_transform.origin)
			var d := (chunk_pos - f_chunk_pos).length()
			if d <= render_distance:
				should_visible = true
				should_unload = false
				break
			elif d <=update_distance:
				should_unload = false
				break
		if not should_unload:
			cm.set_mesh_visible(should_visible)
		else:
			unloading_chunk_keys.append(c.chunk_pos.get_encoded_chunk_pos())
			chunk.queue_free()
	for k in unloading_chunk_keys:
		chunks.erase(k)
	
	
	

func _on_chunk_data_generator_component_responded(data) -> void:
	var c:ChunkDataComponent = data.chunk.get_node('ChunkDataComponent')
	
	# update faces of the blocks that in the edges of the chunk
	update_faces_of_the_blocks_that_in_the_edges_of_the_chunk(data.chunk)
	
	c.call_deferred('emit_signal_chunk_data_updated')
