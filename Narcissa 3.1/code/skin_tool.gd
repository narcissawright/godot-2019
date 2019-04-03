tool
extends MeshInstance
export(bool) var load_materials = false setget set_materials
func set_materials(value):
	if Engine.editor_hint:
		for i in range (0, mesh.get_surface_count()):
			if mesh.surface_get_name(i) == "Grass":
				var grass_material = load("res://materials/grass_mat.tres") 
				set_surface_material(i, grass_material)
			elif mesh.surface_get_name(i) == "Ice":
				var ice_material = load("res://materials/ice_new.tres")
				set_surface_material(i, ice_material)
			elif mesh.surface_get_name(i) == "Wall":
				var wall_material = load("res://materials/wall_mat.tres")
				set_surface_material(i, wall_material)