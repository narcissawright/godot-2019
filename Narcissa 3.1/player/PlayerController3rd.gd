extends KinematicBody
const common = preload("res://code/common.gd") # common functions

signal collision(point)
signal respawn()

const display_state:bool = true

# Variables
var lockplayer:bool = true # prevent all input and physics in the player
var lockplayerinput:bool = true # prevent only input, keep physics.
var console_open:bool = false
var health = 100 setget set_health
var max_health = 100
var velocity = Vector3()
var has_jump = true
var on_ice = false
var on_floor = true
var on_grass = false
var wall_jump = 0 # frames remaining to initiate a wall jump. -1 means the wj was already used.
var wall_normal # stored wall normal for wall jump bounce
var initial_jump_velocity = Vector3() # it stores your initial jump velocity to be used for wall jump calcs
var interactable = null
var timescale = 1.0 # debug option for setting time

onready var body = $'Body'
onready var anim = $'Body/AnimationPlayer'
onready var anim_tree = $'Body/AnimationTree'
onready var tail = $"Tail"
onready var grass_sfx = $"grass_sfx"
onready var air_rush = $"air_rush"
onready var jump_sfx = $"jump_sfx"

# Physics
const PLUCK_RADIUS = 1.5
const MAXSPEED = 8.0
const ACCEL = 3.0
const DEACCEL = 7.0
const GRAVITY = 9.8 * 2 # ???
const MOUSESPEED = 0.005
const JUMP_HEIGHT = 8.0
const STRAFE_ANGLE = 0.9  #forward 100%, sideways 90%
const SPEED_STRAFE = 1.065  #diagonal boost
const BACK_SPEED = 0.5  #if back is held
const WALL_JUMP_FRAMES = 8 # amount of frames where a wall jump is possible after initial hit
const MIN_FALL_DAMAGE_SPEED = 20.0
const MAX_FALL_DAMAGE_SPEED = 33.0

# Items
var has_strafe_helm = false
const STRAFE_HELM_SPEEDUP = 1.12

func set_health(hp):
	health = hp
	if health > max_health:
		health = max_health
	Game.UI.health_update(health)
	if health <= 0:
		Game.UI.update_topmsg("You died.")
		Game.player.lockplayerinput = true
		Game.UI.fadeout()

func _physics_process(delta):
	
	# I'll just keep this here for now but.. I don't think this should be here.
	Game.time_of_day += delta * timescale
	if Game.time_of_day > 1440.0:
		Game.time_of_day -= 1440.0
	
	if lockplayer:
		return
	
	# fix this rounding error bs
	var y_small = abs(velocity.y)
	if y_small < 0.001 and y_small != 0:
		velocity.y = 0
	
	stick_to_ramps()
	
	var direction = Vector3(0,0,0)
	
	if !lockplayerinput:
		Game.data.playtime += delta
		if get_translation().y < -100:
			Game.respawn()
		direction = find_movement_direction()
		
