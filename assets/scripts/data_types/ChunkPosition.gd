extends RefCounted
class_name ChunkPosition

const CHUNK_SIZE := Vector3i(16, 256, 16)

var encoded_chunk_pos:int

#----- Methods -----
static func create(_chunk_pos:Vector2i) -> ChunkPosition:
	var p := ChunkPosition.new()
	p.set_chunk_pos(_chunk_pos)
	return p

static func encode_chunk_pos(_chunk_pos:Vector2i) -> int:
	var res := 0
	
	res |= (abs(_chunk_pos.x) & 0x7fffffff) << 32
	res |= (1<<63) if _chunk_pos.x < 0 else 0
	res |= abs(_chunk_pos.y) & 0x7fffffff
	res |= (1<<31) if _chunk_pos.y < 0 else 0
	
	return res

static func decode_chunk_pos(_encoded_chunk_pos:int) -> Vector2i:
	var res := Vector2i()
	
	res.x = (_encoded_chunk_pos & 0x7fffffff00000000) >> 32
	res.x *= -1 if (_encoded_chunk_pos & 1<<63) else 1
	res.y = (_encoded_chunk_pos & 0x000000007fffffff)
	res.y *= -1 if (_encoded_chunk_pos & 1<<31) else 1
	
	return res

static func chunk_pos_to_pos(_chunk_pos:Vector2i) -> Vector3:
	return Vector3(_chunk_pos.x * CHUNK_SIZE.x, 0, _chunk_pos.y * CHUNK_SIZE.z)

static func pos_to_chunk_pos(_pos:Vector3) -> Vector2i:
	@warning_ignore(narrowing_conversion)
	return Vector2i(floor(_pos.x / CHUNK_SIZE.x), floor(_pos.z /CHUNK_SIZE.z))

func set_chunk_pos(_chunk_pos) -> void:
	encoded_chunk_pos = encode_chunk_pos(_chunk_pos)

func get_chunk_pos() -> Vector2i:
	return decode_chunk_pos(encoded_chunk_pos)

func get_pos() -> Vector3:
	return chunk_pos_to_pos(get_chunk_pos())

func get_encoded_chunk_pos() -> int:
	return encoded_chunk_pos

func to_pos(pos_in_chunk:Vector3) -> Vector3:
	var _chunk_pos := get_chunk_pos()
	return pos_in_chunk + Vector3(_chunk_pos.x*ChunkPosition.CHUNK_SIZE.x, 0, _chunk_pos.y*ChunkPosition.CHUNK_SIZE.z)

func to_pos_in_chunk(pos:Vector3) -> Vector3:
	var _chunk_pos := get_chunk_pos()
	return pos - Vector3(_chunk_pos.x*CHUNK_SIZE.x, 0, _chunk_pos.y*CHUNK_SIZE.z)

func clone() -> ChunkPosition:
	var c = ChunkPosition.new()
	c.encoded_chunk_pos = encoded_chunk_pos
	return c
