extends MeshInstance
var edge_lines
func _ready():
	edge_lines = Game.decorator.create_edge_lines(mesh)
	add_child(edge_lines)