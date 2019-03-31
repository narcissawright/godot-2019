extends ColorRect
var fadein = false
var fadeout = false

func fadein():
	fadeout = false
	fadein = true
	set_process(true)
	
func fadeout():
	fadeout = true
	fadein = false
	set_process(true)
	
func _process(delta):
	if fadein:
		color.a += 0.05
		if color.a >= 1:
			fadein = false
			set_process(false)
	elif fadeout:
		color.a -= 0.05
		if color.a <= 0:
			fadeout = false
			set_process(false)