extends TextureRect
const mh_color = Color('9a5a3b')
const hh_color = Color('9ea3a5')
const mh_length = -38.0
const hh_length = -22.0
const offset:Vector2 = Vector2(45, 45)
var current_delta = 0.0

func _process(delta):
	current_delta += delta
	if current_delta > 1.0 or Game.player.timescale > 1.0:
		update()
		current_delta = fmod(current_delta, 1.0)
	
func _draw():
	var pos = Vector2(0, mh_length).rotated(fmod(Game.time_of_day, 60.0) / 60.0 * 2*PI)
	var cross = pos.normalized().rotated(PI/2)
	var points:PoolVector2Array
	points.append(offset + cross)
	points.append(offset + pos)
	points.append(offset - cross)
	points.append(offset + (-pos / 10.0))
	var colors:PoolColorArray = [mh_color, mh_color, mh_color, mh_color]
	draw_polygon ( points, colors, PoolVector2Array(), null, null, true )

	pos = Vector2(0, hh_length).rotated(Game.time_of_day / (60.0 * 12.0) * 2*PI)
	cross = pos.normalized().rotated(PI/2) * 2
	points = []
	points.append(offset + cross)
	points.append(offset + pos)
	points.append(offset - cross)
	points.append(offset + (-pos / 10.0))
	colors = [hh_color, hh_color, hh_color, hh_color]
	draw_polygon ( points, colors, PoolVector2Array(), null, null, true )