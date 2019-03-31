extends KinematicBody

signal collision(point)
signal respawn()
signal ui(button, state)

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

func _physics_process(delta):
	
	if lockplayer:
		return
	
	# fix this rounding error bs
	var y_small = abs(velocity.y)
	if y_small < 0.001 and y_small != 0:
		velocity.y = 0
	
	stick_to_ramps()
	
	var direction = Vector3(0,0,0)
	
	if !lockplayerinput:
		
		Game.playtime += delta
		
		if get_translation().y < -100:
			Game.respawn()
			
		if Game.UI.console.open == false and Input.is_action_just_pressed("restart"):
			Game.respawn()
		
		if Input.is_action_just_pressed("console_open"):
			Game.UI.console.open = true

		if Input.is_action_just_pressed("console_close"):
			Game.UI.console.open = false
		
		if Game.UI.console.open == false:
			direction = find_movement_direction()
			
		click_interactables()
			
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
	
	# JUMPING & WALL JUMPING:
	
	if !Game.UI.console.open and !lockplayerinput:
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
				health -= damage
				Game.UI.health_update(health)
				if health <= 0:
					Game.UI.update_topmsg("You died.")
					Game.player.lockplayerinput = true
					Game.UI.fadeout()
				else:
					Game.UI.update_topmsg("Big Fall cost " + str(round(damage)) + "% of health.")
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
	
	# Update UI Information
	emit_signal('ui', 'has_jump', has_jump)
	var display_speed = round(velocity.length() * 10.0) / 10.0
	if fmod(display_speed, 1.0) == 0.0:
		display_speed = str(display_speed) + ".0"
	else:
		display_speed = str(display_speed)
	#Game.UI.stats_line_3 = "Speed: " + display_speed

	# Add Gravity
	velocity.y -= GRAVITY * delta

func click_interactables():
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_from = Game.cam.project_ray_origin(mouse_pos)
	var ray_to = ray_from + Game.cam.project_ray_normal(mouse_pos) * PLUCK_RADIUS
	var space_state = get_world().direct_space_state
	var selection = space_state.intersect_ray(ray_from, ray_to, [], 2) # [] = exceptions, 2 = mask
	if selection.size() > 0:
		var item = selection.collider.get_node('..')
		if item.is_in_group('click_interactables'):
			if Input.is_action_just_pressed("left_click"):
				item.interact()
			else:
				item.hover()

func find_movement_direction():
	
	var strafe_boost = 1.0
	if has_strafe_helm:
		strafe_boost = STRAFE_HELM_SPEEDUP
	
	# Build the movement direction vector
	var direction = Vector3()
	var aim = get_global_transform().basis
	var forward_pressed = false
	var backward_pressed = false
	var left_pressed = false
	var right_pressed = false
	if Input.is_action_pressed("move_forward"):
		forward_pressed = true
	if Input.is_action_pressed("move_backward"):
		backward_pressed = true
	if Input.is_action_pressed("move_left"):
		direction -= aim.x * STRAFE_ANGLE
		left_pressed = true
	if Input.is_action_pressed("move_right"):
		direction += aim.x * STRAFE_ANGLE
		right_pressed = true
	if forward_pressed:
		direction -= aim.z
		if backward_pressed:
			direction = direction.normalized() * (BACK_SPEED * strafe_boost)
		else:
			if left_pressed != right_pressed: # if one or the other, but not both
				direction = direction.normalized() * (SPEED_STRAFE * strafe_boost)
	elif backward_pressed:
			direction += aim.z * STRAFE_ANGLE
			direction = direction.normalized() * (BACK_SPEED * strafe_boost)
	else:
		direction = direction.normalized() * (BACK_SPEED * strafe_boost)
	return direction

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
	
func _input(event):
	if lockplayer or lockplayerinput:
		return
	# we're checking for mouse movement here
	if event is InputEventMouseMotion:
		var camera_change = event.relative
		Game.cam.rotation.x = clamp(Game.cam.rotation.x - camera_change.y*MOUSESPEED, deg2rad(-85), deg2rad(85))
		rotation.y -= camera_change.x*MOUSESPEED
		
func item_obtained(what):
	if what == "StrafeHelm":
		has_strafe_helm = true