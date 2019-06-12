extends Node

# Can easily reference these in any script with prefix 'Game.'
onready var UI = preload("res://ui/UI.tscn")
onready var player = preload("res://player/Player3rd.tscn")

const FIRST_LVL = 'fofs'
const levels = {
	'grassy_knoll' : 'res://scenes/grassy_knoll/grassy_knoll.tscn',
	'big_fall' : 'res://scenes/big_fall/big_fall.tscn',
	'mesh_generator' : 'res://scenes/mesh_generator/meshgen.tscn',
	'castle' : 'res://scenes/new_area/castle.tscn',
	'fofs' : 'res://scenes/fofs/fofs.tscn'
	}

var joyID = 0
var scene # current scene
var cam # current camera
var decorator # current level decorator.

var max_x = 1920 # width
var max_y = 1080 # height.

var DRAW_CURRENT_AABB = false # debug option for drawn octree bounding boxes

var save_dir = null
#var playtime:float = 0.0 # total playtime
var current_level = null
var current_item = null
var star_field = null # 1 starfield per game
var time_of_day:float = 240.0

var loader = null # loads levels
var resource = null # level from load
var quitting = false

var data:Dictionary = {
	'id': '',
	'name': '',
	'playtime': 0.0
}

func make_dir(path):
	var dir = Directory.new()
	dir.make_dir(path)

func _enter_tree():
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	randomize() # randomize the RNG

func size_changed():
	max_x = get_viewport().size.x
	max_y = get_viewport().size.y

func _ready():
	get_tree().get_root().connect("size_changed", self, "size_changed")
	set_process (false) # process is used for resource loading
	UI = UI.instance() # instance the player and UI outside the scene tree
	player = player.instance()

func detect_joypads():
	var joypad_count = Input.get_connected_joypads().size()
	var joy_string:String = 'Found ' + str(joypad_count) + ' Joypad'
	if joypad_count != 1:
		joy_string += 's'
	joy_string += '.'
	for i in range (Input.get_connected_joypads().size()):
		joy_string += '\n'
		joy_string += 'Joypad ' + str(i+1) + ': ' + Input.get_joy_name(i)
		if Input.is_joy_known(i):
			joy_string += ' - mapped device.'
		else:
			joy_string += ' - unknown device.'
	return joy_string

func readable_playtime(passed_playtime):
	var secs = int(round(passed_playtime))
	var mins = int(floor(secs / 60))
	var hrs = int(floor(mins / 60))
	var time = str(hrs) + ":" + str(mins%60).pad_zeros(2) + ":" + str(secs%60).pad_zeros(2)
	return time

func delete_dir_contents(path):
	var dir = Directory.new()
	if dir.open(path) == OK:
		dir.list_dir_begin(true) # skip . and ..
		var file_name:String = dir.get_next()
		while file_name != '':
			if dir.current_is_dir():
				delete_dir_contents(path + file_name + "/")
			else:
				dir.remove(file_name)
			file_name = dir.get_next()
		dir.remove(path)
	else:
		print("An error occurred when trying to access the path.")
	
func start_game():
	save_dir = 'user://' + Game.data.id + '/'
	call_deferred("add_child", player) # add player to scene tree
	cam = player.find_node("Camera") # change to player cam
	call_deferred("add_child", UI) # add UI to scene tree
	call_deferred("load_level", FIRST_LVL) # load first level

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
		var f = File.new()
		f.open(Game.save_dir + 'data.save', File.WRITE)
		f.store_line(JSON.print(data))
		f.close()
		get_tree().quit()

func save_complete(): # called externally
	scene.call_deferred('free')
	if quitting:
		get_tree().quit()