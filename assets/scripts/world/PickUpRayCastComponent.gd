extends BaseComponent

@export var ray_cast_np:NodePath
var ray_cast:RayCast3D:
	get:
		return get_node(ray_cast_np)

var current_look_at_block_data:BlockData = null
var current_look_at_block_face:int = 0

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

#----- Signals -----
func _on_update_timer_timeout() -> void:
	if ray_cast.is_colliding():
		var chunk:Node = ray_cast.get_collider().owner
		if chunk == null or not chunk.is_in_group('chunk'):
			return
		var c:ChunkDataComponent = chunk.get_node('ChunkDataComponent')
		var pos := ray_cast.get_collision_point() - ray_cast.get_collision_normal() * 0.01
		var bd:BlockData = c.get_block_data(pos)
		current_look_at_block_data = bd
	else:
		current_look_at_block_data = null
