extends Sprite

onready var minute_hand = $'Minutes'
onready var hour_hand = $'Hours'

var last_known_time = Game.time_of_day

const mh_color = Color('9a5a3b')
const hh_color = Color('9ea3a5')

var current_delta = 0.0

func _ready():
	minute_hand.color = mh_color

func _process(delta):
	current_delta += delta
	if current_delta > 1.0 or Game.player.timescale > 1.0:
		minute_hand.rotation_degrees = fmod(Game.time_of_day, 60.0) * 6
		hour_hand.rotation_degrees = Game.time_of_day / (60.0 * 12.0) * 6
		update()
		current_delta = fmod(current_delta, 1.0)
	
func _draw():
	var pos = Vector2(0, -12.0).rotated(fmod(Game.time_of_day, 60.0) / 60.0 * 2*PI)
	draw_line(Vector2(0,0), pos, mh_color)
	pos = Vector2(0, -7.0).rotated(Game.time_of_day / (60.0 * 12.0) * 2*PI)
	draw_line(Vector2(0,0), pos, hh_color)