extends Spatial
const common = preload("res://code/common.gd") # common functions

# MeshInstance for main level
onready var level = self

# Edge Lines Material
var edge_lines = load("res://materials/edge_lines.tres")

# Threads
var flora_thread = Thread.new() # creating flora / grass damage calc
var save_thread = Thread.new() # save game

# surface indices for level.mesh
var grass_index
var ice_index
var wall_index

# generation progress of flora
var world_generation_stage = 0
var grass_generation_percent = 0
var grass_generation_prior_percent = 0
var generation_time
var label_fade_timer # timer resets the grass collision flag
signal decoration_complete

# grass damage wait time
var grass_collision_check = false # flag if grass collision calc is permissable
var grass_collision_timer # timer resets the grass collision flag
const GRASS_COLLISION_WAIT_TIME = 0.25 # minimum time between grass collisions
const GRASS_HURT_DIST = 0.3 # radius in which grass is hurt by collision

# Flora Octree
var FloraOctree = {} # will hold AABBs to segment the level into cubes, for fast spacial searching
var LEAF_MAX_SIZE = (DOTS_THICKNESS + TALL_THICKNESS) / 3 # Octree max compartment size.
var current_aabb_node # immediategeometry for aabb debug

# grass nodes / resources / data
var grass_shader = load("res://materials/grass_shader.tres")
var grass_dots # MeshInstance holder
var tall_grass # MeshInstance holder 

var grass_list = [] # keeping track of grass properties
var grass_mesh_arrays = [] # the ArrayMesh for the grass dots
var tg_mesh_arrays = [] # ArrayMesh for tall grass

# grass constants
const DOTS_THICKNESS = 100 # how many single vertices per unit of area
const TALL_THICKNESS = 50 # how many pairs of vertices per unit of area
const GRASS_COLORS = [Color(0, 0.5, 0.15), Color(0.15, 0.35, 0.5), Color(0.35, 0.3, 0), Color(0, 0.1, 0)]
const TALL_GRASS_COLORS = [Color(0, 0.45, 0.125), Color(0, 0.35, 0.05), Color(0.05, 0.4, 0.05), Color(0, 0.3, 0)]
const DESTROYED_GRASS_COLOR = Color(0.175,0.075,0.05,1)
const BLOODY_GRASS_COLOR = Color(0.3, 0, 0, 1)
const GRASS_RAISE = 0.01 # distance off ground for the dots
const TALL_GRASS_MIN_HEIGHT = 0.005 # minimum height of tall grass
const TALL_GRASS_GROWTH = 0.09 # min height + growth = max height.
const TALL_GRASS_BEND = 0.005 # distance the top vertex of tall grass can vary horizontally in the x and z axes

# flowers
var flower_container = Spatial.new() # node container
var narcissa_flower = load("res://level_objects/narcissa_flower/narcissa_flower.tscn") # model
const FLOWER_DENSITY = 0.2 # per thousand grass
const FLOWER_SINK_HEIGHT = 0.07 # how far the stem of the flower can sink into the floor

func _enter_tree():
	# enter tree runs before child nodes exist, ready runs after all child readies
	Game.decorator = self

func _ready():
	if get_parent().name == 'Mesh_Generator':
		# if we are using a Mesh Generator, wait for it to call the decorator.
		set_process(false)
		return
	Game.UI.fadein()
	call_deferred("begin_generation")

