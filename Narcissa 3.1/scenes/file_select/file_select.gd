extends Control
onready var select = $"select"
onready var NEW = $"NEW"
onready var LOAD = $"LOAD"
onready var sfx = $'sfx'
var moving = "up"
var allow_load = false

var grey = '[color=#808080]'
var white = '[color=#ffffff]'
var off = '[color=#202020]'
var ready = false

func _ready():
	connect("tree_exited", Game, "start_game")
	OS.move_window_to_foreground() # does this even work
	Game.scene = self
	Game.cam = $'Camera'
	if Game.playtime > 0.0:
		LOAD.bbcode_text = grey + 'LOAD - ' + Game.readable_playtime() + '[/color]'
		allow_load = true

func _input(event):
	if ready:
		if Input.is_action_just_pressed("ui_cancel"):
			get_tree().quit()
			
		if Input.is_action_just_pressed("ui_up"):
			if moving == "up":
				sfx.pitch_scale = 0.5
				sfx.volume_db = -20
				sfx.play()
			else:
				moving = "up"
				sfx.volume_db = -16
				sfx.pitch_scale = 1.1
				sfx.play()
				NEW.bbcode_text = white + 'NEW[/color]'
				LOAD.bbcode_text = grey + 'LOAD - ' + Game.readable_playtime() + '[/color]'
			
		if Input.is_action_just_pressed("ui_down"):
			if moving == "down" or allow_load == false:
				sfx.pitch_scale = 0.5
				sfx.volume_db = -20
				sfx.play()
			else:
				sfx.volume_db = -16
				sfx.pitch_scale = 1.0
				sfx.play()
				moving = "down"
				NEW.bbcode_text = grey + 'NEW[/color]'
				LOAD.bbcode_text = white + 'LOAD - ' + Game.readable_playtime() + '[/color]'
		
		if Input.is_action_just_pressed("ui_accept"):
			if moving == "up":
				Game.new_game()
			elif moving == "down":
				Game.load_game()
			call_deferred('free')
			set_process_input (false)
			set_process (false)
			Game.scene = null # without this, scene sometimes becomes a SpatialMaterial ... VERY WEIRD ...
	
func _process(delta):
	if moving == "up" and select.margin_top > 20:
		select.margin_top -= 4
	if moving == "down" and select.margin_top < 40:
		select.margin_top += 4
	ready = true