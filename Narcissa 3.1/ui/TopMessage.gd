extends RichTextLabel
var fade = false
var time = 0.0

func begin_fade():
	modulate = Color(1,1,1,1)
	fade = true
	time = 0.0

func _process(delta):
	if fade:
		time += delta
		if time > 2.0:
			var perc = 1 - ((time-2.0) / 1.2)
			if perc > 1:
				modulate = Color(0,0,0,0)
				fade = false
			else:
				modulate = Color(perc,perc,perc*2,perc)