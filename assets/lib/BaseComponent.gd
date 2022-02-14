extends Node
class_name BaseComponent

var components := {}

@export var enabled := true:
	set (v):
		if enabled != v:
			if v:
				on_enabled()
			else:
				on_disabled()
		enabled = v

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_PREDELETE:
			on_destroy()
		NOTIFICATION_EXIT_TREE:
			enabled = false
		NOTIFICATION_READY:
			_fetch_components()
			if enabled:
				on_enabled()

func _physics_process(delta: float) -> void:
	if enabled:
		on_physics_update(delta)

func _process(delta: float) -> void:
	if enabled:
		on_update(delta)

func _input(event: InputEvent) -> void:
	if enabled:
		on_input(event)

func _unhandled_input(event: InputEvent) -> void:
	if enabled:
		on_unhandled_input(event)
#----- Overrides -----
func on_input(event:InputEvent) -> void:
	pass
func on_unhandled_input(event:InputEvent) -> void:
	pass
func on_update(delta:float) -> void:
	pass
func on_physics_update(delta:float) -> void:
	pass
func on_destroy() -> void:
	pass
func on_enabled() -> void:
	pass
func on_disabled() -> void:
	pass
func on_get_components() -> Array[NodePath]:
	return []
#----- Privates -----
func _fetch_components() -> void:
	var np = on_get_components()
	for p in np:
		var n = get_owner().get_node_or_null(p)
		if n == null:
			printerr('Can\' find component: %s.' % [p])
		components[n.name] = n
#----- Methods -----
func get_owner() -> Node:
	return owner

#----- Signals -----