func begin_generation():
	generation_time = OS.get_ticks_msec() # timestamp the beginning of the generation
	create_octree_root_cube() # for finding relevant grass quickly
	Game.player.connect("collision", self, "grass_collision") # signal connect from Player
	for i in range (0, level.mesh.get_surface_count()): # loop over the surfaces
		if level.mesh.surface_get_name(i) == "Grass": # name from Blender, it's the Surface name.
			grass_index = i                           # they are used as key words to determine if
		elif level.mesh.surface_get_name(i) == "Ice": # grass or ice needs to be created
			ice_index = i
		elif level.mesh.surface_get_name(i) == "Wall":
			var wall_material = load("res://materials/wall_mat.tres")
			level.set_surface_material(i, wall_material)
	
	if ice_index != null:
		create_ice_fx(ice_index) # create ice sparkles
		
	create_level_collision() # separate collider for each surface.
	
	for node in get_tree().get_nodes_in_group("has_edge_lines"):
		generate_edge_lines(node) # give edgelines to everything that needs it
	
	if grass_index != null:
		# as of now I am creating two meshes for the grass, one is a PRIMITIVE_POINTS mesh
		# the other is a PRIMITIVE_LINES mesh, 2 vertices per tall grass. looks better than tris
		
		var grass_mat = (load("res://materials/grass_mat.tres"))
		level.set_surface_material(grass_index, grass_mat)
		
		grass_dots = MeshInstance.new()
		tall_grass = MeshInstance.new()
		grass_dots.name = "GrassDots"
		tall_grass.name = "TallGrass"
		grass_dots.material_override = grass_shader
		tall_grass.material_override = grass_shader
		
		if save_check():
			flora_thread.start(self, "create_flora", grass_index) # create grass, flowers. segment grass into Octree.
	else:
		save_check()
		finish()

func save_check():
	var d = Directory.new()
	var level_dir = 'user://savedata/' + str(Game.current_level) + '/'
	if d.dir_exists(level_dir):
		load_save_data()
		return false
	else:
		d.make_dir(level_dir)
		return true

func create_ice_fx(ice_index):
	var ice_sparkles = CanvasLayer.new()
	ice_sparkles.layer = 3
	ice_sparkles.set_script(load("res://fx/ice_sparkles.gd"))
	ice_sparkles.name = "IceSparkles"
	ice_sparkles.verts = level.mesh.surface_get_arrays(ice_index)[0]
	ice_sparkles.trios = level.mesh.surface_get_arrays(ice_index)[8]
	add_child(ice_sparkles)

func create_level_collision():
	# Separating each surface to a separate collider
	# Helps with SFX.
	var surface_count = level.mesh.get_surface_count()
	for i in range (surface_count):
		var meshdupe = level.mesh.duplicate()
		for j in range (surface_count-1, -1, -1): # reverse order
			if j != i:
				meshdupe.surface_remove(j)
		var surface_name = meshdupe.surface_get_name(0)
		var meshdupe_instance = MeshInstance.new()
		meshdupe_instance.mesh = meshdupe
		meshdupe_instance.create_trimesh_collision() # Create Level Collision
		var static_body = meshdupe_instance.get_child(0) # get StaticBody & CollisionShape
		static_body.name = surface_name
		static_body.get_child(0).name = surface_name + "_collision"
		meshdupe_instance.remove_child(static_body)
		level.add_child(static_body)

