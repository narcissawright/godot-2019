extends AudioStreamPlayer

func play_sound(what):
	match what:
		'error':
			volume_db = -20
			pitch_scale = 0.5
			play()
		'up':
			volume_db = -16
			pitch_scale = 1.1
			play()
		'down':
			volume_db = -16
			pitch_scale = 1.0
			play()
		'update_key':
			volume_db = -20
			pitch_scale = 2.0
			play()
