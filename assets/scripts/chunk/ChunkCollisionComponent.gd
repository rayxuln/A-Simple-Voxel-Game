extends BaseComponent

@export var body_np:NodePath
var body:StaticBody3D:
	get:
		return get_node(body_np)

#----- Dependencies -----
func on_get_components() -> Array[NodePath]:
	return [
		^'ChunkDataComponent',
	]
#----- Overrides -----
func on_update(delta:float) -> void:
	pass

func on_enabled() -> void:
	pass

func on_disabled() -> void:
	pass
#----- Mehtods -----
func update_collision_shapes() -> void:
	var factors:Array = get_tree().get_nodes_in_group('chunk_update_factor')
	var poses := []
	for f in factors:
		poses.append(f.global_transform.origin)
	
	var chunk_manager = GameSystem.get_world().get_node('ChunkManagerComponent')
	var load_distance:float = chunk_manager.collision_load_distance
	var unload_distance:float = chunk_manager.collision_unload_distance
	var load_chunk_distance:float = floor(load_distance / ChunkPosition.CHUNK_SIZE.x) + 1
	
	var loaded_encoded_pos_map := {}
	
	for c in body.get_children():
		if c is CollisionShape3D:
			var should_unload := true
			var encoded_pos:int = c.get_meta('encoded_pos')
			if components.ChunkDataComponent.has_block_data_exist(encoded_pos):
				var pos:Vector3 = components.ChunkDataComponent.chunk_pos.to_pos(BlockPosition.decode_pos(encoded_pos))
				for f_pos in poses:
					var d:Vector3 = pos - f_pos
					var l := d.length()
					if l <= unload_distance:
						should_unload = false
						break
			if should_unload:
				c.queue_free()
			else:
				loaded_encoded_pos_map[encoded_pos] = true
	
	var should_load := false
	for f_pos in poses:
		var f_chunk_pos := BlockPosition.calc_chunk_pos(f_pos)
		var d:Vector2i = f_chunk_pos - components.ChunkDataComponent.chunk_pos.get_chunk_pos()
		var l:float = d.length()
		if l <= load_chunk_distance:
			should_load = true
			break
	
	if should_load:
		var cs := []
		var block_data:Array = components.ChunkDataComponent.get_block_data_arround_pos(poses, load_distance, loaded_encoded_pos_map)
		for bd in block_data:
			bd.get_collision_shapes(cs)
		
		for c in cs:
			body.add_child(c)


#----- Signals -----
func _on_chunk_data_component_chunk_data_updated() -> void:
	update_collision_shapes()


func _on_update_timer_timeout() -> void:
	update_collision_shapes()
