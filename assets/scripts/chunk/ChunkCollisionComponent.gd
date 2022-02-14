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
	for c in body.get_children():
		if c is CollisionShape3D:
			c.queue_free()
	
	var cs := []
	for block_data in components.ChunkDataComponent.block_data.values():
		block_data.get_collision_shapes(cs)
	
	for c in cs:
		body.add_child(c)


#----- Signals -----
func _on_chunk_data_component_chunk_data_updated() -> void:
	pass
#	update_collision_shapes()
