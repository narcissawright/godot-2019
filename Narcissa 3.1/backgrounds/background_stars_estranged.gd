extends Control

var textures = []
const STARTOTAL = 600
const SIZE_INDEX = 0
const POSITION_INDEX = 1
const COLOR_INDEX = 2
var sun = Vector3(-0.446634, 0.893269, 0.050884).normalized()
onready var moonlight = $'MoonLight'
var axis_of_rotation = Vector3(1,0.5,0).normalized()

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
	var bounds = Rect2(-20, -20, Game.max_x + 20, Game.max_y + 20)
	
	# neg half pi to pos half pi
	#3am to 6am
	# 180 -> 360
	# 270 middle
	# 180 units total makes 1 PI

	var y = 0.5 * sin(deg2rad(Game.time_of_day - 270.0)) + 0.5
	var dark_sky = Color(0.0, 0.0, 0.07)
	var light_sky =  Color(0.05, 0.0, 0.3)
	
	
	if Game.time_of_day < 180.0:
		draw_rect(bounds, dark_sky, true)
	elif Game.time_of_day > 360.0:
		draw_rect(bounds, light_sky, true)
	else:
		draw_rect(bounds, dark_sky.linear_interpolate(light_sky, y), true)
		
	for star in Game.star_field:
		var world_point = cam_pos + star[POSITION_INDEX].rotated(axis_of_rotation, deg2rad(rot_amount) )
		if Game.cam.is_position_behind(world_point):
			var pos = Game.cam.unproject_position(world_point)
			pos.x = round(pos.x)
			pos.y = round(pos.y)
			if bounds.has_point(pos):
				draw_texture (textures[star[SIZE_INDEX]], pos, star[COLOR_INDEX])
	var moon_rot = sun.rotated(axis_of_rotation, deg2rad(rot_amount) )
	print (moon_rot)
	var world_point = cam_pos + moon_rot
	moonlight.look_at(moon_rot, Vector3.UP)
	if Game.cam.is_position_behind(world_point):
			var pos = Game.cam.unproject_position(world_point)
			pos.x = round(pos.x)
			pos.y = round(pos.y)
			if bounds.has_point(pos):
				draw_circle (pos, 7.0, Color(0.4,0.3,1))
				draw_circle (pos, 6.0, Color(1,1,1))