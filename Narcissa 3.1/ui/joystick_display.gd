extends Control

const common = preload("res://code/common.gd") # common functions
const size = 20.0
const offset = 48.0

var prior_circle_opacity:Array = [0.0, 0.0]
var prior_input_position:Array = [
		[Rect2(), Rect2(), Rect2(), Rect2(), Rect2(), 
	 	Rect2(), Rect2(), Rect2(), Rect2(), Rect2()], 
		[Rect2(), Rect2(), Rect2(), Rect2(), Rect2(), 
	 	Rect2(), Rect2(), Rect2(), Rect2(), Rect2()]
	]

func flush(axis):
	for j in range (10):
		prior_input_position[axis][j].position = Vector2(size + (offset * axis), size)
		prior_input_position[axis][j].size = Vector2(2,2)

func _ready():
	for axis in range(2):
		flush(axis)

func _process(time):
	update()

func _draw():
	for i in range (2):
		var input:Vector2 = common.deadzone(0 + i*2, 1 + i*2)
		var rect_x:float = round((input.x * size) + size + (offset * i) - 1)
		var rect_y:float = round((input.y * size) + size - 1)
		var rect_dot = Rect2(Vector2(rect_x, rect_y), Vector2(2, 2))
		var input_strength = input.length_squared()
		
		var circle_color:Color
		var dot_color:Color
		if input_strength > 0.01:
			if input_strength > 0.99:
				circle_color = Color(0.4, 0.3, 0.5, input_strength * 0.15)
				dot_color = Color(1,1,1,1)
			else:
				circle_color = Color(0.4, 0.3, 0.5, input_strength * 0.1)
				dot_color = Color(0.6, 0.6, 1, 0.5 + (input_strength / 2.0))
			draw_circle(Vector2(size + (offset * i), size), size+2, Color(0,0,0, input_strength * 0.15))
			draw_circle(Vector2(size + (offset * i), size), size, circle_color)
			for j in range (9):
				draw_line ( prior_input_position[i][j].position, prior_input_position[i][j+1].position, Color(0.04*j,0.03*j,0.08*j, (j+1) / 15.0), 2.0, true )
			
			draw_rect(Rect2(Vector2(size + offset*i, size), Vector2(2,2)), Color(0,0,0, 0.5 + (input_strength / 2.0)))
			draw_rect(rect_dot, dot_color)
		prior_input_position[i].pop_front()
		prior_input_position[i].append(rect_dot)