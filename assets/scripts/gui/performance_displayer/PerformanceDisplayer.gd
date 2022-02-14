extends Control

@onready var fps_label := $VBoxContainer/FPSLabel
@onready var process_label := $VBoxContainer/ProcessLabel
@onready var physics_label := $VBoxContainer/PhysicsLabel
@onready var pos_label := $VBoxContainer/PosLabel
@onready var mem_label := $VBoxContainer/MemLabel
@onready var draw_calls_label := $VBoxContainer/DrawCallsLabel

func _process(delta: float) -> void:
	fps_label.text = 'FPS: %d' % [Performance.get_monitor(Performance.TIME_FPS)]
	process_label.text = 'Process: %dms' % [Performance.get_monitor(Performance.TIME_PROCESS) * 1000]
	physics_label.text = 'Physics: %dms' % [Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000]
	mem_label.text = 'Mem: %d/%dMB' % [Performance.get_monitor(Performance.MEMORY_STATIC)/1000000.0, Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/1000000.0]
	draw_calls_label.text = 'Draw Calls: %d' % [Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)]

#----- Methods -----
func set_pos_label(s):
	pos_label.text = s
