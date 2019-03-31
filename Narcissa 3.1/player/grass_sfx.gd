extends AudioStreamPlayer
var timepassed = 0.0
onready var grass = [
	preload('res://sound/grass1_rm.wav'),
	preload('res://sound/grass2_rm.wav'),
	preload('res://sound/grass3_rm.wav'),
	preload('res://sound/grass4_rm.wav'),
	preload('res://sound/grass5_rm.wav'),
	preload('res://sound/grass6_rm.wav')]

func grass_walk(delta, velocity):
	timepassed += delta
	if timepassed * velocity > 2:
		var rand_sound = grass[randi() % grass.size()]
		stream = rand_sound
		play()
		timepassed = 0