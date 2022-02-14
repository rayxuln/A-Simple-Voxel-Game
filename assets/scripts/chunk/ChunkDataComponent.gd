extends BaseComponent

signal chunk_data_updated

var block_data := {}
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
				set_block_data(Vector3(x, y, z), bd)
	for x in 16:
		for z in 16:
			set_block_data(Vector3(x, 1, z), GrassBlock.new())
	set_block_data(Vector3(3, 2, 3), StoneBlock.new())
	set_block_data(Vector3(3, 2, 4), StoneBlock.new())
	set_block_data(Vector3(3, 3, 5), StoneBlock.new())
	set_block_data(Vector3(3, 3, 5), StoneBlock.new())
	set_block_data(Vector3(7, 4, 8), StoneBlock.new())
	
func emit_signal_chunk_data_updated():
	chunk_data_updated.emit()

func set_block_data(pos:Vector3, data:BlockData) -> void:
	data.pos = BlockPosition.create(pos, chunk_pos)
	block_data[data.pos.get_encoded_pos()] = data

func get_block_data(pos:Vector3) -> BlockData:
	var encoded_pos := BlockPosition.encode_pos(BlockPosition.pos_to_pos_in_chunk(pos, chunk_pos.get_chunk_pos()))
	if block_data.has(encoded_pos):
		return block_data[encoded_pos]
	return null
#----- Signals -----