func generate_edge_lines(meshinstance):
	
	var mesh = meshinstance.mesh
	
	# EDGE LINES GENERATION:
	var immediate_geometry = ImmediateGeometry.new()
	var lines = []
	var verts = mesh.get_faces() # returns triplets of vertices that make triangles
	var line_tri_map = {}
	for i in range(0, verts.size(), 3): # for every 3 vertices:
		var l1 = [verts[i], verts[i+1]]   # line1 = v1 + v2
		var l2 = [verts[i+1], verts[i+2]] # line2 = v2 + v3
		var l3 = [verts[i+2], verts[i]]   # line3 = v3 + v1
		l1.sort() # sort the vertices in the line array to be in 'natural order'
		l2.sort() # sorting is done to make finding matching lines easier.
		l3.sort() # the line value is used as the dictionary key.
		var tri = [verts[i], verts[i+1], verts[i+2]] # get the triangle
		upd_dict(line_tri_map, l1, tri) # update dictionary called "line_tri_map"
		upd_dict(line_tri_map, l2, tri) # the line becomes a key
		upd_dict(line_tri_map, l3, tri) # the triangle becomes the value
	
	# Get the array of lines with no duplicates.
	lines = line_tri_map.keys()
	for i in range(0, lines.size()):
		var tris = line_tri_map[lines[i]]
		if tris.size() > 1:
			var normal1 = common.get_normal(tris[0][0], tris[0][1], tris[0][2])
			var normal2 = common.get_normal(tris[1][0], tris[1][1], tris[1][2])
			#var average = ((normal1 + normal2) / 2).normalized()
			var difference = normal1.dot(normal2) # -1 is 180 degrees, 1 is 0 degrees
			var opacity = (-difference+1) / 2
			lines[i].push_back(opacity)
		else:
			lines[i].push_back(0) # hide the line if no connecting tri.
	immediate_geometry.material_override = edge_lines
	immediate_geometry.begin(Mesh.PRIMITIVE_LINES, null)
	for i in range (0,lines.size()):
		var opacity = lines[i][2]
		if opacity > 0.01:
			#if opacity < 0.15:
			#	opacity = 0.15
			if opacity > 0.85: # no dark black lines
				opacity = 0.85
			immediate_geometry.set_color(Color(0,0,0,opacity))
			immediate_geometry.add_vertex(lines[i][0])
			immediate_geometry.add_vertex(lines[i][1])
	immediate_geometry.end()
	immediate_geometry.name = "EdgeLines"
	meshinstance.add_child(immediate_geometry)
	
	#return edge_lines

# Update a dictionary of lines.
func upd_dict(dict, k, v):
	if dict.has(k):
		dict[k].append(v)
	else:
		dict[k] = [v]

func create_flora(grass_index):
	# GRASS GENERATION:
	var verts = level.mesh.surface_get_arrays(grass_index)[0] #Vertices. no duplicates.
	var trios = level.mesh.surface_get_arrays(grass_index)[8] #gives indices of Verts that form Triangles.
	
	var g_vertices = PoolVector3Array() # dot positions
	var g_normals = PoolVector3Array() # vertex normals
	var g_colors = PoolColorArray() # dot colors
	var g_indices = PoolIntArray()
	
	var tg_vertices = PoolVector3Array()
	var tg_normals = PoolVector3Array() # vertex normals
	var tg_colors = PoolColorArray()
	var tg_indices = PoolIntArray()
	
	for i in range (0, trios.size(), 3): # for each triangle
		var normal = common.get_normal(verts[trios[i]], verts[trios[i+1]], verts[trios[i+2]])
		normal = -normal
		if normal.y == 0:
			continue # vertical grass, do not spawn.
		grass_generation_percent = float(i) / (float(trios.size())) * 100
		var area = common.tri_area(verts[trios[i]], verts[trios[i+1]], verts[trios[i+2]]) # find area of triangle
		
		# Grass Dots:
		for j in range(floor(area*DOTS_THICKNESS)): 
			var color = GRASS_COLORS[randi() % GRASS_COLORS.size()]
			g_colors.push_back(color)
			var dot_pos = common.sample_tri(verts[trios[i]], verts[trios[i+1]], verts[trios[i+2]])
			dot_pos += Vector3(0, GRASS_RAISE, 0)
			var index = g_vertices.size()
			g_vertices.push_back(dot_pos)
			g_normals.push_back(normal)
			g_indices.push_back(index)
			grass_list.push_back({ "pos": dot_pos, "health": 100, "color": color, "type": "dot", "arraymeshindex": index })
			add_to_tree(FloraOctree, grass_list.size()-1)
			
		# Tall Grass:
		for j in range(floor(area*TALL_THICKNESS)):
			var color = TALL_GRASS_COLORS[randi() % TALL_GRASS_COLORS.size()]
			var v1 = common.sample_tri(verts[trios[i]], verts[trios[i+1]], verts[trios[i+2]])
			var grass_height = TALL_GRASS_MIN_HEIGHT + (randf() * TALL_GRASS_GROWTH)
			var v2 = v1 + Vector3(randf() * TALL_GRASS_BEND, grass_height, randf() * TALL_GRASS_BEND)
			
			var index = tg_vertices.size()
			
			tg_vertices.push_back(v1)
			tg_normals.push_back(normal)
			tg_colors.push_back(color)
			tg_indices.push_back(index)
			
			tg_vertices.push_back(v2)
			tg_normals.push_back(normal)
			tg_colors.push_back(color)
			tg_indices.push_back(index+1)
			
			grass_list.push_back({ "pos": v1, "health": 100, "color": color, "type": "tall", "arraymeshindex": index})
			add_to_tree(FloraOctree, grass_list.size()-1)
	
	# Spawn Flowers:
	flower_container.name = "Flowers"
	var flower_count = FLOWER_DENSITY * (grass_list.size() / 1000)
	for i in range (flower_count):
		var flower = narcissa_flower.instance()
		transform_flower(flower)
		flower.name = "N_Flower" + str(i+1)
		flower_container.add_child(flower) # each flower is a separate meshinstance
		flower.connect("plucked", self, "flower_plucked")
	
	grass_mesh_arrays.resize(ArrayMesh.ARRAY_MAX) # ArrayMesh must be this size
	grass_mesh_arrays[ArrayMesh.ARRAY_VERTEX] = g_vertices
	grass_mesh_arrays[ArrayMesh.ARRAY_NORMAL] = g_normals
	grass_mesh_arrays[ArrayMesh.ARRAY_COLOR] = g_colors
	grass_mesh_arrays[ArrayMesh.ARRAY_INDEX] = g_indices

	tg_mesh_arrays.resize(ArrayMesh.ARRAY_MAX)
	tg_mesh_arrays[ArrayMesh.ARRAY_VERTEX] = tg_vertices
	tg_mesh_arrays[ArrayMesh.ARRAY_NORMAL] = tg_normals
	tg_mesh_arrays[ArrayMesh.ARRAY_COLOR] = tg_colors
	tg_mesh_arrays[ArrayMesh.ARRAY_INDEX] = tg_indices

	print("Total Grass: " + str(grass_list.size()) + " - Total Flowers: " + str(round(flower_count)))
	flora_thread.call_deferred("wait_to_finish")

