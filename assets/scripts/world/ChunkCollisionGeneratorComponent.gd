extends WorkerComponent

#----- Dependencies -----
func on_get_components() -> Array[NodePath]:
	return []
#----- Overrides -----
func on_update(delta:float) -> void:
	super.on_update(delta)

func on_enabled() -> void:
	super.on_enabled()

func on_disabled() -> void:
	super.on_disabled()
#----- Mehtods -----

#----- Signals -----

