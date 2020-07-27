extends Camera
var current_axis:Vector3 = Vector3(randf()*2-1, randf()*2-1, randf()*2-1).normalized()
var future_axis:Vector3
var frame_ticks = 0

func _ready():
	future_axis = new_axis(current_axis)

func new_axis(current_axis):
	future_axis = Vector3(randf()*2-1, randf()*2-1, randf()*2-1).normalized()
	while current_axis.dot(future_axis) < 0:
		future_axis = Vector3(randf()*2-1, randf()*2-1, randf()*2-1).normalized()
	return future_axis

func _process(delta):
	frame_ticks += 1
	frame_ticks = frame_ticks % 300
	var axis = current_axis * (1 - (float(frame_ticks) / 300)) + future_axis * (float(frame_ticks) / 300)
	
	if frame_ticks % 300 == 0:
		current_axis = future_axis
		axis = current_axis
		future_axis = new_axis(current_axis)
	
	global_rotate (axis.normalized(), deg2rad(0.1))