func transform_flower(flower):
	# gives a flower a random position, rotation, and size.
	flower.translation = grass_list[randi() % grass_list.size()].pos
	flower.rotation = Vector3(0, 0, 0)
	flower.rotate(Vector3(0, 1, 0), (randf() * 2.5) + 2 ) # randf() * PI * 2 is 360 rotation. I wanted it smaller.
	var sinkamount = randf() * FLOWER_SINK_HEIGHT
	flower.translation.y -= sinkamount
	var fscale = 1 - (sinkamount * 4)
	flower.scale = Vector3(fscale, fscale, fscale)

func grass_generation_complete():
	
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, grass_mesh_arrays) # create the mesh
	grass_dots.mesh = arr_mesh # apply the mesh
	
	arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, tg_mesh_arrays) # create the mesh
	tall_grass.mesh = arr_mesh # apply the mesh
	
	call_deferred("add_child", grass_dots)
	call_deferred("add_child", tall_grass)
	
	generation_time = OS.get_ticks_msec() - generation_time
	Game.UI.update_topmsg("Generation Complete (" + str(generation_time) + "ms)")
	
	finish()

func load_save_data():
	print("loading save data: " + str(Game.current_level))
	
	var file_check = File.new()
	if file_check.file_exists(Game.save_dir + str(Game.current_level) + '/valid.save'):
		file_check.open(Game.save_dir + str(Game.current_level) + '/valid.save', File.READ)
		var valid = file_check.get_line()
		if valid != 'true':
			print("Invalid Save Data")
			flora_thread.start(self, "create_flora", grass_index)
			return
	else:
		print("Invalid Save Data")
		flora_thread.start(self, "create_flora", grass_index)
		return
	
	if file_check.file_exists(Game.save_dir + str(Game.current_level) + '/flowers.save'):
		var file = File.new()
		file.open(Game.save_dir + str(Game.current_level) + '/flowers.save', File.READ)
		while true:
			var flower = narcissa_flower.instance()
			flower.global_transform = file.get_var() # gets variant and moves pos in file forward.
			flower_container.add_child(flower)
			flower.connect("plucked", self, "flower_plucked")
			if file.get_position() >= file.get_len():
				break
		file.close()
	
	if file_check.file_exists(Game.save_dir + str(Game.current_level) + '/tall_grass.mesh'):
		var arr_mesh = ResourceLoader.load(Game.save_dir + str(Game.current_level) + '/tall_grass.mesh')
		tall_grass.mesh = arr_mesh
		call_deferred("add_child", tall_grass)
		tg_mesh_arrays = tall_grass.mesh.surface_get_arrays(0)
	
	if file_check.file_exists(Game.save_dir + str(Game.current_level) + '/grass_dots.mesh'):
		var arr_mesh = ResourceLoader.load(Game.save_dir + str(Game.current_level) + '/grass_dots.mesh')
		grass_dots.mesh = arr_mesh
		call_deferred("add_child", grass_dots)
		grass_mesh_arrays = grass_dots.mesh.surface_get_arrays(0)
	
	if file_check.file_exists(Game.save_dir + str(Game.current_level) + '/flora_octree.save'):
		var file = File.new()
		file.open(Game.save_dir + str(Game.current_level) + '/flora_octree.save', File.READ)
		var text = file.get_var()
		FloraOctree = text
		file.close()
	
	if file_check.file_exists(Game.save_dir + str(Game.current_level) + '/grass_list.save'):
		var file = File.new()
		file.open(Game.save_dir + str(Game.current_level) + '/grass_list.save', File.READ)
		var text = file.get_var()
		grass_list = text
		file.close()
	
	call_deferred('finish')

