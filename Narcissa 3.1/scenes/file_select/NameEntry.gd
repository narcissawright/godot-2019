extends Control

onready var symbol_bg = preload("name_entry_key.tscn")

var key_layout:Array = [
	['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
	['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'],
	['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', '@', '#', '_', '&', '!', '?', '.', ',', '\'', '(', ')', '*', 'â€“', '+', '/'],
]

#var key_layout:Array = [
#	['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', ' ', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M'],
#	['n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z', ' ', 'N', 'O', 'P', 'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z'],
#	['0', '1', '2', '3', '4', '5', '6', '7', '8', '9', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', ' ', 'í ¼í½†'],
#	['!', '@', '#', '$', '%', '^', '&', '*', '+', '=', 'â€“', '~', '.', ',', '!', '?', '(', ')', '[', ']', '<', '>', '{', '}', "'", '"', '/']
#]

func _ready():
	for i in range (key_layout.size()):
		for j in range (key_layout[i].size()):
			var instance = symbol_bg.instance()
			instance.position.y = (i+1) * 49
			instance.position.x = (j * 49)
			instance.get_child(0).text = key_layout[i][j]
			add_child(instance)