tool # needed so it runs in editor
extends EditorScenePostImport

func post_import(scene):
	scene.get_node('DISABLE_boolcut').free()
	for child in scene.get_node('Armature/Skeleton').get_children():
		if child.name.substr(0, 8) == "DISABLE_":
			print(child.name)
			child.free()
			continue
		if child is MeshInstance:
			if child.name == 'Tights':
				child.set_surface_material(0, preload("res://materials/tights.tres"))
			else:
				child.set_surface_material(0, preload("res://materials/toonshader.tres"))
			if child.name == 'Hands':
				var orb = Position3D.new().instance()
				orb.name = "OrbPosition"
				orb.translation = Vector3(-2.039, 4.365, -0.043)
				child.add_child(orb)
	var ap = scene.get_node("AnimationPlayer")
	var anim_list = ap.get_animation_list()
	for i in range (anim_list.size()):
		var animation = ap.get_animation(anim_list[i])
		animation.loop = true
		var id = animation.find_track('Armature')
		if id > -1:
			animation.remove_track(id)
			print("removed track.")
	var anim_tree = load("res://player/AnimationTree.tscn").instance()
	scene.add_child(anim_tree)
	anim_tree.set_owner(scene)
	anim_tree.active = true
	var editor_light = DirectionalLight.new()
	scene.add_child(editor_light)
	editor_light.set_owner(scene)
	editor_light.name = "EditorLight"
	editor_light.editor_only = true
	editor_light.transform = Basis(Vector3(-0.24, 0.71, 0.65), Vector3(0.396, -0.54, 0.73), Vector3(0.886, 0.43, -0.15))
	return scene # remember to return the imported scene
