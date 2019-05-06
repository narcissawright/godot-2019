extends Node

# Can easily reference these in any script with prefix 'Game.'
onready var UI = preload("res://ui/UI.tscn")
onready var player = preload("res://player/Player3rd.tscn")

const levels = {
	'grassy_knoll' : 'res://scenes/grassy_knoll/grassy_knoll.tscn',
	'big_fall' : 'res://scenes/big_fall/big_fall.tscn',
	'mesh_generator' : 'res://scenes/mesh_generator/meshgen.tscn'
	}

var joyID = 0
var scene # current scene
var cam # current camera
var decorator # current level decorator. also right now it handles saving...

var max_x = 1920 # width
var max_y = 1080 # height.

var DRAW_CURRENT_AABB = false # debug option for drawn octree bounding boxes

var playtime = 0.0 # total playtime
var current_level = null
var current_item = null
var star_field = null # 1 starfield per game
var time_of_day:float = 240.0

var loader = null # loads levels
var resource = null # level from load
var quitting = false

func _enter_tree():
	# I move the window out of the way of the output window in editor. lol
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
#	OS.set_window_position(Vector2(OS.window_position.x, OS.window_position.y / 2.5))
#	OS.window_size = Vector2(1280,720)
	randomize() # randomize the RNG
	
	# enter tree occurs very early so I can load up the relevant save data first:
	var file = File.new()
	if file.file_exists('user://savedata/star_field.save'):
		file.open('user://savedata/star_field.save', File.READ)
		star_field = file.get_var() # load starry bg from save file if exists.
		file.close()
		
	if file.file_exists('user://savedata/stats.save'):
		file.open('user://savedata/stats.save', File.READ)
		playtime = file.get_var()
		file.close()

func size_changed():
	max_x = get_viewport().size.x
	max_y = get_viewport().size.y
	#Game.UI.resize()

func _ready():
	get_tree().get_root().connect("size_changed", self, "size_changed")
	var joypad_count = Input.get_connected_joypads().size()
	print('Found ' + str(joypad_count) + ' joypad(s).')
	for i in range (Input.get_connected_joypads().size()):
		var print_str = 'Joypad ' + str(i) + ': ' + Input.get_joy_name(i)
		if Input.is_joy_known(i):
			print_str += ' - mapped device.'
		else:
			print_str += ' - unknown device.'
		print(print_str)
	set_process (false) # process is used for resource loading
	
	if OS.is_debug_build() == false: # fullscreen in release builds.
		OS.window_fullscreen = true  # can be toggled with F11
	
	UI = UI.instance() # instance the player and UI outside the scene tree
	player = player.instance()

func readable_playtime():
	var secs = int(round(Game.playtime))
	var mins = int(floor(secs / 60))
	var hrs = int(floor(mins / 60))
	var time = str(hrs) + ":" + str(mins%60).pad_zeros(2) + ":" + str(secs%60).pad_zeros(2)
	return time

func delete_dir_contents(path):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true) # skip . and ..
		var file_name = dir.get_next()
		while (file_name != ""):
			if dir.current_is_dir():
				delete_dir_contents(path + file_name + "/")
			else:
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.remove(path)
	else:
		print("An error occurred when trying to access the path.")

func new_game():
	var dir = Directory.new()
	if dir.dir_exists('user://savedata/'):
		delete_dir_contents('user://savedata/') # wipe old save directory
	dir.make_dir("user://savedata/") # make new save directory
	star_field = null # will generate new stars upon new starry area loaded
	playtime = 0.0
	#start_game()
	
func load_game():
	pass
	# I don't actually have to do anything specific here.
	# Just the /savedata/ directory existing is enough.
	#start_game()
	
func start_game():
	call_deferred("add_child", player) # add player to scene tree
	cam = player.find_node("Camera") # change to player cam
	call_deferred("add_child", UI) # add UI to scene tree
	call_deferred("load_level", 'big_fall') # load first level

func load_level(lvl_name):
	current_level = lvl_name
	loader = ResourceLoader.load_interactive(levels[lvl_name])
	resource = null # clear the resource
	if loader == null: # check for errors
		print("Problem loading " + levels[lvl_name])
		return
	set_process(true) # process is used for smooth loading

func _process(delta):
	if resource == null:
		var err = loader.poll()
		if err == ERR_FILE_EOF: # Finished loading.
			resource = loader.get_resource()
			Game.UI.update_progress('load', 100)
			loader = null
		elif err == OK:
			var progress = float(loader.get_stage()) / loader.get_stage_count()
			progress = round(progress * 100)
			Game.UI.update_progress('load', progress)
		else: # error during loading
			print("loading failed. " + str(err))
			loader = null
	elif is_instance_valid(scene) == false: # scene has been freed:
		scene = resource.instance() # set new scene from the resource
		Game.UI.hide_progress()
		Game.UI.update_topmsg(str(current_level).capitalize())
		add_child(scene)
		call_deferred("respawn") # set player at spawn point
		set_process(false)

func respawn():
	var spawnPoints = scene.get_node("Spawns").get_children()
	var spawnIndex = randi() % spawnPoints.size()
	var spawnPoint = spawnPoints[spawnIndex]
	var pos = spawnPoint.get_transform()
	player.transform = pos
	player.velocity = Vector3(0,-9.8,0)
	#cam.rotation = Vector3(0,0,0)

func _input(event):
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = not OS.window_fullscreen
		OS.window_size = Vector2(1280, 720)

func save_and_quit():
	Game.UI.fadeout()
	if decorator != null:
		decorator.save(current_level)
		quitting = true
	else:
		get_tree().quit()

func save_complete(): # called externally
	scene.call_deferred('free')
	if quitting:
		get_tree().quit()