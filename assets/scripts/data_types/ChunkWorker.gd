extends Node
class_name ChunkWorker

signal finished

var thread:Thread

enum StatusType {
	Idle,
	Working,
	Finished,
}

var status = StatusType.Idle
var status_mutex := Mutex.new()

var ready_data
var ready_data_mutex := Mutex.new()

func _ready() -> void:
	thread = Thread.new()

#func _exit_tree() -> void:
#	if thread.is_alive():
#		thread.wait_to_finish()

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if thread.is_alive():
			thread.wait_to_finish()
#----- Methods -----
func start(data):
	assert(not thread.is_alive())
	if thread.is_started():
		thread.wait_to_finish()
	thread.start(_thread_run, data)
	status = StatusType.Working

func _thread_run(data):
	ready_data = data
	
	data.worker_func.call(data)
	
	status_mutex.lock()
	status = StatusType.Finished
	status_mutex.unlock()
	finished.emit()

func get_status():
	status_mutex.lock()
	var s = status
	status_mutex.unlock()
	return s

func get_ready_data_and_reset():
#	set_timeout(0.1, func (that): that.status = StatusType.Idle)
	status = StatusType.Idle
	var res = ready_data
	ready_data = null
	return res

func set_timeout(t_sec:float, c:Callable):
	await get_tree().create_timer(t_sec).timeout
	c.call(self)
