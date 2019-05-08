extends CanvasLayer

onready var console = $"Console"
onready var topmsg = $"TopMessage"
onready var meters = $"main_ui_margin/meters"
onready var fadeout = $"FadeOut"
onready var LoadBar = $"LoadBar"
onready var SaveBar = $"SaveBar"
onready var ItemViewport = $"main_ui_margin/ItemHolder/ViewportContainer/ItemViewport"
onready var ItemCam = $"main_ui_margin/ItemHolder/ViewportContainer/ItemViewport/Camera"

var fps:bool = false setget show_fps
onready var fps_node = $'FPS'
onready var fps_timer = $'FPS/FPS_Update'

func fadeout():
	fadeout.fadeout()
func fadein():
	fadeout.fadein()

func show_fps(value):
	fps = value
	fps_node.visible = fps
	if fps:
		fps_timer.start()
	else:
		fps_timer.stop()
	
func _on_FPS_Update_timeout():
	fps_node.text = str(Engine.get_frames_per_second()) + " FPS"
	
func _ready():
	if (Game.player.has_strafe_helm):
		$"StrafeHelmOverlay".enable()

func health_update(health):
	meters.update_meter("health", health)

func update_topmsg(msg):
	topmsg.bbcode_text = "[center]" + msg + "[/center]"
	console.update_console(msg)
	topmsg.begin_fade()

func hide_progress():
	LoadBar.fadeout()
	SaveBar.fadeout()
func show_progress():
	LoadBar.margin_right = 100
	LoadBar.fadein()
	SaveBar.margin_right = 100
	SaveBar.fadein()

func update_progress(type, amount):
	if type == 'load':
		LoadBar.margin_right = 100 + ((amount / 100.0) * (Game.max_x - 200))
	if type == 'save':
		SaveBar.margin_right = 100 + ((amount / 6.0) * (Game.max_x - 200))

func obtain_item(node):
	ItemViewport.add_child(node)
	node.translation = Vector3(0,0,0)
func remove_current_item():
	Game.current_item = null
	ItemViewport.get_child(2).queue_free()

func _process(delta):
	if Input.is_action_just_pressed("ui_page_down"):
		console.open = true
	if Input.is_action_just_pressed("ui_page_up"):
		console.open = false
	if console.open and console.margin_top < 0:
		console.margin_top += 30
	elif console.open == false and console.margin_top > -Game.max_y:
		console.margin_top -= 30