func finish():
	current_aabb_node = ImmediateGeometry.new()
	self.add_child(current_aabb_node) # add an ImmediateGeometry node for debug AABB visualizer
	
	if grass_index != null:
		if flower_container.get_child_count() > 0:
			self.add_child(flower_container)
	
		# grass collisions only happen every so often.
		grass_collision_timer = Timer.new()
		add_child(grass_collision_timer)
		grass_collision_timer.connect("timeout", self, "enable_grass_collision_check")
		grass_collision_timer.set_wait_time(GRASS_COLLISION_WAIT_TIME)
		grass_collision_timer.set_one_shot(false) # Make sure it loops
		grass_collision_timer.start()
		
		world_generation_stage = 2
	else:
		world_generation_stage = 3

	Game.player.lockplayer = false
	Game.player.lockplayerinput = false
	emit_signal('decoration_complete')

func enable_grass_collision_check():
	grass_collision_check = true

func flower_plucked(index): # via signal
	var flower = flower_container.get_child(index)
	transform_flower(flower)

# Draw Axis-Aligned Bounding Box (debug function)
func draw_aabb(aabb):
	current_aabb_node.name = "AABB_Lines"
	current_aabb_node.material_override = load("res://materials/edge_lines.tres")
	current_aabb_node.begin(Mesh.PRIMITIVE_LINES, null) # begin ImmediateGeometry creation
	current_aabb_node.set_color(Color(0.6, 0.4, 1, 1))
	# 12 lines create a cube wireframe.
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,0,0)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,0,0)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,0,0)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,1,0)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,0,0)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,0,1)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,0,0)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,1,0)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,1,0)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,1,0)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,1,0)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,1,1)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,0,0)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,0,1)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,0,1)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,0,1)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,0,1)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,1,1)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(0,1,1)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,1,1)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,1,0)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,1,1)))
	
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,0,1)))
	current_aabb_node.add_vertex(aabb.position + (aabb.size * Vector3(1,1,1)))
	
	current_aabb_node.end()

