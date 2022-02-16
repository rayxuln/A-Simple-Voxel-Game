extends Node3D
class_name BlockCollisionShape

@export var shape:Shape3D:
	set(v):
		shape = v
		sync_dirty = true

var body:CollisionObject3D
var block_pos:BlockPosition
var shape_owner_id:int = -1

var sync_dirty := true

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if body:
			body.remove_shape_owner(shape_owner_id)

func _process(delta: float) -> void:
	if sync_dirty:
		sync_body_shape()
#----- Methods -----
func init(_body:CollisionObject3D, _block_pos:BlockPosition) -> void:
	block_pos = _block_pos.clone()
	body = _body
	shape_owner_id = body.create_shape_owner(self)
	sync_dirty = true

func sync_body_shape():
	if body and shape and shape_owner_id >= 0:
		body.shape_owner_clear_shapes(shape_owner_id)
		body.shape_owner_add_shape(shape_owner_id, shape)
		sync_dirty = false
#----- Signals -----
