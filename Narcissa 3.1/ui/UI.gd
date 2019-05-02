extends CanvasLayer
#UI
const UI_UNPRESSED = "#5d5658"
const UI_PRESSED = "#e1c2cb"
const HAS_JUMP_COLOR = "21a15b"
const NO_JUMP_COLOR = "601030"

#onready var stats = $"Stats"
onready var console = $"Console"
onready var topmsg = $"TopMessage"
onready var hp = $"main_ui_margin/meters/hp_container/hp_bar"
onready var loss = $"main_ui_margin/meters/hp_container/hp_loss"
onready var fadeout = $"FadeOut"
onready var LoadBar = $"LoadBar"
onready var SaveBar = $"SaveBar"
onready var ItemViewport = $"main_ui_margin/ItemHolder/ViewportContainer/ItemViewport"
onready var ItemCam = $"main_ui_margin/ItemHolder/ViewportContainer/ItemViewport/Camera"

#onready var joyLdot = $"JoyL/JoyL_dot"
#onready var joyRdot = $"JoyR/JoyR_dot"

var fps:bool = false setget show_fps
onready var fps_node = $'FPS'
onready var fps_timer = $'FPS/FPS_Update'

onready var input_display = $'InputDisplay'

onready var ui_dict = { 
	"forward": $"InputDisplay/W_icon",
	"backward": $"InputDisplay/S_icon",
	"left": $"InputDisplay/A_icon",
	"right": $"InputDisplay/D_icon",
	"jump": $"InputDisplay/Space_icon",
	"has_jump": $"InputDisplay/Space_border",
	"clickdot": $"ClickDot"
}

#var up_pressed = false
#var down_pressed = false
#var left_pressed = false
#var right_pressed = false
#var jump_pressed = false

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

func _ready():
	resize()
	fadeout.show()
	set_label_style(fps_node) # this feels outdated
	Game.player.connect("ui", self, "_ui_update")
	ui_dict["forward"].modulate = UI_UNPRESSED
	ui_dict["backward"].modulate = UI_UNPRESSED
	ui_dict["left"].modulate = UI_UNPRESSED
	ui_dict["right"].modulate = UI_UNPRESSED
	ui_dict["jump"].modulate = UI_UNPRESSED
	ui_dict["has_jump"].modulate = NO_JUMP_COLOR
	#subtract_ticks = OS.get_system_time_secs ( ) #this stopped working or something
	if (Game.player.has_strafe_helm):
		$"StrafeHelmOverlay".enable()

func _ui_update(button, state):
	ui_updates += 1
	var ui_element = ui_dict[button]
	if button == "has_jump":
		if state == true:
			ui_element.modulate = HAS_JUMP_COLOR
		else:
			ui_element.modulate = NO_JUMP_COLOR

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
	
#	if (Engine.get_frames_drawn()) == 1:
#		subtract_ticks = OS.get_ticks_msec()
	
#	joyLdot.rect_position.x = round((Input.get_joy_axis(Game.joyID, 0) * 20) + 19)
#	joyLdot.rect_position.y = round((Input.get_joy_axis(Game.joyID, 1) * 20) + 19)
#	joyRdot.rect_position.x = round((Input.get_joy_axis(Game.joyID, 2) * 20) + 19)
#	joyRdot.rect_position.y = round((Input.get_joy_axis(Game.joyID, 3) * 20) + 19)
#	var inputstring = ''
#	if Input.is_joy_button_pressed(0, JOY_BUTTON_0):
#		inputstring += 'B '
#	if Input.is_joy_button_pressed(0, JOY_BUTTON_1):
#		inputstring += 'A '
#	if Input.is_joy_button_pressed(0, JOY_BUTTON_2):
#		inputstring += 'Y '
#	if Input.is_joy_button_pressed(0, JOY_BUTTON_3):
#		inputstring += 'X '
#	if Input.is_joy_button_pressed(0, JOY_DPAD_UP):
#		inputstring += 'D-up '
#	if Input.is_joy_button_pressed(0, JOY_DPAD_DOWN):
#		inputstring += 'D-down '
#	if Input.is_joy_button_pressed(0, JOY_DPAD_LEFT):
#		inputstring += 'D-left '
#	if Input.is_joy_button_pressed(0, JOY_DPAD_RIGHT):
#		inputstring += 'D-right '
#	if Input.is_joy_button_pressed(0, JOY_L):
#		inputstring += 'L '
#	if Input.is_joy_button_pressed(0, JOY_L2):
#		inputstring += 'ZL '
#	if Input.is_joy_button_pressed(0, JOY_L3):
#		inputstring += 'L3 '
#	if Input.is_joy_button_pressed(0, JOY_R):
#		inputstring += 'R '
#	if Input.is_joy_button_pressed(0, JOY_R2):
#		inputstring += 'ZR '
#	if Input.is_joy_button_pressed(0, JOY_R3):
#		inputstring += 'R3 '
#	if Input.is_joy_button_pressed(0, JOY_SELECT):
#		inputstring += '- '
#	if Input.is_joy_button_pressed(0, JOY_START):
#		inputstring += '+ '
		
		
		
	#print (inputstring)

