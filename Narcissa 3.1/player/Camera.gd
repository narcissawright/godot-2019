extends Camera
const common = preload("res://code/common.gd") # common functions
var player_height_offset = Vector3(0, 1.20, 0)
const move_speed = 0.04
var resetting = false
var cam_reset_frame = 0.0
const cam_reset_time = 8.0 #frames @ 60fps
onready var body = $'../Body'
var current_zoom_type:String = 'medium'
var current_zoom_value:float = 3.0
var cam_collider = preload('res://player/cam_collider.tres')
var shape

const zoom_levels:Dictionary = {
		"near": 1.6,
		"medium": 2.8,
		"far": 4.0
	}

func nlerp(start:Vector3, end:Vector3, percent:float) -> Vector3:
	return lerp(start,end,percent).normalized()

func _ready():
	shape = PhysicsShapeQueryParameters.new()
	shape.collide_with_areas = false
	shape.collision_mask = 1
	shape.set_shape(cam_collider)

func _process(delta):
	
	if Input.is_action_just_pressed('R3'):
		match current_zoom_type:
			"medium":
				current_zoom_type = 'near'
			"near":
				current_zoom_type = 'far'
			"far":
				current_zoom_type = 'medium'
	
	if current_zoom_value != zoom_levels[current_zoom_type]:
		current_zoom_value = lerp(current_zoom_value, zoom_levels[current_zoom_type], 0.33)
		if abs(current_zoom_value - zoom_levels[current_zoom_type]) < 0.05:
			current_zoom_value = zoom_levels[current_zoom_type]
	
	var pushdir:Vector2 = common.deadzone(2, 3)
	var target:Vector3 = Game.player.global_transform.origin + player_height_offset
	var varying:Vector3 = self.global_transform.origin
	
	if resetting:
		#var goal_pos = Vector3(1,0.25,0).rotated(Vector3.UP, body.rotation.y).normalized()
		var goal_pos = Vector3(0,0.25,-1).rotated(Vector3.UP, body.rotation.y).normalized()
		var difference = (varying-target).normalized()
		varying = nlerp(difference, goal_pos, 1.0 / (cam_reset_time - cam_reset_frame))
		cam_reset_frame += 1.0
		varying = (varying * current_zoom_value) + target
		try_position(varying, target)
		if cam_reset_frame >= cam_reset_time:
			resetting = false
			cam_reset_frame = 0
	
	elif pushdir.length_squared() > 0.0:
		varying = (varying - target).normalized()
		var cross:Vector3 = varying.cross(Vector3.UP).normalized()
		varying = varying.rotated(Vector3.UP, -pushdir.x * move_speed)
		if (pushdir.y > 0.0 and varying.y > 0.0) or ((pushdir.y < 0.0 and varying.y < 0.0)):
			pushdir.y *= 1.0 - abs(varying.y)
		varying = varying.rotated(cross, pushdir.y * move_speed)
		varying.y = clamp(varying.y, -0.85, 0.85)
		varying *= current_zoom_value
		varying += target
		try_position(varying, target)
	
	else:
		varying = (varying-target).normalized() * current_zoom_value + target
		try_position(varying, target)

func try_position(from_here, look_here):
	var space_state = get_world().direct_space_state # get the space.
	shape.transform = Transform(Basis(), look_here) # start at the player,
	var motion = (from_here - look_here) # move along this vector
	var result = space_state.cast_motion(shape, motion) # until a collision happens
	if result[0] > 0: # result[0] is how much to lerp
		from_here = look_here.linear_interpolate(from_here, result[0]) # now we have final position
		look_at_from_position(from_here, look_here, Vector3.UP) # look at player from final position

func reset_cam():
	if not resetting:
		resetting = true