#	if display_state:
#		if direction.length_squared() > 0.999:
#			Game.UI.update_topmsg("running")
#		elif direction.length_squared() > 0.0:
#			Game.UI.update_topmsg("walking")
#		else:
#			Game.UI.update_topmsg("idle")
	
	var new_velocity = velocity # copy velocity to a temp var
	#new_velocity.y = 0 # clear the vertical component from the temp var (unused for horizontal movement)
	var target = direction * MAXSPEED
	
	# every frame this moves 10% closer to the target velocity
	new_velocity = new_velocity.linear_interpolate(target, 0.1)
	
	if on_ice or !has_jump:
		# use old velocity
		new_velocity = velocity.linear_interpolate(new_velocity, delta * 1.5)
	
	# insert the x and z values from the temp var into the actual velocity
	velocity.x = new_velocity.x
	velocity.z = new_velocity.z
	var walk_length = Vector2(velocity.x, velocity.z).length()
	
	anim_tree['parameters/blend2/blend_amount'] = 0.0
	anim_tree['parameters/timescale/scale'] = 0.2 + (walk_length / 18.0)
	anim_tree['parameters/walkrun/blend_position'] = walk_length / 8.0
	if walk_length < 0.2:
		anim_tree['parameters/blend2/blend_amount'] = 1.0 - (walk_length * 5.0)
	
	if !Game.UI.console.open and !lockplayerinput:
		
		# JUMPING & WALL JUMPING:
		if Input.is_action_just_pressed("jump"):
			if has_jump:
				var old_y = velocity.y
				velocity.y = JUMP_HEIGHT
				has_jump = false
				if (wall_jump > 0):
					# perform wall jump
					jump_sfx.play()
					wall_jump = -1 # -1 means no more wall jump until on_floor resets it.
					if old_y > 0:
						old_y = 0
					velocity = find_movement_direction()*1.5 + (initial_jump_velocity.bounce(wall_normal) * Vector3(0.75, 1, 0.75)) + Vector3(0, old_y/3, 0)
					initial_jump_velocity = Vector3(0,0,0)
				else:
					initial_jump_velocity = velocity
			else:
				wall_jump = -1 # an early press will negate any possible wall jump
	
		# TARGET / CAM RESET
		if Input.is_action_just_pressed('ZL'):
			if common.deadzone(2,3) == Vector2(0,0):
				Game.cam.reset_cam()
		if not Input.is_action_pressed('ZL'):
			var looktowards = Vector3(-velocity.x, 0, -velocity.z)
			if looktowards.length_squared() > 0.0:
				#looktowards = looktowards.rotated(Vector3.UP, PI/2.0)
				looktowards += body.global_transform.origin
				if looktowards != body.global_transform.origin:
					body.look_at(looktowards, Vector3.UP)
		
		# INTERACT
		if Input.is_action_just_pressed('A'):
			if interactable != null:
				interactable.interact()
	
	# Decrement wall jump frames
	if wall_jump > 0:
		wall_jump -= 1
		if wall_jump == 0: # If time ran out, wall jump is no longer possible.
			wall_jump = -1
			has_jump = false
	
	var crash_vector = velocity
	
	# Move. (Velocity, UpDirection, StopOnSlope, MaxSlides
	velocity = move_and_slide(velocity, Vector3(0, 1, 0), true, 1) # this also sets is_on_floor(), is_on_wall(), is_on_ceiling()
	on_floor = is_on_floor()
	on_ice = is_on_ice()
	
	if health > 0:
		for i in range(get_slide_count()):
			var crash_speed = (crash_vector - velocity).length()
			if crash_speed > MIN_FALL_DAMAGE_SPEED:
				var damage = 100 * (crash_speed - MIN_FALL_DAMAGE_SPEED) / (MAX_FALL_DAMAGE_SPEED - MIN_FALL_DAMAGE_SPEED)
				set_health(health - damage)
				#Game.UI.update_topmsg("Big Fall cost " + str(round(damage)) + "% of health.")
			var grass_collision_speed = crash_speed + velocity.length()
			if health <= 0:
				emit_signal("collision", get_slide_collision(i).position, 9999)
			elif grass_collision_speed*delta > 0.05: # slow means don't affect environment.
				emit_signal("collision", get_slide_collision(i).position, grass_collision_speed) # emit collision info to environment
	
	if is_on_wall() and wall_jump == 0:
		for i in range(get_slide_count()):
			if abs(get_slide_collision(i).normal.y) < 0.2: # 0.2 is very vertical
				wall_jump = WALL_JUMP_FRAMES # set the timer
				has_jump = true 
			wall_normal = get_slide_collision(i).normal
	
	
	if on_floor:
		wall_jump = 0
	if on_floor or wall_jump > 0:
		has_jump = true
	else:
		if !tail.is_colliding():
			has_jump = false
			Game.UI.update_topmsg("in air")
			if initial_jump_velocity == Vector3(0,0,0) and wall_jump == 0:
				initial_jump_velocity = velocity + Vector3(0, JUMP_HEIGHT/2.0, 0)
	
	# SFX
	if is_on_floor() and is_on_grass() and velocity.length() > 3:
		grass_sfx.grass_walk(delta, velocity.length())
	
	if velocity.y < -5:
		if air_rush.playing == false:
			air_rush.play()
	elif air_rush.playing:
		air_rush.stop()
	
	# Add Gravity
	velocity.y -= GRAVITY * delta

func find_movement_direction():
	# Build the movement direction vector
	var pushdir:Vector2 = common.deadzone(0, 1)
	var camdir:Vector3 = Game.cam.get_global_transform().basis.z
	camdir.y = 0.0
	camdir = camdir.normalized()
	return (camdir * pushdir.y) + (camdir.rotated(Vector3.UP, PI/2) * pushdir.x)

func stick_to_ramps():
	if has_jump and !on_floor and wall_jump == 0:
		move_and_collide(Vector3(0, -1, 0))

func is_on_ice():
	for i in range(get_slide_count()):
		if (get_slide_collision(i).collider.get("name")) == "Ice":
			return true
	return false
	
func is_on_grass():
	for i in range(get_slide_count()):
		if (get_slide_collision(i).collider.get("name")) == "Grass":
			return true
	return false
		
func item_obtained(what):
	if what == "StrafeHelm":
		has_strafe_helm = true

func interactable_within_range(body):
	var item = body.get_node('..')
	if item.is_in_group('interactables'):
		interactable = item
		interactable.hover(true)
	else:
		print("i don't think this should happen.")
		# maybe I should remove "interactables" as a group
		# and just use the collision layer.

func interactable_left_range(body):
	var item = body.get_node('..')
	if item.is_in_group('interactables'):
		item.hover(false)
		interactable = null