func create_octree_root_cube(): # big box covers entire level. the root of the octree.
	var aabb = level.get_aabb()
	var long = aabb.get_longest_axis_size()
	aabb = AABB(aabb.position, Vector3(long,long,long) ).grow(1) # grow is for padding
	
	FloraOctree = {
		"box" : aabb,   # axis-aligned bounding box
		"objects" : [], # list of Vector3s
		"children" : [] # list of child Octrees
	}

# Add the index of a piece of grass to the Octree
#func add_to_tree(layer, index):
#    if layer.children.empty(): # only nodes with no children may hold these indices
#        layer.objects.push_back(index)
#        compartmentalize(layer)
#    else:
#        var grass_pos = grass_list[index].pos
#        for child in layer.children:
#            if child.box.has_point(grass_pos):
#                add_to_tree(child, index)

# unverified that this actually works correctly?? is fast tho
func add_to_tree(root, index):
	var node = root
	var grass_pos = grass_list[index].pos
	while not node.children.empty():
		for child in node.children:
			if child.box.has_point(grass_pos):
				node = child
				break
	node.objects.push_back(index)
	compartmentalize(node)

# Octree splits into 8 smaller pieces
func compartmentalize(octree):
	if octree.objects.size() <= LEAF_MAX_SIZE:
		return # if there is enough space for the new index, we don't need to compartmentalize.
	
	var new_boxes = []
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2 * Vector3(0,0,0)), octree.box.size/2))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2 * Vector3(0,0,1)), octree.box.size/2))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2 * Vector3(0,1,0)), octree.box.size/2))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2 * Vector3(0,1,1)), octree.box.size/2))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2 * Vector3(1,0,0)), octree.box.size/2))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2 * Vector3(1,0,1)), octree.box.size/2))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2 * Vector3(1,1,0)), octree.box.size/2))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2 * Vector3(1,1,1)), octree.box.size/2))
	# Create 8 new children
	for j in range (0, new_boxes.size()):
		var new_octree = {
			"box" : new_boxes[j],
			"objects" : [],
			"children" : []
		}
		for i in range (0, octree.objects.size()):
			if new_octree.box.has_point(grass_list[octree.objects[i]].pos):
				new_octree.objects.push_back(octree.objects[i])
		octree.children.push_back(new_octree)
	octree.objects = []
	
	for child in octree.children: # handles rare cases of a compartmentalized box still holding too many indices
		compartmentalize(child)

# Signal Function. There's a 0.05 collision speed minimum required to recieve this signal.
func grass_collision(pos, speed):
	if grass_collision_check and flora_thread.is_active() == false:
		grass_collision_check = false # only run this once per iteration.
		flora_thread = Thread.new()
		flora_thread.start(self, "grass_collision_calculation", [pos, speed])
		
# Separate thread handles grass collision calculations to not slow down the main thread.
func grass_collision_calculation(stuff): # thread takes 1 param, in this case an array with 2 values.
	var pos = stuff[0] # collision point
	var speed = stuff[1] # collision speed
	var damage
	if speed == 9999:
		damage = 9999
	else:
		damage = find_damage(speed) # find damage to grass from speed
	var node = search_octree(pos, FloraOctree) # find which node contains the collision point
	
	if Game.DRAW_CURRENT_AABB:
		current_aabb_node.clear()
		draw_aabb(node.box) # debug function
	var axis_aligned_checks = PoolVector3Array() # we check 6 axis aligned points to find nearby grass containers.
	axis_aligned_checks.push_back(Vector3(-GRASS_HURT_DIST, 0, 0))
	axis_aligned_checks.push_back(Vector3( GRASS_HURT_DIST, 0, 0)) 
	axis_aligned_checks.push_back(Vector3(0, -GRASS_HURT_DIST/2.5, 0)) 
	axis_aligned_checks.push_back(Vector3(0,  GRASS_HURT_DIST/2.5, 0))
	axis_aligned_checks.push_back(Vector3(0, 0, -GRASS_HURT_DIST))
	axis_aligned_checks.push_back(Vector3(0, 0,  GRASS_HURT_DIST))
	var grass = find_grass(pos, axis_aligned_checks, node) # finds adjacent grass
	if grass.size() > 0:
		destroy_grass(pos, grass, damage)
	else:
		flora_thread.call_deferred("wait_to_finish") # ends the thread if no grass to destroy.

