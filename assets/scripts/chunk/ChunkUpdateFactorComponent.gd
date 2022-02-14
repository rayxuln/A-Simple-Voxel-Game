extends BaseComponent

#----- Dependencies -----
func on_get_components() -> Array[NodePath]:
	return []
#----- Overrides -----
func on_update(delta:float) -> void:
	pass

func on_enabled() -> void:
	get_owner().add_to_group('chunk_update_factor')

func on_disabled() -> void:
	get_owner().remove_from_group('chunk_update_factor')
#----- Mehtods -----

#----- Signals -----

