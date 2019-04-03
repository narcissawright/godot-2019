extends Control

var textures = []
const STARTOTAL = 600
const SIZE_INDEX = 0
const POSITION_INDEX = 1
const COLOR_INDEX = 2
var sun = Vector3(-0.446634, 0.893269, 0.050884).normalized()
onready var sunlight = $'SunLight'
var axis_of_rotation = Vector3(1,0.5,0).normalized()
onready var sun_tex = load("res://img/sun.png")

func _ready():
	textures.push_back(load("res://img/star_0.png"))
	textures.push_back(load("res://img/star_1.png"))
	textures.push_back(load("res://img/star_2.png"))
	if Game.star_field == null:
		print("created star field")
		create_star_field()

func _process(delta):
	update() #calls _draw()

func fix_saturation(brightness):
	if brightness < 0.15:
		return 0.15
	elif brightness > 0.85:
		return 0.85
	return brightness

func create_star_field():
	var field = []
	var r
	var g
	var b
	var a
	var size
	randomize()
	for i in range (1,STARTOTAL):
		size = 0
		if i % 5 == 0:
			size += 1
		if i % 50 == 0:
			size += 1
		
		if size == 0:
			r = randf() / 3
			g = randf() / 5
			b = randf()
			
		if size == 1:
			r = randf() / 2
			g = randf() / 3
			b = randf() * 1.5
			if b > 1:
				b = 1
		
		if size == 2:
			r = fix_saturation(randf())
			g = fix_saturation(randf())
			b = fix_saturation(randf())
		
		a = (randf()/2) + 0.5
		var color = Color(r,g,b,a)
		var position = Vector3(gaussian(0,1), gaussian(0,1), gaussian(0,1)).normalized()
		field.push_back([size, position, color])
	Game.star_field = field
	
	var dirCheck = Directory.new()
	if dirCheck.dir_exists('user://savedata/'):
		var star_field_file = File.new()
		star_field_file.open('user://savedata/star_field.save', File.WRITE)
		star_field_file.store_var(field)
		star_field_file.close()

func gaussian(mean, deviation):
	var x1 = null
	var x2 = null
	var w = null
	while true:
		x1 = rand_range(0, 2) - 1
		x2 = rand_range(0, 2) - 1
		w = x1*x1 + x2*x2
		if 0 < w && w < 1:
			break
	w = sqrt(-2 * log(w)/w)
	return (mean + deviation * x1 * w)