func _input(event):
	if event.is_action_pressed("move_forward"):
		ui_dict["forward"].modulate = UI_PRESSED
		#up_pressed = true
	else:
		ui_dict["forward"].modulate = UI_UNPRESSED
		#up_pressed = false
	if event.is_action_pressed("move_backward"):
		ui_dict["backward"].modulate = UI_PRESSED
		#down_pressed = true
	else:
		ui_dict["backward"].modulate = UI_UNPRESSED
		#down_pressed = false
	if event.is_action_pressed("move_left"):
		ui_dict["left"].modulate = UI_PRESSED
		#left_pressed = true
	else:
		ui_dict["left"].modulate = UI_UNPRESSED
		#left_pressed = false
	if event.is_action_pressed("move_right"):
		ui_dict["right"].modulate = UI_PRESSED
		#right_pressed = true
	else:
		ui_dict["right"].modulate = UI_UNPRESSED
		#right_pressed = false
	if event.is_action_pressed("jump"):
		ui_dict["jump"].modulate = UI_PRESSED
		#jump_pressed = true
	else:
		ui_dict["jump"].modulate = UI_UNPRESSED
		#jump_pressed = false
		
	if event.is_action_pressed("left_click"):
		ui_dict["clickdot"].color = Color(1,1,1,1)
	else:
		ui_dict["clickdot"].color = Color(1,1,1,0.5)

#func stats_update():
#	var ticks = OS.get_ticks_msec() - subtract_ticks
#	ticks = round((float(ticks) / 1000 * 60))
#	var frames_dropped = ticks - Engine.get_frames_drawn()
#	if frames_dropped < min_frames_dropped:
#		frames_dropped = min_frames_dropped
#	else:
#		min_frames_dropped = frames_dropped
#	var minutes = int(Game.time_of_day) % 60
#	var hours = str((int(Game.time_of_day) - minutes) / 60)
#	minutes = str(minutes).pad_zeros(2)
#	hours = str(hours).pad_zeros(2)
#	stats.text += "\nTime of Day: " + hours + ":" + minutes
	
#	stats.text = "the quick brown fox jumps over the lazy dog\n"
#	stats.text += "THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG\n"
#	stats.text += "0123456789 ~!@#$%^&*()_-+=:;.,<>?/\\|~`'\n"

#	if stats_line_2 != null:
#		stats.text += '\n' + str(stats_line_2)
#	if stats_line_3 != null:
#		stats.text += '\n' + str(stats_line_3)
#	if OS.is_debug_build() == true:
#		var static_mem = str(round((Performance.get_monitor(Performance.MEMORY_STATIC)/1024))) + "kb"
#		var static_max = str(round((Performance.get_monitor(Performance.MEMORY_STATIC_MAX)/1024))) + "kb"
#		var dynamic_mem = str(round((Performance.get_monitor(Performance.MEMORY_DYNAMIC)/1024))) + "kb"
#		var dynamic_max = str(round((Performance.get_monitor(Performance.MEMORY_DYNAMIC_MAX)/1024))) + "kb"
#
#		stats.text += "\nStaticMem: " + static_mem + "/" + static_max
#		stats.text += "\nDynamicMem: " + dynamic_mem + "/" + dynamic_max
#stats.text += "RENDER_DRAW_CALLS_IN_FRAME: " + (str(Performance.get_monitor(Performance.RENDER_DRAW_CALLS_IN_FRAME))) + "\n"
#stats.text += "RENDER_SURFACE_CHANGES_IN_FRAME: " + (str(Performance.get_monitor(Performance.RENDER_SURFACE_CHANGES_IN_FRAME))) + "\n"
