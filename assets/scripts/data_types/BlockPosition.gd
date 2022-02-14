extends RefCounted
class_name BlockPosition

var encoded_pos:int
var chunk_pos:ChunkPosition

#----- Methods -----
static func create(_pos:Vector3, _chunk_pos:ChunkPosition) -> BlockPosition:
	var p = BlockPosition.new()
	p.chunk_pos = _chunk_pos.clone()
	p.set_pos(_pos)
	return p

static func pos_to_pos_in_chunk(pos:Vector3, _chunk_pos:Vector2i) -> Vector3:
	return pos - Vector3(_chunk_pos.x*ChunkPosition.CHUNK_SIZE.x, 0, _chunk_pos.y*ChunkPosition.CHUNK_SIZE.z)

static func pos_in_chunk_to_pos(pos_in_chunk:Vector3, _chunk_pos:Vector2i) -> Vector3:
	return pos_in_chunk + Vector3(_chunk_pos.x*ChunkPosition.CHUNK_SIZE.x, 0, _chunk_pos.y*ChunkPosition.CHUNK_SIZE.z)

static func encode_pos(pos:Vector3) -> int:
	@warning_ignore(narrowing_conversion)
	var x:int = floor(pos.x)
	@warning_ignore(narrowing_conversion)
	var y:int = floor(pos.y)
	@warning_ignore(narrowing_conversion)
	var z:int = floor(pos.z)
	
	x = x & 0xf
	y = y & 0xff
	z = z & 0xf
	
	var res:int = (x<<12) | (y<<4) | z
	return res

static func decode_pos(pos:int) -> Vector3:
	var x := (pos & 0xf000) >> 12
	var y := (pos & 0x0ff0) >> 4
	var z := (pos & 0x000f)
	return Vector3(x, y, z)

static func calc_chunk_pos(pos:Vector3) -> Vector2i:
	@warning_ignore(narrowing_conversion)
	return Vector2i(
		floor(pos.x/16),
		floor(pos.z/16),
	)

static func is_chunk_pos_same(chunk_pos_a:Vector2i, chunk_pos_b:Vector2i) -> bool:
	return chunk_pos_a.x == chunk_pos_b.x and chunk_pos_a.y == chunk_pos_b.y

func get_encoded_pos() -> int:
	return encoded_pos

func get_pos_in_chunk() -> Vector3:
	return decode_pos(encoded_pos)

func get_pos() -> Vector3:
	return pos_in_chunk_to_pos(get_pos_in_chunk(), chunk_pos.get_chunk_pos())

func set_pos(pos:Vector3) -> void:
	encoded_pos = encode_pos(pos_to_pos_in_chunk(pos, chunk_pos.get_chunk_pos()))

func clone() -> BlockPosition:
	var p := BlockPosition.new()
	p.encoded_pos = encoded_pos
	p.chunk_pos = chunk_pos.clone()
	return p
