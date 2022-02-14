extends BaseComponent

var chunks := {}

@export var chunk_root_np:NodePath
var chunk_root:Node3D:
	get:
		return get_node(chunk_root_np)

@export var the_noise:OpenSimplexNoise

#----- Dependencies -----
func on_get_components() -> Array[NodePath]:
	return []
#----- Overrides -----
func on_update(delta:float) -> void:
	pass

func on_enabled() -> void:
	$ChunkUpdateTimer.start()
	

func on_disabled() -> void:
	$ChunkUpdateTimer.stop()
#----- Mehtods -----
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


#----- Signals -----
func _on_chunk_update_timer_timeout() -> void:
	var update_factors := get_tree().get_nodes_in_group('chunk_update_factor')
	# load new chunk
	var new_chunks := []
	for f in update_factors:
		var f_chunk_pos := ChunkPosition.pos_to_chunk_pos(f.global_transform.origin)
		for x in range(-4, 4):
			for y in range(-4, 4):
				var chunk_pos := f_chunk_pos + Vector2i(x, y)
				if not chunks.has(ChunkPosition.encode_chunk_pos(chunk_pos)):
					var chunk = gen_chunk(chunk_pos)
					new_chunks.append(chunk)
					var c = chunk.get_node('ChunkDataComponent')
					for cx in 16:
						for cy in 16:
							var bx:float = chunk_pos.x * 16.0 + cx
							var bz:float = chunk_pos.y * 16.0 + cy
							var my:float = (the_noise.get_noise_2d(bx, bz) + 1)/2.0 * 20
							for by in my:
								c.set_block_data(Vector3(bx, by, bz), DirtBlock.new())
							c.set_block_data(Vector3(bx, my, bz), GrassBlock.new())
		for chunk in new_chunks:
			var c = chunk.get_node('ChunkDataComponent')
			c.call_deferred('emit_signal_chunk_data_updated')
	
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
			var d := (chunk_pos - f_chunk_pos).length_squared()
			if d <= 16:
				should_visible = true
				should_unload = false
				break
			elif d <= 25:
				should_unload = false
				break
		if not should_unload:
			cm.set_mesh_visible(should_visible)
		else:
			unloading_chunk_keys.append(c.chunk_pos.get_encoded_chunk_pos())
			chunk.queue_free()
	for k in unloading_chunk_keys:
		chunks.erase(k)
	
	
	
