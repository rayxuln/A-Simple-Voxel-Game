extends BaseComponent
class_name WorkerComponent

signal responded(data)

var request_queue := []
var respond_queue := []

@export var worker_count := 1
var workers:Array = []

#----- Dependencies -----
func on_get_components() -> Array[NodePath]:
	return []
#----- Overrides -----
func on_update(delta:float) -> void:
	for res in respond_queue:
		responded.emit(res)
	respond_queue.clear()
	
	if request_queue.size() == 0:
		return
	var idle_workers:Array = []
	for w in workers:
		if w.get_status() == ChunkWorker.StatusType.Idle:
			idle_workers.append(w)
	for w in idle_workers:
		if request_queue.size() == 0:
			break
		var req = request_queue.pop_front()
		w.start(req)

func on_enabled() -> void:
	var w := ChunkWorker.new()
	workers.append(w)
	add_child(w)
	w.connect('finished', self.on_worker_finished, [w], CONNECT_DEFERRED)
	w.name = 'ChunkWorker_%d' % [workers.size()-1]

func on_disabled() -> void:
	pass
#----- Mehtods -----
func request_worker(data):
	request_queue.append(data)
#----- Signals -----
func on_worker_finished(worker:ChunkWorker):
	respond_queue.append(worker.get_ready_data_and_reset())
