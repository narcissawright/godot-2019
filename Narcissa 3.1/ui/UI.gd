extends CanvasLayer
#UI
const UI_UNPRESSED = "#5d5658"
const UI_PRESSED = "#e1c2cb"
const HAS_JUMP_COLOR = "21a15b"
const NO_JUMP_COLOR = "601030"

onready var console = $"Console"
onready var topmsg = $"TopMessage"
onready var hp = $"main_ui_margin/meters/hp_container/hp_bar"
onready var loss = $"main_ui_margin/meters/hp_container/hp_loss"
onready var fadeout = $"FadeOut"
onready var LoadBar = $"LoadBar"
onready var SaveBar = $"SaveBar"
onready var ItemViewport = $"main_ui_margin/ItemHolder/ViewportContainer/ItemViewport"
onready var ItemCam = $"main_ui_margin/ItemHolder/ViewportContainer/ItemViewport/Camera"

var fps:bool = false setget show_fps
onready var fps_node = $'FPS'
onready var fps_timer = $'FPS/FPS_Update'

var ui_updates = 0
var subtract_ticks
var min_frames_dropped = 0

var stats_line_1 = null
var stats_line_2 = null
var stats_line_3 = null

var bar_length = 200

var fading_out = false
var fading_in = false

func fadeout():
	fading_out = true
	fading_in = false
func fadein():
	fading_in = true
	fading_out = false
	AudioServer.set_bus_volume_db(0, -50)

func show_fps(value):
	fps = value
	fps_node.visible = fps
	if fps:
		fps_timer.start()
	else:
		fps_timer.stop()
	
func _on_FPS_Update_timeout():
	fps_node.text = str(Engine.get_frames_per_second()) + " FPS"

func set_label_style(label):
	label.add_color_override ( "font_color", Color(0.9, 0.9, 1, 0.8) )
	label.add_color_override ( "font_color_shadow", Color(0.1, 0.1, 0.45, 1) )
	label.add_constant_override ("shadow_offset_x", 1)
	label.add_constant_override ("shadow_offset_y", 1)

func resize():
	$"main_ui_margin".rect_size = Vector2(Game.max_x - 10, Game.max_y - 10)
	$"FadeOut".rect_size = Vector2(Game.max_x, Game.max_y)

func _ready():
	resize()
	fadeout.show()
	set_label_style(fps_node) # this feels outdated
	Game.player.connect("ui", self, "_ui_update")
	if (Game.player.has_strafe_helm):
		$"StrafeHelmOverlay".enable()

func health_update(health):
	bar_length = round(health * 2)
	if hp.margin_right < 0:
		hp.margin_right = 0
	if bar_length < hp.margin_right:
		hp.margin_right = bar_length
	else:
		loss.margin_right = bar_length

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
	
	if fading_out:
		fadeout.color.a += 0.02
		AudioServer.set_bus_volume_db(0, AudioServer.get_bus_volume_db(0)-1)
		if fadeout.color.a >= 1:
			fading_out = false
			AudioServer.set_bus_volume_db(0, -50)
			if Game.player.health <= 0:
				Game.respawn()
				Game.player.health = 100
				Game.player.lockplayerinput = false
				fading_in = true
	elif fading_in:
		AudioServer.set_bus_volume_db(0, AudioServer.get_bus_volume_db(0)+1)
		if AudioServer.get_bus_volume_db(0) > 0:
			AudioServer.set_bus_volume_db(0, 0)
		fadeout.color.a -= 0.02
		if fadeout.color.a <= 0:
			fading_in = false
			AudioServer.set_bus_volume_db(0, 0)
	
	if hp.margin_right < bar_length:
		hp.margin_right += 1
		if hp.margin_right < bar_length:
			hp.margin_right += 1
	if loss.margin_right > bar_length:
		loss.margin_right -= 1
		if loss.margin_right > bar_length:
			loss.margin_right -= 1
	
	if console.open and console.margin_top < 0:
		console.margin_top += 30
	elif console.open == false and console.margin_top > -Game.max_y:
		console.margin_top -= 30