func _draw():
	var rot_amount = (Game.time_of_day / 1440.0) * 360
	var cam_pos = Game.cam.global_transform.origin
	var bounds = Rect2(-64, -64, Game.max_x + 128, Game.max_y + 128)

	var midnight_blue = Color('000011')
	var dawn = Color('204958')
	var day = Color('2ebbed')
	var evening = Color('127bcd')

	if Game.time_of_day > 1200.0 or Game.time_of_day < 300.0:
		draw_rect(bounds, midnight_blue, true)
	elif Game.time_of_day > 300.0 and Game.time_of_day < 500.0:
		var y = (Game.time_of_day - 300.0) / 200.0
		draw_rect(bounds, midnight_blue.linear_interpolate(dawn, y), true)
	elif Game.time_of_day > 500.0 and Game.time_of_day < 600.0:
		var y = (Game.time_of_day - 500.0) / 100.0
		draw_rect(bounds, dawn.linear_interpolate(day, y), true)
	elif Game.time_of_day > 600.0 and Game.time_of_day < 900.0:
		draw_rect(bounds, day, true)
	elif Game.time_of_day > 900.0 and Game.time_of_day < 960.0:
		var y = (Game.time_of_day - 900.0) / 60.0
		draw_rect(bounds, day.linear_interpolate(evening, y), true)
	elif Game.time_of_day > 960.0 and Game.time_of_day < 1020.0:
		var y = (Game.time_of_day - 960.0) / 60.0
		draw_rect(bounds, evening.linear_interpolate(Color('003f9e'), y), true)
	elif Game.time_of_day > 1020.0 and Game.time_of_day < 1080.0:
		var y = (Game.time_of_day - 1020.0) / 60.0
		draw_rect(bounds, Color('003f9e').linear_interpolate(Color('38255b'), y), true)
	elif Game.time_of_day > 1080.0 and Game.time_of_day < 1140.0:
		var y = (Game.time_of_day - 1080.0) / 60.0
		draw_rect(bounds, Color('38255b').linear_interpolate(Color('150f39'), y), true)
	elif Game.time_of_day > 1140.0 and Game.time_of_day < 1200.0:
		var y = (Game.time_of_day - 1140.0) / 60.0
		draw_rect(bounds, Color('150f39').linear_interpolate(midnight_blue, y), true)
		
	for star in Game.star_field:
		var world_point = cam_pos + star[POSITION_INDEX].rotated(axis_of_rotation, deg2rad(rot_amount) )
		if Game.cam.is_position_behind(world_point):
			var pos = Game.cam.unproject_position(world_point)
			pos.x = round(pos.x)
			pos.y = round(pos.y)
			if bounds.has_point(pos):
				var star_c = star[COLOR_INDEX]
				var color_sum = (star_c.r + star_c.g + star_c.b + star_c.a) / 4.0
				var star_opacity
				
				if Game.time_of_day < 720:
					star_opacity = clamp((Game.time_of_day - 300) / 120, 0.0, 1.0)
					if color_sum - star_opacity > 0.0:
						draw_texture (textures[star[SIZE_INDEX]], pos, star_c)
					elif color_sum + 0.25 - star_opacity > 0.0:
						draw_texture (textures[star[SIZE_INDEX]], pos, star_c * 0.65)
				
				elif Game.time_of_day > 1050:
					star_opacity = clamp((Game.time_of_day - 1050) / 120, 0.0, 1.0)
					if star_opacity > (1.0 - color_sum):
						draw_texture (textures[star[SIZE_INDEX]], pos, star_c)
					
	var sun_rot = sun.rotated(axis_of_rotation, deg2rad(rot_amount) )
	var world_point = cam_pos + sun_rot
	sunlight.look_at(sun_rot, Vector3.UP)
	if Game.cam.is_position_behind(world_point):
		var pos = Game.cam.unproject_position(world_point)
		if bounds.has_point(pos):
			draw_texture(sun_tex, pos, Color(1,1,1,1))
#			var tex_coords = PoolVector2Array()
#			var other_axis = sun_rot.cross(axis_of_rotation)
#			var v_0 = sun_rot.rotated(axis_of_rotation, deg2rad(-34.641) )
#			var v_1 = sun_rot.rotated(axis_of_rotation, deg2rad(17.321) )
#			v_1 = v_1.rotated(other_axis, deg2rad(-30))
#			var v_2 = sun_rot.rotated(axis_of_rotation, deg2rad(17.321) )
#			v_2 = v_2.rotated(other_axis, deg2rad(30))
#			tex_coords.push_back(Game.cam.unproject_position(v_0 + cam_pos))
#			tex_coords.push_back(Game.cam.unproject_position(v_1 + cam_pos))
#			tex_coords.push_back(Game.cam.unproject_position(v_2 + cam_pos))
#			var tex_color = PoolColorArray([Color(1,1,1,1), Color(1,1,1,1), Color(1,1,1,1)])
#			var uvs = PoolVector2Array([Vector2(0,-3.464), Vector2(-3,1.7321), Vector2(3,1.7321)])
#			draw_polygon(tex_coords, tex_color, uvs, sun_tex)
#			draw_line(tex_coords[0], tex_coords[1], Color(0,0,1))
#			draw_line(tex_coords[0], tex_coords[2], Color(0,0,1))
#			draw_line(tex_coords[1], tex_coords[2], Color(0,0,1))