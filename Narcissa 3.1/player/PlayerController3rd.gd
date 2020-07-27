# Player Controller - 3rd person
extends KinematicBody
const common = preload("res://code/common.gd") # common functions

signal collision(point)
signal respawn()

var lockplayer:bool = true # prevent all input and physics in the player
var lockplayerinput:bool = true # prevent only input, keep physics.
var console_open:bool = false

# Health
var health = 100 setget set_health
var max_health = 100

# Physics
var velocity = Vector3()
const MAXSPEED = 8.0
const ACCEL = 3.0
const DEACCEL = 7.0
const GRAVITY = 9.8 * 2 # ???
const JUMP_HEIGHT = 8.0
var has_jump = true
var on_ice = false
var on_floor = true
var on_grass = false

# Wall Jump
var wall_jump = 0 # frames remaining to initiate a wall jump. -1 means the wj was already used.
var wall_normal # stored wall normal for wall jump bounce
var initial_jump_velocity = Vector3() # it stores your initial jump velocity to be used for wall jump calcs
const WALL_JUMP_FRAMES = 8 # amount of frames where a wall jump is possible after initial hit

# Fall Damage
const MIN_FALL_DAMAGE_SPEED = 20.0
const MAX_FALL_DAMAGE_SPEED = 33.0

# Interactables
const PLUCK_RADIUS = 1.5
var interactable = null #object in range to be interacted with...

# Debug
var timescale = 1.0
onready var debug_draw = $'debug_draw' # ImmediateGeometry node for drawing lines in 3d, etc.

# Body
onready var body = $'Body'
var hair_idx:int # hair index, for hair movement
var prior_bone_pos = Vector3() # for hair movement
onready var orb_pos = $'Body/Armature/Skeleton/Hands/OrbPosition'
onready var skele = $'Body/Armature/Skeleton'
onready var anim = $'Body/AnimationPlayer'
onready var anim_tree = $'Body/AnimationTree'
onready var tail = $"Tail" # raycast detects if ground is nearby

# Player Shaders
onready var toon_shader = load('res://materials/toonshader.tres')
onready var tights_shader = load('res://materials/tights.tres')

# Sound Effects
onready var grass_sfx = $"grass_sfx"
onready var air_rush = $"air_rush"
onready var jump_sfx = $"jump_sfx"

# Area Detection (unused)
const RENDER_SIT_COLLIDERS = false
var sit_collider_shape1 = preload('res://player/sit_collider_1.tres')
var sit_collider_shape2 = preload('res://player/sit_collider_2.tres')
onready var sit_collider_visual1 = $"Body/sit_collider_1"
onready var sit_collider_visual2 = $"Body/sit_collider_2"

func _ready():
	hair_idx = skele.find_bone('Hair')
	prior_bone_pos = get_hair_bone_pos()
	if RENDER_SIT_COLLIDERS:
		sit_collider_visual1.show()
		sit_collider_visual2.show()

func set_health(hp): # setter function
	health = hp
	if health > max_health:
		health = max_health
	Game.UI.health_update(health)
	if health <= 0:
		Game.UI.update_topmsg("You died.")
		Game.player.lockplayerinput = true
		Game.UI.fadeout()

func _process(t):
	player_opacity()
	
	Game.time_of_day += t * timescale
	if Game.time_of_day > 1440.0:
		Game.time_of_day -= 1440.0
		
	if lockplayer:
		return
		
	Game.data.playtime += t

