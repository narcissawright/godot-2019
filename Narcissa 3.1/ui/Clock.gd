extends TextureRect

#onready var minute_hand = $'Minutes'
#onready var hour_hand = $'Hours'

var last_known_time = Game.time_of_day

const mh_color = Color('9a5a3b')
const hh_color = Color('9ea3a5')

var current_delta = 0.0

func _ready():
	pass
	#minute_hand.color = mh_color

func _process(delta):
	current_delta += delta
	if current_delta > 1.0 or Game.player.timescale > 1.0:
		update()
		current_delta = fmod(current_delta, 1.0)
	
func _draw():
	var offset = Vector2(15,15)
	var pos = Vector2(0, -12.0).rotated(fmod(Game.time_of_day, 60.0) / 60.0 * 2*PI)
	var pos2 = pos.rotated(PI / 8).normalized()
	var pos3 = pos.rotated(-PI / 8).normalized()
	draw_line(offset, pos + offset, mh_color)
	draw_line(offset + pos2, pos*0.75 + offset, mh_color)
	draw_line(offset + pos3, pos*0.75 + offset, mh_color)
	pos = Vector2(0, -8.0).rotated(Game.time_of_day / (60.0 * 12.0) * 2*PI)
	pos2 = pos.rotated(PI / 4).normalized()
	pos3 = pos.rotated(-PI / 4).normalized()
	draw_line(offset, pos + offset, hh_color)
	draw_line(offset + pos2, pos*0.75 + offset, hh_color)
	draw_line(offset + pos3, pos*0.75 + offset, hh_color)