func find_damage(speed):
	return 10 * (speed - 0.05)

# returns the smallest node that contains the position
func search_octree(pos, root):
	if root.box.has_point(pos):
		var node = root
		while not node.children.empty():
			for child in node.children:
				if child.box.has_point(pos):
					node = child
					break
		return node
	else:
		return null # not found

func find_grass(pos, axis_aligned_checks, node):
	var boxes = []
	boxes.push_back(node.objects) # push the collision point box grass into the array
	
	for i in range (axis_aligned_checks.size()): # for each axis aligned check
		if !node.box.has_point(pos + axis_aligned_checks[i]): # if the new point to check isn't in the collision point box
			var box = search_octree(pos + axis_aligned_checks[i], FloraOctree) # find where it is
			# if the box ends up out of bounds entirely, typeof(box) won't be > 0
			if typeof(box) > 0:
				if Game.DRAW_CURRENT_AABB:
					draw_aabb(box.box) # debug function
				if boxes.find(box.objects) == -1 and box.objects.size() > 0: # if it isn't already in the boxes array, and has size
					boxes.push_back(box.objects) # add it
	return common.flatten(boxes) # return all the grass indices in a single array

# I still need to add grass regrowth.
func destroy_grass(pos, grass, damage):
	var hurt_count = 0
	for i in range (0, grass.size()): # for each piece of grass
		var dist = pos.distance_to(grass_list[grass[i]].pos) # find dist from collision point to grass
		if dist < GRASS_HURT_DIST: # if dist is within hurt radius, then apply damage
			hurt_count += 1
			var index = grass_list[grass[i]].arraymeshindex # contains indices of grass vertices in the Mesh
			if grass_list[grass[i]].type == "dot":
				if damage == 9999: # special value for "death on grass"
					grass_mesh_arrays[ArrayMesh.ARRAY_COLOR][index] = BLOODY_GRASS_COLOR
				else:
					grass_list[grass[i]].health -= (damage)
					if grass_list[grass[i]].health <= 0: # once health is gone, make dot dirt color
						grass_mesh_arrays[ArrayMesh.ARRAY_COLOR][index] = DESTROYED_GRASS_COLOR
			elif grass_list[grass[i]].type == "tall":
				if damage == 9999:
					tg_mesh_arrays[ArrayMesh.ARRAY_COLOR][index] = BLOODY_GRASS_COLOR
					tg_mesh_arrays[ArrayMesh.ARRAY_COLOR][index+1] = BLOODY_GRASS_COLOR
				else:
					var grass_height = tg_mesh_arrays[ArrayMesh.ARRAY_VERTEX][index+1].y - tg_mesh_arrays[ArrayMesh.ARRAY_VERTEX][index].y
					if grass_height > 0.02:
						# if the tall grass still has some height, shrink it some amount
						var new_height = tg_mesh_arrays[ArrayMesh.ARRAY_VERTEX][index+1].y - (grass_height/100 * damage)
						if new_height - tg_mesh_arrays[ArrayMesh.ARRAY_VERTEX][index].y < 0.02:
							new_height = tg_mesh_arrays[ArrayMesh.ARRAY_VERTEX][index].y + 0.02
						tg_mesh_arrays[ArrayMesh.ARRAY_VERTEX][index+1].y = new_height
					else: # if the tall grass is already very short, make it dirt color
						if grass_list[grass[i]].health > 0:
							grass_list[grass[i]].health = 0
							tg_mesh_arrays[ArrayMesh.ARRAY_COLOR][index] = DESTROYED_GRASS_COLOR
							tg_mesh_arrays[ArrayMesh.ARRAY_COLOR][index+1] = DESTROYED_GRASS_COLOR
						grass_list[grass[i]].health -= damage
	
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_POINTS, grass_mesh_arrays) # create the new mesh
	grass_dots.mesh = arr_mesh # apply the new mesh
	
	arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, tg_mesh_arrays) # create the new mesh
	tall_grass.mesh = arr_mesh # apply the new mesh
	
	if hurt_count > 0:
		#print("hurt " + str(hurt_count) + " grass. " + str(damage) + " damage.")
		pass
	
	flora_thread.call_deferred("wait_to_finish") # ends the thread