func _physics_process(t):
	if lockplayer:
		return
	
	# pre-movement adjustments
	y_small() # set y velocity to 0 if very small
	stick_to_ramps()
	
	# respawn if low
	if get_translation().y < -100:
		Game.respawn()
	
	# find movement direction
	var direction = Vector3()
	if !lockplayerinput:
		direction = find_movement_direction()
	var target = direction * MAXSPEED
	
	# calculate velocity 
	var new_velocity = velocity
	new_velocity = new_velocity.linear_interpolate(target, 0.1) # every frame 10% closer
	if on_ice or !has_jump:
		new_velocity = velocity.linear_interpolate(new_velocity, t * 1.5) # allows very slight movement
	velocity.x = new_velocity.x
	velocity.z = new_velocity.z
	
	walk_animation()
	
	button_input(direction) # passing in the movement direction too...
	
	# Decrement wall jump frames
	if wall_jump > 0:
		wall_jump -= 1
		if wall_jump == 0: # If time ran out, wall jump is no longer possible.
			wall_jump = -1
			has_jump = false
	
	# store current velocity prior to movement
	var crash_vector = velocity
	var prior_pos = global_transform.origin
	
	# Move. (Velocity, UpDirection, StopOnSlope, MaxSlides
	velocity = move_and_slide(velocity, Vector3.UP, true) # this also sets is_on_floor(), is_on_wall(), is_on_ceiling()
	on_floor = is_on_floor()
	on_ice = is_on_surface("Ice")

	# Check fall damage
	if health > 0:
		for i in range(get_slide_count()):
			var crash_speed = (crash_vector - velocity).length()
			if crash_speed > MIN_FALL_DAMAGE_SPEED:
				var damage = 100 * (crash_speed - MIN_FALL_DAMAGE_SPEED) / (MAX_FALL_DAMAGE_SPEED - MIN_FALL_DAMAGE_SPEED)
				set_health(health - damage)
			var grass_collision_speed = crash_speed + velocity.length()
			if health <= 0:
				emit_signal("collision", get_slide_collision(i).position, 9999) #signal to decorator
			elif grass_collision_speed* t > 0.05: # slow means don't affect environment.
				emit_signal("collision", get_slide_collision(i).position, grass_collision_speed) # emit collision info to environment
	
	# If just hit wall, activate walljump frames
	if is_on_wall() and wall_jump == 0:
		for i in range(get_slide_count()):
			if abs(get_slide_collision(i).normal.y) < 0.2: # 0.2 is very vertical
				wall_jump = WALL_JUMP_FRAMES # set the timer
				has_jump = true 
			wall_normal = get_slide_collision(i).normal
	
	# some kind of variables mess
	if on_floor:
		wall_jump = 0
	if on_floor or wall_jump > 0:
		has_jump = true
	else:
		if !tail.is_colliding():
			has_jump = false
			#Game.UI.update_topmsg("in air")
			if initial_jump_velocity == Vector3(0,0,0) and wall_jump == 0:
				initial_jump_velocity = velocity + Vector3(0, JUMP_HEIGHT/2.0, 0)
	
	# SFX
	if is_on_floor() and is_on_surface("Grass") and velocity.length() > 3:
		grass_sfx.grass_walk(t, velocity.length())
	if velocity.y < -5:
		if air_rush.playing == false:
			air_rush.play()
	elif air_rush.playing:
		air_rush.stop()
	
	# Add Gravity
	velocity.y -= GRAVITY * t
	
	# hair physics
	var bone_pos = get_hair_bone_pos()
	hair_bounce(bone_pos, prior_bone_pos)
	prior_bone_pos = bone_pos

func forwards():
	return body.transform.basis.z.normalized()

func y_small():
	# fix this rounding error bs
	var y_small = abs(velocity.y)
	if y_small < 0.001 and y_small != 0:
		velocity.y = 0

func find_movement_direction() -> Vector3:
	var pushdir:Vector2 = common.deadzone(0, 1)
	var camdir:Vector3 = Game.cam.get_global_transform().basis.z
	camdir.y = 0.0
	camdir = camdir.normalized()
	return (camdir * pushdir.y) + (camdir.rotated(Vector3.UP, PI/2) * pushdir.x)

func button_input(dir):
	if !lockplayerinput:
		
		# RESET
		if Input.is_action_just_pressed("MINUS"):
			Game.respawn()
		
		# ORB
		if Game.orb.state == 'ready':
			if Input.is_action_pressed("Y"):
				Game.orb.change_state("charge")
		elif Game.orb.state == 'charge' and !Input.is_action_pressed("Y"):
			Game.orb.change_state('launch', forwards())
		
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
			
			# OoT style wall targeting / realignment
			var from = global_transform.origin + (Vector3(0,1,0))
			var to = global_transform.origin + lerp(forwards() * 0.75, dir * 0.75, 0.5) + (Vector3(0,1,0))
			var result = get_world().direct_space_state.intersect_ray(from, to, [], 1)
			if result.size() > 0:
				body.look_at(global_transform.origin + result.normal, Vector3.UP)
		
		# Body facing direction:
		elif not Input.is_action_pressed('ZL') and on_floor:
			
			#var looktowards = lerp(forwards(),dir,0.2).normalized()
			#var looktowards = dir
			var looktowards = Vector3(velocity.x, 0, velocity.z)
			
			looktowards = -looktowards  # look_at assumes -z is forward, so I must negate it
			if looktowards.length_squared() > 0.0:
				looktowards += body.global_transform.origin
				body.look_at(looktowards, Vector3.UP) # bug: this can sometimes already be the correct value.
		
		# INTERACT
		if Input.is_action_just_pressed('A'):
			if interactable != null:
				interactable.interact()

