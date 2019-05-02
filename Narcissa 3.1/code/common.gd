extends Node

# 2D array -> 1D array
static func flatten(arr):
	var result = []
	for a in arr:
		for x in a:
			result.append(x)
	return result

# Find Normal from 3 vertices
static func get_normal(v1, v2, v3):
	return (v1-v2).cross(v1-v3).normalized()

# Find Area of Triangle
static func tri_area(v1, v2, v3):
	return (v2 - v1).cross(v3 - v1).length() / 2

# Find random point on Triangle
static func sample_tri(p1, p2, p3):
	var a = randf()
	var b = randf()
	var v1 = p2 - p1
	var v2 = p3 - p1
	while a + b > 1:
		a = randf()
		b = randf()
	return p1 + a*v1 + b*v2

static func deadzone(input):
#	var normalized = input.normalized()
#	if normalized.dot(Vector2.UP) > 0.95:
#		return clamp(Vector2.UP * input.length(), 0.0, 1.0)
	var length:float = input.length_squared()
	if length > 0.88:
		return input.normalized()
	elif length < 0.015:
		return Vector2()
	return input

static func colorvalue(color_name):
	match color_name:
		'red':
			return Color("ff3130")
		'orange':
			return Color("ff9000")
		'yellow':
			return Color("eff70b")
		'green':
			return Color("1fd43d")
		'cyan':
			return Color("00f8f8")
		'blue':
			return Color("1d67ff")
		'purple':
			return Color("a23fdb")
		'grey':
			return Color("676767")
		'white':
			return Color("ffffff")
		_:
			return ColorN(color_name)