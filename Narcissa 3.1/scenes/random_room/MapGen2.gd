extends Node2D
var grid_size = 32
var rects = []
var border_points = []
var s_point = Vector2()
var player_spawn = Vector2()

export var NO_DRAW = true

onready var canvaslayer = $'..'
onready var meshgen = $'../../MeshGen'

func generate():
	clear_map()
	create_room()
	update()
	meshgen.generate(border_points, player_spawn)
	
func clear_map():
	rects = []

func make_rect():
	# Create rectangle
	var w = 3 + (randi() % 15)
	var l = 3 + (randi() % 15)
	
	# find upper left corner
	var x = randi() % (grid_size - w - 1)
	var y = randi() % (grid_size - l - 1)
	
	return Rect2(x,y,w,l)

func slight_offset(dir):
	match dir:
		"up":
			return Vector2(0, -0.01)
		"down":
			return Vector2(0, 0.01)
		"left":
			return Vector2(-0.01, 0)
		"right":
			return Vector2(0.01, 0)

func create_room():
	rects.append(make_rect())
	player_spawn = rects[0].position + (rects[0].size * rand_range(0.2, 0.8))
	for i in range (1 + (randi() % 4)):
		var new_rect = make_rect()
		while new_rect.intersects(rects[0]) == false:
			new_rect = make_rect()
		rects.append(new_rect)
	var current_rect = start_point()
	s_point = rects[current_rect].position
	var trace_point = s_point
	border_points = [s_point]
	trace_border(trace_point, "right")
	
func trace_border(point, march_dir):
	#print("trace border: " + str(point) + " - heading " + march_dir)
	if border_points.back() == s_point && border_points.size() > 1:
		return
	if border_points.size() > 150: # clean this up later
		print("BAD ERROR, NEVER REACHED STARTING POINT??")
		return
	match march_dir:
		"right":
			for i in range (grid_size):
				point += Vector2.RIGHT
				if is_in_any_rect(point + slight_offset("right") + slight_offset("up")):
					border_points.append(point)
					trace_border(point, "up")
					return
				elif is_in_any_rect(point + slight_offset("right") + slight_offset("down")):
					continue
				else:
					border_points.append(point)
					trace_border(point, "down")
					return
		"down":
			for i in range (grid_size):
				point += Vector2.DOWN
				if is_in_any_rect(point + slight_offset("down") + slight_offset("right")):
					border_points.append(point)
					trace_border(point, "right")
					return
				elif is_in_any_rect(point + slight_offset("down") + slight_offset("left")):
					continue
				else:
					border_points.append(point)
					trace_border(point, "left")
					return
		"left":
			for i in range (grid_size):
				point += Vector2.LEFT
				if is_in_any_rect(point + slight_offset("left") + slight_offset("down")):
					border_points.append(point)
					trace_border(point, "down")
					return
				elif is_in_any_rect(point + slight_offset("left") + slight_offset("up")):
					continue
				else:
					border_points.append(point)
					trace_border(point, "up")
					return
		"up":
			for i in range (grid_size):
				point += Vector2.UP
				if is_in_any_rect(point + slight_offset("up") + slight_offset("left")):
					border_points.append(point)
					trace_border(point, "left")
					return
				elif is_in_any_rect(point + slight_offset("up") + slight_offset("right")):
					continue
				else:
					border_points.append(point)
					trace_border(point, "right")
					return

func start_point():
	#find upper left corner that is not shared
	for i in range (rects.size()):
		var x_in = is_in_any_rect(rects[i].position + slight_offset("left"))
		var y_in = is_in_any_rect(rects[i].position + slight_offset("up"))
		if !x_in and !y_in:
			return i
	print("ERROR - start_point() - no result found")

func is_in_any_rect(point):
	# is this point in any rect?
	for i in range (rects.size()):
		if rects[i].position.x <= point.x && rects[i].end.x >= point.x:
			if rects[i].position.y <= point.y && rects[i].end.y >= point.y:
				return true
	return false

func _draw():
	if NO_DRAW:
		return
	
	
	# ugly setup for drawing the map
	var cell_size = 5
	var pad = 3
	var map_start = Vector2(-pad, -pad)
	var map_end = Vector2((cell_size*32)+pad, (cell_size*32)+pad)
	var map_bordercolor = Color(0.45,0.5,0.7)
	canvaslayer.offset.x = 1920 - map_end.x - pad
	canvaslayer.offset.y = 9
	draw_rect(Rect2(map_start, map_end), Color(0.85,0.9,1,1))
	map_end -= Vector2(pad, pad+1)
	draw_line(map_start, Vector2(map_end.x, map_start.y), map_bordercolor, 2.0, true)
	draw_line(map_end,   Vector2(map_end.x, map_start.y), map_bordercolor, 2.0, true)
	draw_line(map_start, Vector2(map_start.x, map_end.y), map_bordercolor, 2.0, true)
	draw_line(map_end,   Vector2(map_start.x, map_end.y), map_bordercolor, 2.0, true)
	
	# size the rectangles!
	for i in range (rects.size()):
		rects[i].position.x *= cell_size
		rects[i].position.x += pad
		rects[i].position.y *= cell_size
		rects[i].position.y += pad
		rects[i].size.x *= cell_size
		rects[i].size.y *= cell_size
		
	# draw the rectangles!
	for i in range (rects.size()):
		draw_rect(rects[i], Color(0.5,0.6,0.855))
		
	# size the room border points!
	for i in range (border_points.size()):
		border_points[i].x *= cell_size
		border_points[i].x += pad
		border_points[i].y *= cell_size
		border_points[i].y += pad
	var border_color = Color(0,0,0)
	
	# draw the room border!
	for i in range (border_points.size() - 1):
		if i != border_points.size() - 1: #if not final iteration:
			draw_line(border_points[i], border_points[i+1], border_color, 2.0, true)
		else:
			draw_line(border_points[i], border_points[0], border_color, 2.0, true)
	
#	var player_icon := PoolVector2Array([Vector2(-5, -5), Vector2(0, 5), Vector2(5, -5), Vector2(0, -3)])
#	var player_icon_color = Color(0,0,0)
#	var player_icon_colors = PoolColorArray([player_icon_color, player_icon_color, player_icon_color, player_icon_color])
#	draw_polygon(player_icon, player_icon_colors)
#
