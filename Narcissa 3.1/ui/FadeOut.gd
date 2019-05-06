extends ColorRect
var fading_out:bool = false
var fading_in:bool = false

func _ready():
	show()

func fadeout():
	fading_out = true
	fading_in = false
func fadein():
	fading_in = true
	fading_out = false
	AudioServer.set_bus_volume_db(0, -50)
	
func _process(t):
	if fading_out:
		color.a += 0.02
		AudioServer.set_bus_volume_db(0, AudioServer.get_bus_volume_db(0)-1)
		if color.a >= 1:
			fading_out = false
			AudioServer.set_bus_volume_db(0, -50)
			if Game.player.health <= 0:
				Game.respawn()
				Game.player.health = 100
				Game.player.lockplayerinput = false
				fading_in = true
	elif fading_in:
		AudioServer.set_bus_volume_db(0, AudioServer.get_bus_volume_db(0)+1)
		if AudioServer.get_bus_volume_db(0) > 0:
			AudioServer.set_bus_volume_db(0, 0)
		color.a -= 0.02
		if color.a <= 0:
			fading_in = false
			AudioServer.set_bus_volume_db(0, 0)