func _process(delta):
	# worry about thread progress
	edge_lines.set_shader_param("eye_position",Game.cam.global_transform.origin)
	if world_generation_stage == 0:
		if flora_thread.is_active():
			if grass_generation_percent > 0:
				if grass_generation_prior_percent < round(grass_generation_percent):
					Game.UI.update_topmsg("Flora Generation: " + str(round(grass_generation_percent)) + "% Complete")
				grass_generation_prior_percent = round(grass_generation_percent)
		else:
			world_generation_stage + 1
			grass_generation_complete()
	elif world_generation_stage == 2:
		# this works for BOTH, it's a shared material:
		# I might be able to combine this with edgelines too, I should try that.
		grass_shader.set_shader_param("eye_position",Game.cam.global_transform.origin)
		
func save(level):
	if world_generation_stage < 2:
		return
	
	Game.UI.show_progress()
	Game.UI.update_progress('save', 0)
	save_thread.start(self, "save_with_thread", level)
	
func save_with_thread(level):
	
	var valid = File.new()
	valid.open(Game.save_dir + level + '/valid.save', File.WRITE)
	valid.store_line('false')
	valid.close()
	
	Game.UI.update_progress('save', 1)
	
	if grass_index != null:
		if flower_container.get_children().size() > 0:
			var f = File.new()
			f.open(Game.save_dir + level + '/flowers.save', File.WRITE)
			for i in range (flower_container.get_children().size()):
				f.store_var(flower_container.get_child(i).global_transform)
			f.close()
		
		Game.UI.update_progress('save', 2)
		
		if FloraOctree.size() > 0:
			var f = File.new()
			f.open(Game.save_dir + level + '/flora_octree.save', File.WRITE)
			f.store_var(FloraOctree) # WARNING: it is possible that store_var won't let you transfer save between operating systems.
			f.close()
		
		Game.UI.update_progress('save', 3)
		
		if grass_list.size() > 0:
			var f = File.new()
			f.open(Game.save_dir + level + '/grass_list.save', File.WRITE)
			f.store_var(grass_list)
			f.close()
		
		Game.UI.update_progress('save', 4)
		
		if tall_grass.mesh != null:
			ResourceSaver.save(Game.save_dir + level + '/tall_grass.mesh', tall_grass.mesh)
			
		Game.UI.update_progress('save', 5)
		
		if grass_dots.mesh != null:
			ResourceSaver.save(Game.save_dir + level + '/grass_dots.mesh', grass_dots.mesh)
	
	var f = File.new()
	f.open(Game.save_dir + 'stats.save', File.WRITE)
	f.store_var(Game.playtime)
	f.close()
	
	valid = File.new()
	valid.open(Game.save_dir + level + '/valid.save', File.WRITE)
	valid.store_line('true')
	valid.close()
	call_deferred("_save_thread_done")

func _save_thread_done():
	Game.UI.update_progress('save', 6)
	save_thread.wait_to_finish()
	Game.save_complete()

func _exit_triggered(body, level):
	Game.player.lockplayerinput = true
	Game.UI.fadeout()
	save(Game.current_level)
	Game.load_level(level)
