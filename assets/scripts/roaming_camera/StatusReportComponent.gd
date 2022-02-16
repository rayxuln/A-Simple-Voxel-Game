extends BaseComponent

#----- Dependencies -----
func on_get_components() -> Array[NodePath]:
	return [
		^'PickUpRayCastComponent',
	]
#----- Overrides -----
func on_update(delta:float) -> void:
	var pick_up_ray_cast_component = components.PickUpRayCastComponent
	var block_pos_string := 'none'
	var bd:BlockData = pick_up_ray_cast_component.current_look_at_block_data
	if bd:
		block_pos_string = '%s' % [Vector3i(bd.pos.get_pos())]
	var s := 'Pos: %s, Chunk: %s, Look At: %s, Face: %s' % [
		Vector3i(get_owner().global_transform.origin),
		ChunkPosition.pos_to_chunk_pos(get_owner().global_transform.origin),
		block_pos_string,
		BlockData.get_face_flag_text(pick_up_ray_cast_component.current_look_at_block_face),
	]
	GameSystem \
	.get_gui('PerformanceDisplayer') \
	.set_pos_label(s)
	

func on_enabled() -> void:
	pass

func on_disabled() -> void:
	pass
#----- Mehtods -----

#----- Signals -----