func walk_animation():
	var walk_length = Vector2(velocity.x, velocity.z).length()
	anim_tree['parameters/blend2/blend_amount'] = 0.0
	anim_tree['parameters/timescale/scale'] = 0.2 + (walk_length / 18.0)
	anim_tree['parameters/walkrun/blend_position'] = walk_length / 8.0
	if walk_length < 0.2:
		anim_tree['parameters/blend2/blend_amount'] = 1.0 - (walk_length * 5.0)
		anim_tree['parameters/timescale/scale'] = 0.2

func sit_colliders():
	var space_state = get_world().direct_space_state
	var shape = PhysicsShapeQueryParameters.new()
	shape.collide_with_areas = false
	shape.collision_mask = 1
	
	shape.set_shape(sit_collider_shape1)
	shape.transform = sit_collider_visual1.global_transform
	var result1 = space_state.get_rest_info(shape)
		
	shape.set_shape(sit_collider_shape2)
	shape.transform = sit_collider_visual2.global_transform
	var result2 = space_state.get_rest_info(shape)

	if result1.empty() and result2.empty(): # no collision
		if RENDER_SIT_COLLIDERS:
			sit_collider_visual1.get_surface_material(0).albedo_color = '#4c007aff'
	else: # collision
		if RENDER_SIT_COLLIDERS:
			sit_collider_visual1.get_surface_material(0).albedo_color = '#4cff1e00'

func get_hair_bone_pos():
	return [skele.get_bone_global_pose(hair_idx).origin, body.global_transform.origin]

func hair_bounce(new, old):
	var diff1 = new[0] - old[0]
	var diff2 = old[1] - new[1]
	diff2 = diff2.rotated(Vector3.UP, -body.rotation.y)
	diff1.y *= 1.4
	var total_difference = (diff1 + diff2 * 1.3)
	total_difference.x *= 1.6
	total_difference.y *= 0.9
	total_difference.z *= 1.6
	var hair_pos = skele.get_bone_custom_pose(hair_idx)
	var tf = Transform(Basis(), hair_pos.origin.linear_interpolate(total_difference, 0.5))
	var tf_ls = tf.origin.length_squared()
	if tf_ls > 0.2:
		tf.origin *= (0.21 / tf_ls)
	skele.set_bone_custom_pose(hair_idx, tf)

func player_opacity():
	var length_squared = (Game.cam.global_transform.origin - (global_transform.origin + Game.cam.player_height_offset)).length_squared()
	var opacity = clamp(length_squared - 0.1, 0.0, 1.0)
	toon_shader.set_shader_param("opacity", opacity)
	tights_shader.set_shader_param("opacity", opacity)

func stick_to_ramps():
	if has_jump and !on_floor and wall_jump == 0:
		move_and_collide(Vector3(0, -1, 0))

# Should be called AFTER move_and_slide:
func is_on_surface(surface_name):
	for i in range(get_slide_count()):
		if (get_slide_collision(i).collider.get("name")) == surface_name:
			return true
	return false

func interactable_within_range(body):
	var item = body.get_node('..')
	assert (item.is_in_group('interactables'))
	interactable = item
	interactable.hover(true)

func interactable_left_range(body):
	var item = body.get_node('..')
	assert (item.is_in_group('interactables'))
	item.hover(false)
	interactable = null

# keeping this here if I need to use it later, works as a template.
func debug_draw():
	debug_draw.clear()
	debug_draw.begin(Mesh.PRIMITIVE_LINES)
	debug_draw.add_vertex (Vector3(0,1,0))
	debug_draw.add_vertex (Vector3(0,1,0) + forwards())
	debug_draw.end()
	
